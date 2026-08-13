# gen1recomp_mods

Mods for [gen1recomp](https://github.com/bryanthaboi/gen1recomp) (LÖVE2D / Lua). Each mod lives in its own folder at the repo root.

API docs: [gen1recomp wiki](https://github.com/bryanthaboi/gen1recomp/wiki)

# Sweet Share

Optional party EXP share and/or a **level cap** on who may receive EXP after a KO.

When **S. EXP SHARE** is ON: fighters get **full** EXP; other conscious
party members get **half**, optionally gated by level.

When **S. EXP SHARE** is OFF: the stock award (or another EXP-share mod)
runs, and **S. LEVEL CAP** can still filter who gets EXP.

**GYM LVL** is a hard cap from the next gym leader (or post-game rules
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
| **S. LEVEL CAP** | OFF / ACTIVE / TOP LVL / **GYM LVL** | See below (default OFF). |

| EXP SHARE | LEVEL CAP | Result |
|-----------|-----------|--------|
| ON | OFF | Sweet share, whole bench |
| ON | ACTIVE / TOP LVL | Sweet share + soft bench cap |
| ON | GYM LVL | Sweet share + hard gym/post-game cap |
| OFF | OFF | Fully vanilla / other mods |
| OFF | ACTIVE / TOP LVL / GYM LVL | Vanilla / Other mods + cap |

### Level Cap modes

| Mode | Who is blocked | Threshold |
|------|----------------|-----------|
| OFF | Nobody | — |
| ACTIVE | Non-fighters only | Below party slot 1’s level |
| TOP LVL | Non-fighters only | Below the party’s highest level |
| **GYM LVL** | **Everyone** (hard) | Story-based cap (see below). Anyone at or above the cap gets no EXP. |

### GYM LVL — Gen 1 RBY

Hard cap: nobody at or above the threshold gains EXP. The number is the
**highest level** on that boss’s party (read live from trainer data, so
mods that change gym teams update the cap automatically).

| Your badges | Cap is based on |
|-------------|-----------------|
| 0 | Brock (Pewter) |
| 1 | Misty (Cerulean) |
| 2 | Lt. Surge (Vermilion) |
| 3 | Erika (Celadon) |
| 4 | Koga (Fuchsia) |
| 5 | Sabrina (Saffron) |
| 6 | Blaine (Cinnabar) |
| 7 | Giovanni (Viridian) |
| 8 | **Champion** — your rival’s league team (Lance only if that data is missing) |

Example: with **0 badges**, a Pokémon at Brock’s Onix level (or higher)
gains no EXP. After the Boulder Badge, the cap becomes Misty’s ace, and
so on until the Champion.

### GYM LVL — Gen 2 GSC

Same hard-cap rule; the ladder continues through Johto, the League,
Kanto, a rematch, then Red.

**Johto gyms (next leader)**

| Johto badges | Cap is based on |
|--------------|-----------------|
| 0 | Falkner (Violet) |
| 1 | Bugsy (Azalea) |
| 2 | Whitney (Goldenrod) |
| 3 | Morty (Ecruteak) |
| 4 | Chuck (Cianwood) |
| 5 | Jasmine (Olivine) |
| 6 | Pryce (Mahogany) |
| 7 | Clair (Blackthorn) |

**After 8 Johto badges**

| Order | Cap is based on |
|-------|-----------------|
| 1 | Lance (first Champion fight) |
| 2 | Strongest Kanto gym ace (after first Hall of Fame) |
| 3 | Lance (Champion rematch, after 8 Kanto badges) |
| 4 | Red (Mt. Silver, after second Hall of Fame) |

## Notes

- Content mod (`affects_link: false`). Targets Gen 1 and Gen 2 (`games`).
- Cap-only mode wraps `applyShare` before `next` (other share mods that use it compose; keep this mod’s priority ≥ theirs).
- Gym levels are read from `trainers` at runtime — party edits by other mods count.
- Fainted mons and eggs never receive Sweet/capped grants.
- While **S. EXP SHARE** is ON, Gen 1 EXP.ALL / Gen 2 held EXP.SHARE vanilla passes are replaced; on Gold, unequip EXP.SHARE if you want stat EXP free of the item tax.
- GitHub releases: tag **`v1.1.2`** + asset **`sweet_share-1.1.2.zip`**.
- License: [MIT](LICENSE) · Changes: [CHANGELOG.md](CHANGELOG.md)
