# Changelog

All notable changes to **Sweet Share** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project versions with the `version` field in `manifest.json`.

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
