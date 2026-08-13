# Changelog

All notable changes to **Sweet Share** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project versions with the `version` field in `manifest.json`.

## [1.1.0] — 2026-08-13

<!-- release-title: Gen 2, split Options, gym level cap -->

### Added

- Runs on **Pokémon Gold** as well as Red/Blue/Yellow (`games`: gen1 + gen2).
- Gen 2 award path: battle text via `emit`, EXP prediction matches Gold’s
  formula (Lucky Egg / outsider / trainer), eggs skipped on the bench.
- **S. EXP SHARE OFF** + level cap: vanilla (or another `battle.exp_award`
  mod) still runs; `applyShare` is filtered so the cap works alone or with
  other EXP-share mods.
- **S. LEVEL CAP → GYM LEVEL** (hard cap): threshold is the next gym
  leader’s strongest Pokémon. After 8 badges, Gen 1 uses the Champion
  rival (`OPP_RIVAL3`, else Lance). On Gold: Johto gyms → first Lance → max Kanto leaders →
  rematch Lance (after 8 Kanto badges; HoF count &lt; 2) → Red (HoF count ≥ 2).

### Changed

- Options split into two rows:
  - **S. EXP SHARE** — OFF / ON (default ON)
  - **S. LEVEL CAP** — OFF / ACTIVE / TOP LEVEL / GYM LEVEL (default OFF)
- Level cap is independent of Sweet’s own share toggle.
- Legacy single-dial `sweetShare` values (`active` / `top`) migrate to
  share ON + the matching cap; old `on` keeps an ungated bench (cap OFF).
- While Sweet share is ON, Gen 2’s held **EXP.SHARE** tax is cleared on
  `exp.gain` so modes are not halved by the item (unequip to keep stat EXP
  fully untaxed).

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
