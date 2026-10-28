# Changelog

All notable changes to **Sweet Share** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project versions with the `version` field in `manifest.json`.

## [1.4.0] — 2026-10-28

<!-- release-title: Gen 3: FireRed, LeafGreen, Ruby, Sapphire, Emerald -->

### Added

- **FireRed, LeafGreen, Ruby, Sapphire and Emerald** support for
  **S. EXP SHARE** and every **S. LEVEL CAP** mode.
- **GYM LVL** on Gen 3: Hoenn leaders (Roxanne to Juan / Wallace, then
  the Champion) and Kanto leaders on FireRed / LeafGreen (Brock to
  Giovanni, then the rival Champion), read from the badge flags.
- On Gen 3, a held **EXP. SHARE** no longer halves Sweet's grants.

### Notes

- Gen 3 has no free-form battle line, so the bench shows the game's own
  "gained N EXP" line per Pokémon instead of one summary.

## [1.3.0] — 2026-10-28

<!-- release-title: Silver, Crystal and out-of-order gyms -->

### Added

- **Silver** and **Crystal** support (all Gen 2 games).

### Changed

- **GYM LVL** uses the lowest ace among leaders you have not beaten yet,
  so gyms taken out of order (Jasmine before Chuck, Koga before Erika…)
  no longer cap you at a leader you already beat.
- With **S. EXP SHARE** ON, Gen 2 fighters now get full EXP each, like
  Gen 1 and as documented (before, Gen 2 split it among fighters).
- Gen 2 bench EXP is paid silently under the single summary line through
  the engine's `applyShare` (needs gen1recomp **0.2.19+**; older builds
  also print one line per Pokémon).

### Fixed

- Gen 2 with **S. EXP SHARE** OFF and a **S. LEVEL CAP** on: the cap now
  actually blocks EXP (it was ignored).

## [1.2.0] — 2026-08-20

<!-- release-title: GYM LVL follows live trainer parties -->

### Changed

- **GYM LVL** reads the same live boss party battle uses (`trainer.party`
  hook), so difficulty mods that raise gym/E4 teams (e.g. Stronger Trainers)
  raise the cap automatically — no per-mod wiring.

## [1.1.4] — 2026-08-14

<!-- release-title: Fix crash under mod sandbox -->

### Fixed

- Works again on gen1recomp **0.1.84+** (mod sandbox): Gen 1 EXP share and
  Gen 2 awards with a level cap no longer silently fall back to vanilla.

## [1.1.3] — 2026-08-13

<!-- release-title: Fix Gen 2 EXP share and level-cap awards -->

### Fixed

- On Gold, Sweet Share and level-cap options apply correctly in battle.
- Bench Pokémon get half EXP again (including with ACTIVE / TOP LVL / GYM LVL).
- After the share summary, Gold no longer shows each bench mon’s individual
  “gained EXP” line (level-ups still show).

### Changed

- Share summary always shows the count (`2 others got…` / `One more got…`).

## [1.1.1] — 2026-08-13

<!-- release-title: Shorter level-cap option labels -->

### Changed

- Options values change from **TOP LEVEL** and **GYM LEVEL** to **TOP LVL** and **GYM LVL** (fit the Options box).

## [1.1.0] — 2026-08-13

<!-- release-title: Gen 2, split Options, gym level cap -->

### Added

- Support to **Pokémon Gold** / Gen 2.
- Level cap works with Sweet Share off (works with other EXP mods).
- **GYM LEVEL** hard cap (next gym / story bosses; see README).

### Changed

- Options split into **S. EXP SHARE** and **S. LEVEL CAP**.
- Level cap is independent from the share toggle.
- Legacy single-option saves migrate to the new rows.
- Ignores the held EXP.SHARE item while Sweet Share is on.

## [1.0.0] — 2026-08-04

<!-- release-title: First stable release -->

### Added

- First stable release after in-game smoke.
- Options row **SWEET EXP SHARE**: OFF / ON / ACTIVE / TOP LEVEL (default ON).
- Fighters get full undivided EXP; eligible conscious bench gets half.
- ACTIVE / TOP LEVEL gates; fainted bench skipped; Mod Manager disable
  restores vanilla immediately (staged).

### Changed

- Bench messages fit the 18-column box:
  `The others got` / `X EXP each!`, `N others got` / `X EXP each!`,
  or `One more got` / `X EXP!`.

## [0.1.6] — 2026-08-04

<!-- release-title: Shorter share lines under 18 cols -->

### Changed

- Bench lines rewritten to fit the 18-column box with no soft-wrap:
  `The others got` / `X EXP each!`, `N others got` / `X EXP each!`,
  or singular `One more got` / `X EXP!`.

## [0.1.5] — 2026-08-04

<!-- release-title: Singular EXP line; real staged disable -->

### Fixed

- Singular bench line is `1 Pokémon got X EXP!` (no “each”).
- Staged Mod Manager disable is detected via `options.mods[id]` (the entry
  `mod` object has no live `enabled`); Options row and share stop at once.

## [0.1.4] — 2026-08-04

<!-- release-title: Fit share text; honor staged disable -->

### Fixed

- Bench line fits the GB text box (`All remaining` / `got X EXP each!`).
- Disabling the mod in Mod Manager (even STAGED, before restart) removes
  the Options row and restores vanilla EXP award immediately.

## [0.1.3] — 2026-08-04

<!-- release-title: Unified got-EXP-each share line -->

### Changed

- Bench line is now `All remaining Pokémon got X EXP each!` (or
  `N Pokémon got X EXP each!`); ACTIVE / TOP LEVEL tags dropped from
  the message.

## [0.1.2] — 2026-08-04

<!-- release-title: Clearer each-got share messages -->

### Changed

- Bench lines now say **each got** so the amount is per Pokémon, not a
  pot split among them (e.g. `3 Pokémon each got 52 EXP!`).

### Fixed

- Predicted bench EXP is checked against the real `applyShare` grant
  (`battle.exp_gained`); mismatches log a warning.

## [0.1.1] — 2026-08-04

<!-- release-title: Share messages include EXP amount -->

### Changed

- Bench share lines now include the exact EXP each recipient gets
  (e.g. `3 Pokémon shared 42 EXP!`).

## [0.1.0] — 2026-08-04

<!-- release-title: First experimental build -->

### Added

- Options row **SWEET EXP SHARE**: OFF / ON / ACTIVE / TOP LEVEL (default ON).
- Battle EXP: fighters get full undivided EXP; eligible bench gets half.
- ACTIVE gate: bench only if below party slot 1’s level.
- TOP LEVEL gate: bench only if below the party’s highest level.
- Share message per mode with recipient count.
