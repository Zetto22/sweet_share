-- Gym / post-game level caps for Sweet Share (Gen 1 + Gen 2).
-- Levels are read live from mod.content.trainers so ROM/mods that change
-- leader parties update the cap automatically.

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

local function maxLevelGen1(mod, trainerId, partyIndex)
  if not (mod and mod.content and mod.content.trainers) then return 0 end
  local rec = mod.content.trainers:get(trainerId)
  if type(rec) ~= "table" or type(rec.parties) ~= "table" then return 0 end
  if partyIndex then
    return maxLevelInParty(rec.parties[partyIndex])
  end
  local max = 0
  for _, party in ipairs(rec.parties) do
    local m = maxLevelInParty(party)
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

local function maxLevelGen2(mod, classId, trainerName)
  if not (mod and mod.content and mod.content.trainers) then return 0 end
  local rec = mod.content.trainers:get(classId)
  if type(rec) ~= "table" or type(rec.trainers) ~= "table" then return 0 end
  local max, matched = 0, false
  for _, t in ipairs(rec.trainers) do
    if nameMatch(t, trainerName) then
      matched = true
      local m = maxLevelInParty(t.party)
      if m > max then max = m end
    end
  end
  if matched then return max end
  for _, t in ipairs(rec.trainers) do
    local m = maxLevelInParty(t.party)
    if m > max then max = m end
  end
  return max
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

local function gen1BadgeCount(mod, save)
  local inv = save and save.inventory
  if not inv then return 0 end
  local n = 0
  local list = nil
  if mod.content.constants and mod.content.constants.get then
    list = mod.content.constants:get("badges")
  end
  if type(list) == "table" and #list > 0 then
    for _, entry in ipairs(list) do
      local item = (type(entry) == "table" and (entry.item or entry.id)) or entry
      if item and inv[item] then n = n + 1 end
    end
    return n
  end
  for _, g in ipairs(M.GEN1_GYMS) do
    if inv[g.badge] then n = n + 1 end
  end
  return n
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

--- @return number|nil cap level, or nil if data missing
function M.resolve(mod, game)
  if isGen2(game) then
    local save = game.save
    local player = save and save.player
    local johtoN = countBadgeList(player and player.badges, M.GEN2_JOHTO_GYMS)
    if johtoN < #M.GEN2_JOHTO_GYMS then
      local nextGym = M.GEN2_JOHTO_GYMS[johtoN + 1]
      local cap = maxLevelGen2Entry(mod, nextGym)
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

  local n = gen1BadgeCount(mod, game and game.save)
  if n < #M.GEN1_GYMS then
    local nextGym = M.GEN1_GYMS[n + 1]
    local cap = maxLevelGen1(mod, nextGym.trainer, nextGym.party)
    return cap > 0 and cap or nil
  end
  local cap = gen1ChampionCap(mod)
  return cap > 0 and cap or nil
end

M.isGen2 = isGen2
M.maxLevelGen1 = maxLevelGen1
M.maxLevelGen2 = maxLevelGen2
M.maxLevelGen2Entry = maxLevelGen2Entry

return M
