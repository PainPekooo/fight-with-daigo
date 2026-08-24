# Changelog

Notable changes to this project, most recent first.

## Removed temporary debug overlay

- Investigated a reported bug where P2 defaulted to SA1 instead of SA3 on
  a "continue" after losing. Confirmed live (twice, including coming out
  of attract-mode demo play) that P2 correctly locks in SA3 — looks like it
  was intermittent, not a real regression. Removed the temporary debug text
  added to track it down.

## Difficulty: tighter reaction delay

- Shrunk the random reaction delay before anti-air (2-6 → 1-3 frames) and
  before blocking a projectile (2-5 → 1-2 frames), on request — trades a
  bit of the "human" feel for being harder to beat.

## README: new banner image

- Swapped the title banner for a more dynamic action shot (Ken taking a
  jump kick), text repositioned to the bottom so it doesn't cover the hit.

## README: synopsis + how-to up top

- Added a short, punchy synopsis right after the title.
- Moved "How to install & run" to the top of the README so it doesn't
  require scrolling past all the technical detail first.

## README: install instructions and banner

- Added a "How to install & run" section (get the ROM, download the repo,
  load `src/main.lua` in Fightcade's Lua console), including a note about
  Fightcade-as-Flatpak sandboxing on Linux.
- Added a title banner image (`docs/banner.png`).

## Translated to English

- README and every code comment translated from Spanish to English (same
  logic, same behavior — comments and user-facing strings only).

## Whiff punish, Super Art, EX moves, melee parry, more variety

- **Whiff punish**: punishes the opponent the instant they enter recovery
  with a combo (cr.MK canceled into Super Art or shoryuken) instead of
  waiting for Footsies' normal pace — the one rule grounded in real
  research about Daigo instead of generic fundamentals.
- Super Art 3 (Shippu Jinraikyaku) execution, plus EX versions of shoryuken
  and tatsumaki when meter is available.
- Occasional melee parry attempt (Evo Moment 37 nod), with Block as a
  reliable fallback if it fails.
- Anti-air variety: a normal anti-air (st.HP) instead of shoryuken part of
  the time, so it isn't 100% predictable/air-parryable.
- Footsies: added a "hold ground / retreat" approach option so it isn't
  always a straight line forward; fixed a bug where the tatsumaki would
  abort mid-sequence.
- Throw tech: alternates between a neutral throw and a back throw instead
  of always the same one.

## Initial release: rule-based AI bot for Ken

- P2 auto-joins, auto-selects Ken (white gi) and Super Art 3, no controller
  input needed.
- Anti-air (reactive shoryuken), blocking (real attack-hitbox detection for
  melee, projectile-list reading for hadoukens), throw tech, and footsies
  (walk/poke at mid range).
