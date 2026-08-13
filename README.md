# gen1recomp_mods

Mods for [gen1recomp](https://github.com/bryanthaboi/gen1recomp) (LÖVE2D / Lua). Each mod lives in its own folder at the repo root.

API docs: [gen1recomp wiki](https://github.com/bryanthaboi/gen1recomp/wiki)

# Sweet Share

Optional party EXP share and/or a **level cap** on who may receive EXP after a KO.

When **S. EXP SHARE** is ON: fighters get **full** EXP; other conscious
party members get **half**, optionally gated by level.

When **S. EXP SHARE** is OFF: the stock award (or another EXP-share mod)
runs, and **S. LEVEL CAP** can still filter who gets EXP.

**GYM LEVEL** is a hard cap from the next gym leader (or post-game rules
below): anyone at or above that level gets no EXP.

Works on **Red / Blue / Yellow** and **Gold**.

## Install

1. Copy this folder into the game's `mods/` directory  
   (or import the release zip)
2. Enable it in Options → Mod Manager
3. Restart (or `POKEPORT_DEV=1` + F5 while developing)

## Options

| Option | Values | Meaning |
|--------|--------|---------|
| **S. EXP SHARE** | OFF / ON | ON = Sweet’s full/half share (default ON). OFF = vanilla or another share mod. |
| **S. LEVEL CAP** | OFF / ACTIVE / TOP LEVEL / **GYM LEVEL** | See below (default OFF). |

### Level Cap modes

| Mode | Who is blocked | Threshold |
|------|----------------|-----------|
| OFF | Nobody | — |
| ACTIVE | Non-fighters only | `level <` party slot 1 |
| TOP LEVEL | Non-fighters only | `level <` highest party level |
| **GYM LEVEL** | **Everyone** (hard) | Next gym leader’s strongest mon (live trainer data) |

**GYM LEVEL progression**

| Game | Progress | Cap source |
|------|----------|------------|
| Gen 1 | 0–7 badges | Next Kanto gym leader max level |
| Gen 1 | 8 badges | Champion rival (`OPP_RIVAL3`); Lance only if rival data missing |
| Gen 2 | 0–7 Johto badges | Next Johto gym leader |
| Gen 2 | 8 Johto, before HoF | Champion Lance (else Karen) |
| Gen 2 | HoF done, &lt; 8 Kanto badges | Max ace among all Kanto gym leaders |
| Gen 2 | 8 Kanto badges, HoF count &lt; 2 | Rematch Lance (never below Kanto max) |
| Gen 2 | HoF count ≥ 2 | Red (Mt. Silver) |

| EXP SHARE | LEVEL CAP | Result |
|-----------|-----------|--------|
| ON | OFF | Sweet share, whole conscious bench |
| ON | ACTIVE / TOP | Sweet share + soft bench gate |
| ON | GYM LEVEL | Sweet share + hard gym/post-game cap |
| OFF | OFF | Fully vanilla / other mods |
| OFF | ACTIVE / TOP / GYM | Other award + our filter |

## Notes

- Content mod (`affects_link: false`). Targets Gen 1 and Gen 2 (`games`).
- Cap-only mode wraps `applyShare` before `next` (other share mods that use it compose; keep this mod’s priority ≥ theirs).
- Gym levels are read from `trainers` at runtime — party edits by other mods count.
- Fainted mons and eggs never receive Sweet/capped grants.
- While **S. EXP SHARE** is ON, Gen 1 EXP.ALL / Gen 2 held EXP.SHARE vanilla passes are replaced; on Gold, unequip EXP.SHARE if you want stat EXP free of the item tax.
- GitHub releases: tag **`v1.1.0`** + asset **`sweet_share-1.1.0.zip`**.
- License: [MIT](LICENSE) · Changes: [CHANGELOG.md](CHANGELOG.md)
