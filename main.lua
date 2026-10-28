-- Sweet Share: full EXP for fighters, half for the bench, optional
-- level gates. Two Options rows. Wraps battle.exp_award (Gen 1 + Gen 2).

local SHARE_KEY = "sweetShare"
local SHARE_ROW_ID = "sweet_exp_share"
local SHARE_ROW_LABEL = "S. EXP SHARE"

local CAP_KEY = "sweetLevelCap"
local CAP_ROW_ID = "sweet_level_cap"
local CAP_ROW_LABEL = "S. LEVEL CAP"

local OFF = "off"
local ON = "on"
local ACTIVE = "active"
local TOP = "top"
local GYM = "gym"

local SHARE_CYCLE = { OFF, ON }
local SHARE_LABEL = { [OFF] = "OFF", [ON] = "ON" }

-- OFF = no gate. ACTIVE / TOP = soft (bench only). GYM = hard (everyone).
local CAP_CYCLE = { OFF, ACTIVE, TOP, GYM }
local CAP_LABEL = {
  [OFF] = "OFF",
  [ACTIVE] = "ACTIVE",
  [TOP] = "TOP LVL",
  [GYM] = "GYM LVL",
}

-- Divisors passed to ctx.applyShare (engine divides base EXP by this).
local FIGHTER_DIVISOR = 1
local BENCH_DIVISOR = 2

-- gen1recomp 0.1.84+ sandbox omits `debug`; never pass debug.traceback to xpcall.
local function traceErr(err)
  return tostring(err)
end

-- While we own the award, Gen 2's applyShare still closes over `halved`
-- from any EXP_SHARE holder. Clear it on exp.gain so Sweet modes are not
-- taxed by the held item (stat-exp may still see halved — unequip to be safe).
local suppressShareTax = false

-- Gen 2 Battle has .save but not .game; options live on Game2.options and are
-- mirrored to save.options. Prefer the live game, then battle.save.options.
local function resolveGame(mod, battle)
  if battle and battle.game then
    return battle.game
  end
  if mod and mod.game then
    return mod.game
  end
  -- Gen 2 Battle wires .save but not .game. Synthesize enough for options +
  -- gym_caps (generation / save.player.badges).
  if battle and battle.save then
    return {
      generation = 2,
      save = battle.save,
      options = battle.save.options,
    }
  end
  return nil
end

local function optionsTable(game, battle)
  if game then
    if game.save and type(game.save.options) == "table" then
      return game.save.options
    end
    if type(game.options) == "table" then
      return game.options
    end
  end
  if battle and battle.save and type(battle.save.options) == "table" then
    return battle.save.options
  end
  return nil
end

local function writeOptions(game)
  if not game then
    return
  end
  -- Gen 2 persists via persistOptions; Gen 1 via writeOptions.
  if type(game.persistOptions) == "function" then
    game:persistOptions()
  elseif type(game.writeOptions) == "function" then
    game:writeOptions()
  end
end

-- Migrate legacy single-dial sweetShare (off/on/active/top) into share + cap.
local function migrateLegacy(options)
  if type(options) ~= "table" then
    return
  end
  local legacy = options[SHARE_KEY]
  if legacy == ACTIVE or legacy == TOP then
    options[SHARE_KEY] = ON
    if options[CAP_KEY] == nil then
      options[CAP_KEY] = legacy
    end
  elseif legacy == ON or legacy == OFF then
    -- share already on/off; default cap OFF preserves old ungated ON
    if options[CAP_KEY] == nil then
      options[CAP_KEY] = OFF
    end
  elseif legacy ~= nil and legacy ~= ON and legacy ~= OFF then
    options[SHARE_KEY] = ON
    if options[CAP_KEY] == nil then
      options[CAP_KEY] = OFF
    end
  end
end

local function readShare(game, battle)
  local options = optionsTable(game, battle)
  migrateLegacy(options)
  local raw = options and options[SHARE_KEY]
  if raw == OFF or raw == ON then
    return raw
  end
  return ON
end

local function writeShare(game, value)
  local options = optionsTable(game)
  if not options then return false end
  migrateLegacy(options)
  options[SHARE_KEY] = value
  writeOptions(game)
  return true
end

local function readCap(game, battle)
  local options = optionsTable(game, battle)
  migrateLegacy(options)
  local raw = options and options[CAP_KEY]
  if raw == OFF or raw == ACTIVE or raw == TOP or raw == GYM then
    return raw
  end
  return OFF
end

local function writeCap(game, value)
  local options = optionsTable(game)
  if not options then return false end
  migrateLegacy(options)
  options[CAP_KEY] = value
  writeOptions(game)
  return true
end

local function cycleValue(cycle, current, direction)
  local index = 1
  for i, value in ipairs(cycle) do
    if value == current then
      index = i
      break
    end
  end
  local count = #cycle
  return cycle[((index - 1 + (direction or 1)) % count) + 1]
end

local function cycleShare(game, direction)
  local nextValue = cycleValue(SHARE_CYCLE, readShare(game), direction)
  if not writeShare(game, nextValue) then
    return nil
  end
  return nextValue
end

local function cycleCap(game, direction)
  local nextValue = cycleValue(CAP_CYCLE, readCap(game), direction)
  if not writeCap(game, nextValue) then
    return nil
  end
  return nextValue
end

local function monConscious(mon)
  return mon and (mon.hp or 0) > 0 and not mon.isEgg
end

local function partyOf(battle, game)
  if battle and type(battle.party) == "table" then
    return battle.party
  end
  return game and game.save and game.save.party
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

-- Returns gate level and whether the cap is hard (blocks fighters too).
local gymCapsMod
-- Sibling via love FS (mod:read), not Lua loadfile — same pitfall as dex_radar.
local function loadGymCaps(mod)
  if gymCapsMod then return gymCapsMod end
  if not (mod and mod.read) then
    error("sweet_share: cannot load gym_caps.lua (no mod:read)")
  end
  local src, readErr = mod:read("gym_caps.lua")
  if type(src) ~= "string" or src == "" then
    error("sweet_share: cannot load gym_caps.lua (" .. tostring(readErr or "empty") .. ")")
  end
  local loader = loadstring or load
  local chunk, err = loader(src, "@sweet_share/gym_caps.lua")
  if not chunk then
    error("sweet_share: cannot compile gym_caps.lua (" .. tostring(err) .. ")")
  end
  gymCapsMod = chunk()
  return gymCapsMod
end

local function resolveGate(mod, game, cap, party)
  if cap == ACTIVE then
    return slotOneLevel(party), false
  end
  if cap == TOP then
    return partyTopLevel(party), false
  end
  if cap == GYM then
    local ok, gateOrErr = pcall(function()
      return loadGymCaps(mod).resolve(mod, game)
    end)
    if not ok then
      if mod and mod.log then
        mod.log:warn("gym cap unavailable: %s", tostring(gateOrErr))
      end
      return nil, false
    end
    return gateOrErr, true
  end
  return nil, false
end

local function blockedByGate(mon, gate, hard, fought)
  if not monConscious(mon) then
    return true
  end
  if gate == nil then
    return false
  end
  if (mon.level or 1) < gate then
    return false
  end
  if hard then
    return true
  end
  return not fought[mon]
end

-- Gen 2 award ctx carries loser / holders; Gen 1 does not.
local function isGen2Award(ctx)
  return type(ctx) == "table" and (ctx.loser ~= nil or ctx.holders ~= nil)
end

local function isTraded(battle, mon)
  if mon and mon.traded then
    return true
  end
  if battle and type(battle.isOutsider) == "function" then
    return battle:isOutsider(mon) and true or false
  end
  return false
end

-- Gen 1: mirror Experience.gainFor (split divides baseExp first).
local function predictGrantedExpGen1(battle, mon, divisor)
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

-- Gen 2: mirror Mon.experienceGain with halved forced off (Sweet owns the split).
local function predictGrantedExpGen2(battle, ctx, mon, divisor)
  local loser = ctx and ctx.loser
  if not loser then
    return nil
  end
  local def = nil
  if battle and type(battle.speciesDef) == "function" then
    def = battle:speciesDef(loser)
  end
  def = def or loser.def
  if not def then
    return nil
  end

  local baseExp = def.baseExp or 0
  local value = math.floor(baseExp * (loser.level or 1) / 7)
  value = math.floor(value / math.max(1, divisor or 1))
  if isTraded(battle, mon) then
    value = math.floor(value * 3 / 2)
  end
  if battle.trainer ~= nil then
    value = math.floor(value * 3 / 2)
  end
  if mon and mon.item == "LUCKY_EGG" then
    value = math.floor(value * 3 / 2)
  end
  return math.max(1, value)
end

local function predictGrantedExp(ctx, mon, divisor)
  local battle = ctx and ctx.battle
  if isGen2Award(ctx) then
    return predictGrantedExpGen2(battle, ctx, mon, divisor)
  end
  return predictGrantedExpGen1(battle, mon, divisor)
end

local function sayShare(battle, text)
  if not battle or type(text) ~= "string" then
    return
  end
  if type(battle.sayNext) == "function" then
    battle:sayNext(text)
    return
  end
  if type(battle.emit) == "function" then
    battle:emit({ kind = "message", text = text })
  end
end

-- Prefer a non-traded sample so the line matches the common (unboosted) grant.
local function messageSample(battle, recipients)
  for _, mon in ipairs(recipients) do
    if not isTraded(battle, mon) then
      return mon
    end
  end
  return recipients[1]
end

-- GB text box = 18 cols; keep each line well under that (no soft-wrap).
local function shareLine(receivedCount, expAmount)
  if receivedCount == 1 then
    return ("One more got\n%d EXP!"):format(expAmount)
  end
  return ("%d others got\n%d EXP each!"):format(receivedCount, expAmount)
end

-- Mod Manager DISABLE writes save.options.mods[id]=false immediately
-- (STAGED); the entry `mod` facade has no live .enabled field.
local function modIsOn(game, modId, battle)
  local options = optionsTable(game, battle)
  local flags = options and options.mods
  if flags and flags[modId] == false then
    return false
  end
  return true
end

-- One path for Gen 1 and Gen 2: both pass applyShare(mon, split, announce),
-- and Gen 2 honours `announce` since engine v0.2.19. Fighters get full EXP
-- each (announced), the bench half (silent) under one summary line.
local function distributeSweet(mod, ctx, nextFn)
  local battle = ctx.battle
  local game = resolveGame(mod, battle)
  local party = partyOf(battle, game)
  if type(party) ~= "table" or type(ctx.applyShare) ~= "function" then
    return nextFn(ctx)
  end

  local cap = readCap(game, battle)
  local gate, hard = resolveGate(mod, game, cap, party)
  local alive = ctx.alive or {}

  local fought = {}
  for _, mon in ipairs(alive) do
    if monConscious(mon) then
      fought[mon] = true
    end
  end

  suppressShareTax = true
  local ok, err = xpcall(function()
    for _, mon in ipairs(alive) do
      if not blockedByGate(mon, gate, hard, fought) then
        ctx.applyShare(mon, FIGHTER_DIVISOR, true)
      end
    end

    local recipients = {}

    for _, mon in ipairs(party) do
      if monConscious(mon) and not fought[mon] then
        if not blockedByGate(mon, gate, hard, fought) then
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
      local okPred, amount = pcall(predictGrantedExp, ctx, mon, BENCH_DIVISOR)
      if okPred then
        expected[mon] = amount
      end
    end

    local sample = messageSample(battle, recipients)
    local expAmount = expected[sample] or 0
    pcall(sayShare, battle, shareLine(n, expAmount))

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
  end, traceErr)
  suppressShareTax = false
  if not ok then
    error(err)
  end
end

-- Share OFF + cap ON: let vanilla / other award mods run, but filter applyShare.
local function withLevelCap(mod, ctx, game, nextFn)
  local battle = ctx.battle
  local cap = readCap(game, battle)
  if cap == OFF then
    return nextFn(ctx)
  end
  local party = partyOf(battle, game)
  local gate, hard = resolveGate(mod, game, cap, party)
  if gate == nil and cap ~= GYM then
    return nextFn(ctx)
  end
  -- GYM with missing trainer data: fail open (no filter) rather than softlock EXP.
  if gate == nil then
    return nextFn(ctx)
  end

  local fought = {}
  for _, mon in ipairs(ctx.alive or {}) do
    if mon then
      fought[mon] = true
    end
  end

  local rawApply = ctx.applyShare
  if type(rawApply) ~= "function" then
    return nextFn(ctx)
  end

  -- Gen 2 vanilla pays through giveExperiencePass and never calls applyShare,
  -- so a wrapped applyShare would filter nothing. Rebuild its two passes
  -- (participants split by count, then EXP SHARE holders) with the gate.
  if isGen2Award(ctx) then
    party = party or {}
    for _, mon in ipairs(ctx.alive or {}) do
      if not blockedByGate(mon, gate, hard, fought) then
        rawApply(mon, math.max(1, ctx.participants or 1), true)
      end
    end
    local holders = ctx.holders or {}
    if ctx.halved and #holders > 0 then
      for _, index in ipairs(holders) do
        local mon = party[index]
        if mon and not blockedByGate(mon, gate, hard, fought) then
          rawApply(mon, #holders, true)
        end
      end
    end
    return
  end

  ctx.applyShare = function(mon, split, announce)
    if blockedByGate(mon, gate, hard, fought) then
      return
    end
    return rawApply(mon, split, announce)
  end
  return nextFn(ctx)
end

return function(mod)
  mod.log:info("carregado")

  mod.hooks:wrap("exp.gain", function(next, ctx)
    if suppressShareTax and type(ctx) == "table" and ctx.halved then
      ctx.halved = false
    end
    return next(ctx)
  end)

  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if not modIsOn(game, mod.id) or type(out) ~= "table" then
      return out
    end
    out[#out + 1] = {
      id = SHARE_ROW_ID,
      label = SHARE_ROW_LABEL,
      value = function(g)
        return SHARE_LABEL[readShare(g)]
      end,
      step = function(g, dir)
        return cycleShare(g, dir) ~= nil
      end,
    }
    out[#out + 1] = {
      id = CAP_ROW_ID,
      label = CAP_ROW_LABEL,
      value = function(g)
        return CAP_LABEL[readCap(g)]
      end,
      step = function(g, dir)
        return cycleCap(g, dir) ~= nil
      end,
    }
    return out
  end)

  mod.hooks:wrap("battle.exp_award", function(next, ctx)
    local battle = ctx and ctx.battle
    local game = resolveGame(mod, battle)
    if not modIsOn(game, mod.id, battle) then
      return next(ctx)
    end
    if readShare(game, battle) == ON then
      return distributeSweet(mod, ctx, next)
    end
    return withLevelCap(mod, ctx, game, next)
  end)
end
