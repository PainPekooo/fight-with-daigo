# Changelog

Notable changes to this project, most recent first.

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
