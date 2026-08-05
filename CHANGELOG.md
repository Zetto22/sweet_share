# Changelog

All notable changes to **Sweet Share** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project versions with the `version` field in `manifest.json`.

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
