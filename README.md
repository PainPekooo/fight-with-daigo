# Fight with Daigo

A mod for **Street Fighter III: 3rd Strike** (Fightcade v2.0.91 / FBNeo, ROM `sfiii3nr1` "Japan 990512").

A Lua script that, in two-player mode, controls P2 as Ken (white gi) via a
rule-based bot that reads the game state from RAM and decides inputs frame
by frame. It's not a machine-learning-trained model.

**About the name and the current state — being honest about it:** the base
is a bot built on generic fighting-game fundamentals (anti-air, blocking,
throw tech, footsies) — not a model trained on real data about how Daigo
plays. On top of that we did actual research (interviews, his book, FGC
scene analysis) looking for documented tendencies of his, not generic ones.
Result:

- Verified with a direct citation: [Evo Moment 37](https://en.wikipedia.org/wiki/Evo_Moment_37)
  (he played Ken, parried Chun-Li's Super Art, finished with SA3/Shippu
  Jinraikyaku in that specific match — there's no source saying that's his
  default pick in general).
- Verified with direct citations: he plays prioritizing reads and
  whiff-punishing over reacting on reflex ([EventHubs, 2023](https://www.eventhubs.com/news/2023/may/14/daigo-umehara-analyzes-wins-sf6/)),
  profiles the opponent within the first seconds of a match ([EventHubs, 2018](https://www.eventhubs.com/news/2018/may/01/chris-tatarian-sits-down-daigo-umehara-discuss-short-sets-dealing-pressure-ume-shoryu-and-more/)),
  and the "Ume-Shoryu" (throwing out a reversal as a calculated gamble, not
  a guaranteed reflex) is a named phenomenon in the FGC scene, same source.
- No source found: which normal he prefers in footsies, button preference
  for anti-airs, or a "default" SA for Ken outside of Evo Moment 37.

With that in mind, `anti_air.lua` and `block.lua` now have a random delay
before reacting (instead of always reacting on the exact frame), as a first
step toward "read and decide" instead of "fixed trigger" — still far from
actually modeling reads/opponent profiling, which remains a TODO.

## Project status

Functional as a prototype. P2 auto-selects itself (Ken, white gi, SA3)
without touching the controller. During the match:

- Reactive anti-air: shoryuken (random LP/MP/HP, EX if there's meter) 60%
  of the time, a normal anti-air (st.HP) the rest — so it's not 100%
  predictable or always air-parryable — with cooldown and a random delay.
- Melee blocking (based on a real attack hitbox, not distance) and blocking
  against hadoukens (reads the projectile list), with a parry attempt
  before blocking (always against projectiles; occasional — 18% — against
  melee hits, the nod to Evo Moment 37, with Block as a fallback if it
  fails).
- Throw tech at grab range, alternating between a neutral throw and a back
  throw (crosses the opponent to the other side) to avoid being predictable
  on wake-up.
- **Whiff punish**: punishes the opponent the instant they enter recovery,
  with a combo (cr.MK canceled into Super Art if there's meter, or into
  shoryuken if not) instead of a single hit — the only rule based on real
  research about Daigo (see above), not on generic fundamentals. The
  cancel timing (`combo_punish.lua`) still isn't confirmed live — we don't
  know for sure whether it connects as a real combo or as two separate
  hits.
- Footsies: closes the distance (walking, dashing, tatsumaki, offensive
  jump, or holding ground at random — not always a straight line forward)
  and pokes (random cr.MK / cr.MP / st.MP) when the opponent enters range,
  with an occasional step back after poking.

TODO: actually model reads/opponent profiling (beyond the reaction delay
and whiff punish), more research into real sources about Daigo to replace
the generic parameters that remain, and an easter egg: guaranteed parry if
the opponent is Chun-Li and throws her SA2 (Houyoku Sen, Evo Moment 37). A
candidate was found in Chun-Li's framedata (move id `5f54`, 17 hit windows
across 121 frames — matches the profile) but it's not confirmed live yet.

## Requirements

- Fightcade v2.0.91 (or a client running the same FBNeo build)
- A legitimate `sfiii3nr1` (Japan 990512) ROM — **not distributed here, get
  your own**
- Lua Scripting enabled in the emulator

## Structure

```
src/
  main.lua           -- entry point, loads everything else and runs the main loop
  memory.lua         -- memory addresses and player state reading
  projectiles.lua    -- reads the list of active projectiles
  character_select.lua -- forces P2 = Ken (white gi, SA3)
  ai/
    decide.lua       -- orchestrator: priority between the rules below
    util.lua          -- shared helpers (jump posture, directions)
    anti_air.lua      -- reactive shoryuken
    block.lua         -- melee blocking (real hitbox) and projectiles
    parry_fireball.lua -- parry attempt before Block blocks a projectile
    parry_melee.lua   -- occasional melee parry attempt (Evo Moment 37)
    throw_tech.lua    -- throw tech
    super_art.lua     -- Super Art 3 (Shippu Jinraikyaku), used by combo_punish
    combo_punish.lua  -- cr.MK canceled into special/Super Art, used by whiff_punish
    whiff_punish.lua  -- punishes the opponent on recovery
    tatsumaki.lua     -- hurricane kick, used to close distance
    dash.lua          -- forward dash, used to close distance
    jump_in.lua       -- offensive jump, used to close distance
    footsies.lua      -- walk/poke at mid range, orchestrates the approach
```

## Credits

The research into several of the memory addresses used here took as
reference the public work of [Grouflon/3rd_training_lua](https://github.com/Grouflon/3rd_training_lua).
The code in this repo is an original implementation, not a copy.

## Legal notice

This project does not include or distribute ROMs or protected game assets.
It's a third-party mod/tool for personal use with a legitimate copy of the
game.
