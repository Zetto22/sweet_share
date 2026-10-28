-- Gym / post-game level caps for Sweet Share (Gen 1, Gen 2, Gen 3).
-- Cap levels come from the live boss party: registry data first, then the
-- `trainer.party` hook chain (same path battle setup uses). Mods that patch
-- `content.trainers` or wrap `trainer.party` (e.g. Stronger Trainers) raise
-- the cap automatically — no per-mod integration.

local M = {}

-- Gen 1 gym order (badge item id + trainer class + party index).
-- Giovanni's Viridian fight is party 3 (OPP_GIOVANNI#3).
M.GEN1_GYMS = {
  { badge = "BOULDERBADGE", trainer = "OPP_BROCK", party = 1 },
  { badge = "CASCADEBADGE", trainer = "OPP_MISTY", party = 1 },
  { badge = "THUNDERBADGE", trainer = "OPP_LT_SURGE", party = 1 },
  { badge = "RAINBOWBADGE", trainer = "OPP_ERIKA", party = 1 },
  { badge = "SOULBADGE", trainer = "OPP_KOGA", party = 1 },
  { badge = "MARSHBADGE", trainer = "OPP_SABRINA", party = 1 },
  { badge = "VOLCANOBADGE", trainer = "OPP_BLAINE", party = 1 },
  { badge = "EARTHBADGE", trainer = "OPP_GIOVANNI", party = 3 },
}

-- After 8 badges: Champion rival (all starter variants). Lance = data fallback only.
M.GEN1_CHAMPION = { trainer = "OPP_RIVAL3" }
M.GEN1_LAST_E4 = { trainer = "OPP_LANCE", party = 1 }

-- Gen 2 Johto gyms (save.player.badges keys match TrainerCard / Battle).
M.GEN2_JOHTO_GYMS = {
  { badge = "ZEPHYR", classes = { "FALKNER" }, name = "FALKNER" },
  { badge = "HIVE", classes = { "BUGSY" }, name = "BUGSY" },
  { badge = "PLAIN", classes = { "WHITNEY" }, name = "WHITNEY" },
  { badge = "FOG", classes = { "MORTY" }, name = "MORTY" },
  { badge = "STORM", classes = { "CHUCK" }, name = "CHUCK" },
  { badge = "MINERAL", classes = { "JASMINE" }, name = "JASMINE" },
  { badge = "GLACIER", classes = { "PRYCE" }, name = "PRYCE" },
  { badge = "RISING", classes = { "CLAIR" }, name = "CLAIR" },
}

-- After Elite Four / Hall of Fame: flat cap = max ace among Kanto leaders.
-- class ids follow pret/pokegold; alternates tried in maxLevelGen2Entry.
M.GEN2_KANTO_GYMS = {
  { badge = "BOULDER", classes = { "BROCK" }, name = "BROCK" },
  { badge = "CASCADE", classes = { "MISTY" }, name = "MISTY" },
  { badge = "THUNDER", classes = { "LT_SURGE", "SURGE" }, name = "LT.SURGE" },
  { badge = "RAINBOW", classes = { "ERIKA" }, name = "ERIKA" },
  { badge = "SOUL", classes = { "JANINE" }, name = "JANINE" },
  { badge = "MARSH", classes = { "SABRINA" }, name = "SABRINA" },
  { badge = "VOLCANO", classes = { "BLAINE" }, name = "BLAINE" },
  { badge = "EARTH", classes = { "BLUE", "RIVAL" }, name = "BLUE" },
}

-- Johto Champion Lance (first clear); Karen is last Elite Four member.
M.GEN2_CHAMPION = { classes = { "CHAMPION", "LANCE" }, name = "LANCE" }
M.GEN2_LAST_E4 = { classes = { "KAREN" }, name = "KAREN" }

-- After all Kanto badges: rematch champion Lance, then Mt. Silver Red.
-- Rematch may share the same trainer row as the first fight on Gold/Silver;
-- resolve() never drops the cap below the Kanto-leaders max in that phase.
M.GEN2_REMATCH_CHAMPION = { classes = { "CHAMPION", "LANCE" }, name = "LANCE" }
M.GEN2_RED = { classes = { "RED" }, name = "RED" }

-- Gen 3: numeric trainer ids (pret constants, registry keys are strings),
-- badge i = FLAG_BADGE0i_GET. Leaders listed in badge order.
M.GEN3 = {
  emerald = {
    gyms = { 265, 266, 267, 268, 269, 270, 271, 272 }, -- Roxanne .. Juan
    champion = { 335 }, -- Wallace
    lastE4 = 264, -- Drake
  },
  rs = {
    gyms = { 265, 266, 267, 268, 269, 270, 271, 272 }, -- Roxanne .. Wallace
    champion = { 335 }, -- Steven
    lastE4 = 264, -- Drake
  },
  frlg = {
    -- Brock, Misty, Lt. Surge, Erika, Koga, Sabrina, Blaine, Giovanni
    gyms = { 414, 415, 416, 417, 418, 420, 419, 350 },
    champion = { 438, 439, 440 }, -- rival, one per starter
    lastE4 = 413, -- Lance
  },
}

local function maxLevelInParty(party)
  local max = 0
  if type(party) ~= "table" then return max end
  for _, row in ipairs(party) do
    if type(row) == "table" then
      local lv = tonumber(row.level) or 0
      if lv > max then max = lv end
    end
  end
  return max
end

-- Shallow copy so a hook that mutates slots cannot dirty the registry.
local function copyParty(party)
  if type(party) ~= "table" then return party end
  local out = {}
  for i, slot in ipairs(party) do
    if type(slot) == "table" then
      local row = {}
      for k, v in pairs(slot) do
        row[k] = v
      end
      out[i] = row
    else
      out[i] = slot
    end
  end
  return out
end

-- Same call shape as BattleState:startTrainer / Gen2 Battle setup.
local function throughTrainerPartyHook(classId, partyKey, vanillaParty)
  if type(vanillaParty) ~= "table" then
    return vanillaParty
  end
  local okRt, Runtime = pcall(require, "src.mods.Runtime")
  if not okRt or type(Runtime) ~= "table" or type(Runtime.call) ~= "function" then
    return vanillaParty
  end
  if type(Runtime.wantsHook) == "function" and not Runtime.wantsHook("trainer.party") then
    return vanillaParty
  end
  local seed = copyParty(vanillaParty)
  local ok, result = pcall(function()
    return Runtime.call("trainer.party", function(_, _, party)
      return party
    end, classId, partyKey, seed)
  end)
  if ok and type(result) == "table" then
    return result
  end
  return vanillaParty
end

local function maxLevelGen1(mod, trainerId, partyIndex)
  if not (mod and mod.content and mod.content.trainers) then return 0 end
  local rec = mod.content.trainers:get(trainerId)
  if type(rec) ~= "table" or type(rec.parties) ~= "table" then return 0 end
  if partyIndex then
    local party = throughTrainerPartyHook(
      trainerId, partyIndex, rec.parties[partyIndex]
    )
    return maxLevelInParty(party)
  end
  local max = 0
  for index, party in ipairs(rec.parties) do
    local live = throughTrainerPartyHook(trainerId, index, party)
    local m = maxLevelInParty(live)
    if m > max then max = m end
  end
  return max
end

local function nameMatch(row, want)
  if not want then return true end
  if type(row) ~= "table" then return false end
  local id = row.id or row.name
  if id == want then return true end
  -- "LT.SURGE" vs "LT SURGE" vs class display quirks
  if type(id) == "string" and type(want) == "string" then
    local a = id:gsub("[%.%s]", ""):upper()
    local b = want:gsub("[%.%s]", ""):upper()
    return a == b
  end
  return false
end

-- Gen 2 Battle passes memberId (or index) as the second trainer.party arg.
local function gen2PartyKey(row, index)
  if type(row) ~= "table" then return index end
  return row.id or row.memberId or row.name or index
end

local function maxLevelGen2(mod, classId, trainerName)
  if not (mod and mod.content and mod.content.trainers) then return 0 end
  local rec = mod.content.trainers:get(classId)
  if type(rec) ~= "table" or type(rec.trainers) ~= "table" then return 0 end
  local max, matched = 0, false
  for index, t in ipairs(rec.trainers) do
    if nameMatch(t, trainerName) then
      matched = true
      local live = throughTrainerPartyHook(
        classId, gen2PartyKey(t, index), t.party
      )
      local m = maxLevelInParty(live)
      if m > max then max = m end
    end
  end
  if matched then return max end
  for index, t in ipairs(rec.trainers) do
    local live = throughTrainerPartyHook(
      classId, gen2PartyKey(t, index), t.party
    )
    local m = maxLevelInParty(live)
    if m > max then max = m end
  end
  return max
end

local function maxLevelGen3(mod, trainerId)
  if not (mod and mod.content and mod.content.trainers) then return 0 end
  local ok, rec = pcall(function()
    return mod.content.trainers:get(tostring(trainerId))
  end)
  if not ok or type(rec) ~= "table" or type(rec.party) ~= "table" then return 0 end
  local live = throughTrainerPartyHook(rec.class, trainerId, rec.party)
  return maxLevelInParty(live)
end

local function gen3Version(game)
  local session = game and game.session
  local v = session and session.version
  if type(v) ~= "string" then
    local okGv, GameVersion = pcall(require, "src.core.GameVersion")
    if okGv and type(GameVersion) == "table" and GameVersion.get then
      v = GameVersion.get()
    end
  end
  return v
end

local function gen3Ladder(game)
  local v = gen3Version(game)
  if v == "emerald" then return M.GEN3.emerald end
  if v == "ruby" or v == "sapphire" then return M.GEN3.rs end
  if v == "firered" or v == "leafgreen" then return M.GEN3.frlg end
  return nil
end

local function maxLevelGen2Entry(mod, entry)
  if type(entry) ~= "table" then return 0 end
  local classes = entry.classes or { entry.class }
  local max = 0
  for _, classId in ipairs(classes) do
    local m = maxLevelGen2(mod, classId, entry.name)
    if m > max then max = m end
  end
  return max
end

local function isGen2(game)
  if not game then return false end
  if game.generation == 2 then return true end
  local v = game.version or game.gameVersion
  if v == "gold" or v == "silver" or v == "crystal" then return true end
  local save = game.save
  if save and save.player and type(save.player.kantoBadges) == "table" then
    return true
  end
  return false
end

local function countOwned(ordered, ownedMap)
  local n = 0
  if type(ownedMap) ~= "table" then return 0 end
  for _, id in ipairs(ordered) do
    if ownedMap[id] then n = n + 1 end
  end
  return n
end

-- Gym order is free in places (Gen 1: Erika/Koga/Sabrina; Gen 2: Chuck/
-- Jasmine), so badge COUNT cannot pick the next leader. Cap = lowest ace
-- among leaders not yet beaten. Returns 0 when every gym is owned.
local function nextGymCap(gyms, owned, levelOf)
  local cap = 0
  for _, g in ipairs(gyms) do
    if not owned(g) then
      local level = levelOf(g)
      if level > 0 and (cap == 0 or level < cap) then cap = level end
    end
  end
  return cap
end

local function allOwned(gyms, owned)
  for _, g in ipairs(gyms) do
    if not owned(g) then return false end
  end
  return true
end

local function gen1ChampionCap(mod)
  local cap = maxLevelGen1(mod, M.GEN1_CHAMPION.trainer, nil)
  if cap > 0 then return cap end
  return maxLevelGen1(mod, M.GEN1_LAST_E4.trainer, M.GEN1_LAST_E4.party)
end

local function gen2ChampionCap(mod)
  local cap = maxLevelGen2Entry(mod, M.GEN2_CHAMPION)
  if cap > 0 then return cap end
  return maxLevelGen2Entry(mod, M.GEN2_LAST_E4)
end

local function gen2KantoLeadersCap(mod)
  local max = 0
  for _, g in ipairs(M.GEN2_KANTO_GYMS) do
    local m = maxLevelGen2Entry(mod, g)
    if m > max then max = m end
  end
  return max
end

local function gen2RematchChampionCap(mod)
  return maxLevelGen2Entry(mod, M.GEN2_REMATCH_CHAMPION)
end

local function gen2RedCap(mod)
  return maxLevelGen2Entry(mod, M.GEN2_RED)
end

local function hofCount(save)
  local hof = save and save.hallOfFame
  if type(hof) ~= "table" then return 0 end
  return tonumber(hof.count) or 0
end

local function beatGen2EliteFour(save)
  return hofCount(save) > 0
end

-- Second (or later) Hall of Fame induction ≈ rematch E4/Champion cleared.
local function beatGen2RematchLeague(save)
  return hofCount(save) >= 2
end

local function countBadgeList(owned, gyms)
  local ids = {}
  for _, g in ipairs(gyms) do
    ids[#ids + 1] = g.badge
  end
  return countOwned(ids, owned)
end

local function resolveGen3(mod, game)
  local ladder = gen3Ladder(game)
  local world = mod and mod.world
  if not (ladder and world and world.getFlag) then return nil end
  local gyms = {}
  for i, id in ipairs(ladder.gyms) do
    gyms[i] = { id = id, flag = ("FLAG_BADGE%02d_GET"):format(i) }
  end
  local function owned(g)
    local ok, value = pcall(function() return world:getFlag(g.flag) end)
    return ok and value and true or false
  end
  if not allOwned(gyms, owned) then
    local cap = nextGymCap(gyms, owned, function(g)
      return maxLevelGen3(mod, g.id)
    end)
    return cap > 0 and cap or nil
  end
  local cap = 0
  for _, id in ipairs(ladder.champion) do
    local m = maxLevelGen3(mod, id)
    if m > cap then cap = m end
  end
  if cap == 0 then cap = maxLevelGen3(mod, ladder.lastE4) end
  return cap > 0 and cap or nil
end

--- @return number|nil cap level, or nil if data missing
function M.resolve(mod, game)
  if game and game.generation == 3 then
    return resolveGen3(mod, game)
  end
  if isGen2(game) then
    local save = game.save
    local player = save and save.player
    local johto = type(player and player.badges) == "table" and player.badges or {}
    local function johtoOwned(g) return johto[g.badge] and true or false end
    if not allOwned(M.GEN2_JOHTO_GYMS, johtoOwned) then
      local cap = nextGymCap(M.GEN2_JOHTO_GYMS, johtoOwned, function(g)
        return maxLevelGen2Entry(mod, g)
      end)
      return cap > 0 and cap or nil
    end
    if not beatGen2EliteFour(save) then
      local cap = gen2ChampionCap(mod)
      return cap > 0 and cap or nil
    end

    local kantoN = countBadgeList(player and player.kantoBadges, M.GEN2_KANTO_GYMS)
    local kantoCap = gen2KantoLeadersCap(mod)
    if kantoN < #M.GEN2_KANTO_GYMS then
      return kantoCap > 0 and kantoCap or nil
    end

    if not beatGen2RematchLeague(save) then
      local rematch = gen2RematchChampionCap(mod)
      -- Gold/Silver rematch often reuses first-fight levels; never drop below
      -- the Kanto-leaders ceiling the player already unlocked.
      local cap = rematch
      if kantoCap > cap then cap = kantoCap end
      return cap > 0 and cap or nil
    end

    local red = gen2RedCap(mod)
    if red > 0 then return red end
    -- Red row missing: keep rematch/Kanto ceiling rather than unlocking fully.
    local rematch = gen2RematchChampionCap(mod)
    local cap = rematch
    if kantoCap > cap then cap = kantoCap end
    return cap > 0 and cap or nil
  end

  local save = game and game.save
  local inv = type(save and save.inventory) == "table" and save.inventory or {}
  local function gen1Owned(g) return inv[g.badge] and true or false end
  if not allOwned(M.GEN1_GYMS, gen1Owned) then
    local cap = nextGymCap(M.GEN1_GYMS, gen1Owned, function(g)
      return maxLevelGen1(mod, g.trainer, g.party)
    end)
    return cap > 0 and cap or nil
  end
  local cap = gen1ChampionCap(mod)
  return cap > 0 and cap or nil
end

M.isGen2 = isGen2
M.maxLevelGen1 = maxLevelGen1
M.maxLevelGen2 = maxLevelGen2
M.maxLevelGen2Entry = maxLevelGen2Entry
M.throughTrainerPartyHook = throughTrainerPartyHook

return M
