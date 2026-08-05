# gen1recomp_mods

Mods for [gen1recomp](https://github.com/bryanthaboi/gen1recomp) (LÖVE2D / Lua). Each mod lives in its own folder at the repo root.

API docs: [gen1recomp wiki](https://github.com/bryanthaboi/gen1recomp/wiki)

# Sweet Share

Party-wide experience after a KO: every Pokémon that battles gets the **full**
EXP amount (not split among who battle). Other conscious party members get
**half**. Optional level gates keep the bench from outpacing slot 1 or the
party’s strongest member.

Disabling the mod restores the stock EXP award (including the EXP Share item).

## Install

1. Copy this folder into the game's `mods/` directory  
   (or import the release zip)
2. Enable it in Options → Mod Manager
3. Restart (or `POKEPORT_DEV=1` + F5 while developing)

## Options

In the game **Options** menu, cycle **SWEET EXP SHARE** with LEFT / RIGHT:

| Value | Meaning |
|-------|---------|
| OFF | Vanilla EXP (EXP Share item works) |
| ON | Full exp for who participated in the battle, half for the bench (default) |
| ACTIVE | Same as ON but bench only receives EXP if level is below pokemon on slot 1 |
| TOP LEVEL | Same as ON but bench only receives EXP if level is below pokemon on party with the high level |

## Notes

- Content mod (`affects_link: false`).
- Fainted party members do not receive shared EXP.
- Pokemon who participated in the battle always receive full EXP in ON / ACTIVE / TOP LEVEL.
- Bench share text: `All remaining Pokémon got X EXP each!` (or
  `N Pokémon got X EXP each!` when a gate excludes someone).
- While SWEET EXP SHARE is ON/ACTIVE/TOPLEVEL, the EXP SHARE item is ignored.
- GitHub releases for in-game Update must use tag **`vX.Y.Z`** (e.g. `v0.1.1`)
  with asset **`sweet_share-X.Y.Z.zip`**. Prefixed tags are ignored by
  the launcher.
- License: [MIT](LICENSE) · Changes: [CHANGELOG.md](CHANGELOG.md)
