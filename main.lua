-- Sweet Share: full EXP for fighters, half for the bench, optional
-- ACTIVE / TOP LEVEL gates. Wraps battle.exp_award only.

local OPTION_KEY = "sweetShare"
local ROW_ID = "sweet_exp_share"
local ROW_LABEL = "SWEET EXP SHARE"

local MODE_OFF = "off"
local MODE_ON = "on"
local MODE_ACTIVE = "active"
local MODE_TOP = "top"

local MODE_CYCLE = { MODE_OFF, MODE_ON, MODE_ACTIVE, MODE_TOP }
local MODE_LABEL = {
  [MODE_OFF] = "OFF",
  [MODE_ON] = "ON",
  [MODE_ACTIVE] = "ACTIVE",
  [MODE_TOP] = "TOP LEVEL",
}

-- Divisors passed to ctx.applyShare (engine divides base EXP by this).
local FIGHTER_DIVISOR = 1
local BENCH_DIVISOR = 2

local function readMode(game)
  local options = game and game.save and game.save.options
  local raw = options and options[OPTION_KEY]
  if raw == MODE_OFF or raw == MODE_ON or raw == MODE_ACTIVE or raw == MODE_TOP then
    return raw
  end
  return MODE_ON
end

local function writeMode(game, mode)
  local options = game and game.save and game.save.options
  if not options then return false end
  options[OPTION_KEY] = mode
  if game.writeOptions then
    game:writeOptions()
  end
  return true
end

local function cycleMode(game, direction)
  local current = readMode(game)
  local index = 1
  for i, mode in ipairs(MODE_CYCLE) do
    if mode == current then
      index = i
      break
    end
  end
  local count = #MODE_CYCLE
  local nextIndex = ((index - 1 + (direction or 1)) % count) + 1
  local nextMode = MODE_CYCLE[nextIndex]
  if not writeMode(game, nextMode) then
    return nil
  end
  return nextMode
end

local function modeLabel(game)
  return MODE_LABEL[readMode(game)]
end

local function slotOneLevel(party)
  local lead = party and party[1]
  return (lead and lead.level) or 100
end

local function partyTopLevel(party)
  local top = 1
  if not party then return top end
  for _, mon in ipairs(party) do
    local level = mon.level or 1
    if level > top then
      top = level
    end
  end
  return top
end

local function benchGateLevel(mode, party)
  if mode == MODE_ACTIVE then
    return slotOneLevel(party)
  end
  if mode == MODE_TOP then
    return partyTopLevel(party)
  end
  return nil
end

-- Mirror of engine Experience.gainFor (split divides baseExp first, then
-- level/7, then traded/trainer). Floor-first means bench is often a few
-- points off "half of the fighter's line" (e.g. 112 full → ~50 half).
local function predictGrantedExp(battle, mon, divisor)
  local enemy = battle and battle.enemy
  local defeatedDef = enemy and enemy.def
  local foe = enemy and enemy.mon
  if not defeatedDef or not foe then
    return nil
  end

  local levelDivisor, tradedMult, trainerMult = 7, 1.5, 1.5
  local consts = battle.data and battle.data.constants
  local tuning = consts and consts.exp
  if tuning then
    levelDivisor = tuning.divisor or levelDivisor
    tradedMult = tuning.tradedMult or tradedMult
    trainerMult = tuning.trainerMult or trainerMult
  end

  local base = math.floor((defeatedDef.baseExp or 0) / math.max(1, divisor or 1))
  local amount = math.floor(base * (foe.level or 1) / levelDivisor)
  if mon and mon.traded then
    amount = math.floor(amount * tradedMult)
  end
  if battle.kind == "trainer" then
    amount = math.floor(amount * trainerMult)
  end
  return math.max(1, amount)
end

-- Prefer a non-traded sample so the line matches the common (unboosted) grant.
local function messageSample(recipients)
  for _, mon in ipairs(recipients) do
    if not mon.traded then
      return mon
    end
  end
  return recipients[1]
end

-- GB text box = 18 cols; keep each line well under that (no soft-wrap).
local function shareLine(receivedCount, allRemainingGotShare, expAmount)
  if receivedCount == 1 then
    return ("One more got\n%d EXP!"):format(expAmount)
  end
  if allRemainingGotShare then
    return ("The others got\n%d EXP each!"):format(expAmount)
  end
  return ("%d others got\n%d EXP each!"):format(receivedCount, expAmount)
end

-- Mod Manager DISABLE writes save.options.mods[id]=false immediately
-- (STAGED); the entry `mod` facade has no live .enabled field.
local function modIsOn(game, modId)
  local options = game and game.save and game.save.options
  local flags = options and options.mods
  if flags and flags[modId] == false then
    return false
  end
  return true
end

local function distributeSweet(mod, ctx)
  local battle = ctx.battle
  local game = battle and battle.game
  local party = game and game.save and game.save.party
  if not party or type(ctx.applyShare) ~= "function" then
    return
  end

  local mode = readMode(game)
  local alive = ctx.alive or {}

  local fought = {}
  for _, mon in ipairs(alive) do
    fought[mon] = true
  end

  for _, mon in ipairs(alive) do
    ctx.applyShare(mon, FIGHTER_DIVISOR, true)
  end

  local gate = benchGateLevel(mode, party)
  local recipients = {}
  local remainingConscious = 0

  for _, mon in ipairs(party) do
    if mon.hp and mon.hp > 0 and not fought[mon] then
      remainingConscious = remainingConscious + 1
      if gate == nil or (mon.level or 1) < gate then
        recipients[#recipients + 1] = mon
      end
    end
  end

  local n = #recipients
  if n == 0 then
    return
  end

  local expected = {}
  for _, mon in ipairs(recipients) do
    expected[mon] = predictGrantedExp(battle, mon, BENCH_DIVISOR)
  end

  local sample = messageSample(recipients)
  local expAmount = expected[sample] or 0
  battle:sayNext(shareLine(n, n == remainingConscious, expAmount))

  -- Confirm the silent applyShare grants match the amount we just printed
  -- (and each mon's own prediction, including traded boosts).
  local pending = {}
  for _, mon in ipairs(recipients) do
    pending[mon] = true
  end
  local off = mod.events:on("battle.exp_gained", function(ev)
    if ev.battle ~= battle or not pending[ev.mon] then
      return
    end
    pending[ev.mon] = nil
    local want = expected[ev.mon]
    if want == nil then
      return
    end
    if ev.gained ~= want then
      mod.log:warn(
        "bench EXP mismatch for %s: predicted %d, granted %d (message showed %d)",
        tostring(ev.mon.species or "?"), want, ev.gained or -1, expAmount)
    end
  end)

  for _, mon in ipairs(recipients) do
    ctx.applyShare(mon, BENCH_DIVISOR, nil)
  end
  if off then
    off()
  end
end

return function(mod)
  mod.log:info("carregado")

  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if not modIsOn(game, mod.id) or type(out) ~= "table" then
      return out
    end
    out[#out + 1] = {
      id = ROW_ID,
      label = ROW_LABEL,
      value = function(g)
        return modeLabel(g)
      end,
      step = function(g, dir)
        return cycleMode(g, dir) ~= nil
      end,
    }
    return out
  end)

  mod.hooks:wrap("battle.exp_award", function(next, ctx)
    local battle = ctx and ctx.battle
    local game = battle and battle.game
    if not modIsOn(game, mod.id) then
      return next(ctx)
    end
    local mode = readMode(game)
    if mode == MODE_OFF then
      return next(ctx)
    end
    return distributeSweet(mod, ctx)
  end)
end
