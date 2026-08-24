# Changelog

Notable changes to this project, most recent first.

## Add a third read: turtle/keep-away (not just projectile zoning)

- New tendency in `opponent_reads.lua`: counts episodes of the opponent
  walking backward (`WALK_BACK` posture), saturating like the existing
  reads. Broader than the zoner read — picks up a keep-away playstyle even
  from a character with no fireball to detect.
- `footsies.lua`'s approach-mode picker now blends toward closing the
  distance (dash/tatsumaki) based on `max(zoner, turtle)` instead of just
  `zoner` — either signal alone is enough to trigger the same "stop letting
  them dictate range" response.
- Considered and skipped two other candidates: a "jumps out of wakeup"
  read (likely redundant — AntiAir already has priority over WakeupMixup
  and should already catch it) and a "favorite poke" read (would need
  per-character move-name identification, the same scope/licensing
  question already resolved against for framedata — see the effie3rd
  entries below).

## Investigated "precise" parry gating — mapped the data, reverted the gate

- Cross-checked effie3rd/3rd_training_lua's `memory_addresses.lua`
  (GPL-3.0, read only — see reference memory) against our own parry
  validity/cooldown addresses: their P1 addresses matched ours exactly,
  and their P2 addresses matched our own offset math, good independent
  confirmation. Added the `state` address (cooldown + 2 bytes) we didn't
  have before.
- Tried gating `ParryFireball`/`ParryMelee`'s attempts on `state == 1`
  ("can attempt right now"), based on how their code force-writes 1/3 for
  an auto-parry cheat feature. Live-logged our own `state` values before
  trusting it: it isn't a simple binary, it's a 5-value cycle (0-4) whose
  exact meaning isn't decoded yet. Reverted the gate rather than ship
  behavior based on a disproven assumption — see `memory.lua` for what we
  now know and don't. Nothing in `ai/` reads `state` right now.

## Live-playtest fixes: wake-up grab spam, tatsumaki spam, EX meter waste

- **Wake-up throw spam**: `WakeupMixup`'s throw choice used to mash the
  grab input for the entire knockdown window instead of a bounded number
  of attempts. Reported live: it was an obvious tell (Ken visibly flailing
  the grab the whole time), letting a reversal shoryuken always beat it
  clean on wake-up. Now bounded to `THROW_ATTEMPT_CYCLES` (3) press/release
  cycles, then holds position instead of continuing to mash.
- **Footsies approach spam**: `pick_approach_mode()` had no memory of the
  last pick, so a long retreat/chase (many independent rolls in a row)
  could land on the same mode — reported live as Ken repeatedly spamming
  tatsumaki while chasing a retreating opponent. Now discounts whatever was
  picked last time to 15% of its normal weight before rerolling, so it can
  still repeat occasionally but rarely back-to-back.
- **EX meter waste**: EX tatsumaki (`tatsumaki.lua`) and Super Art
  (`combo_punish.lua`/`whiff_punish.lua`) both spend the same `gauge >= 1`
  meter. Reported live as spamming EX just to close distance, directly
  emptying the meter the whiff-punish combo needs for its bigger payoff.
  Shrunk EX tatsumaki's chance from 0.3 to 0.1.
- **Diagnosed and fixed the reported "blocks a Super Art from the right
  once, then eats a later one" bug** (temporary debug logging, console
  Output box scrollback, same style as the earlier left/right block bug —
  removed again now that it's understood). Ruled out: a left/right
  direction bug — every backward-block direction logged across the whole
  session was correct for both sides, matching the earlier investigation's
  conclusion that this game's block issues aren't actually side-dependent.
  Real cause: `ParryFireball` attempted a parry tap (pressing forward)
  unconditionally on every projectile overlap, unlike `parry_melee.lua`
  which only attempts a fraction of the time. Pressing forward for that one
  frame meant no block was held, and both logged hits landed ~2 frames
  after a tap — when the tap's parry attempt failed, Ken had no guard up
  for the hit that followed. (A second, smaller hit later in the same
  encounter, ~7 frames after the block had resumed and stayed held, looks
  like normal chip damage from blocking a multi-hit Super Art rather than a
  block failure — blocking doesn't fully no-sell super chip damage in this
  game.) Fix: gated `ParryFireball` the same way melee already is — rolls
  once per incoming projectile (`ATTEMPT_CHANCE = 0.5`) instead of
  attempting on every single one, so Block covers the rest without taking
  the guard-drop risk.

## Add predictive blocking (live-learned per-move startup timing)

- Looked at effie3rd/3rd_training_lua (a training-mode rewrite with full
  per-character framedata) as a possible source for the "frame data for
  the whole cast" the known block limitation needed. It's GPL-3.0
  licensed, which would mean relicensing this whole project as GPL to
  distribute anything derived from its compiled data/code — decided
  against that, same principle already applied to Grouflon's (unlicensed)
  reference repo: read for understanding, never copy code/data in.
- Instead, new `opponent_move_timing.lua`: times, live, how many frames
  elapse between a given (character, action_state) starting and its
  attack hitbox going active. First time any move is seen, nothing to
  predict yet — Block stays purely reactive for it, same as before. Next
  time the SAME move shows up, Block starts blocking `PREDICT_LEAD_FRAMES`
  (2, unverified starting guess) frames before the hitbox is expected,
  instead of waiting for it — directly targets the fast-close-normal block
  gap without any external data or license entanglement.
- `Block.has_threat()` and `Block.decide()` now treat a predicted
  soon-to-be-active hit the same as an already-active one (still gated on
  the opponent not jumping, same as the reactive case — that's AntiAir's
  job).
- Not live-tested yet — the lead value in particular will need tuning once
  it's actually seen blocking a repeat move early in a real match.

## Add opponent "reads" (lightweight profiling, not a game-tree search)

- New `opponent_reads.lua`: tracks two live tendencies for the whole
  session (persists across rounds/matches, not reset each round) — how
  often the opponent jumps in close, and how often they throw projectiles
  — as simple saturating counters (a handful of repeats is enough to act
  on, not statistical significance).
- Anti-air now scales its range, reaction delay, shoryuken chance, and EX
  chance up as the "jumps in a lot" read climbs — against a jump-happy
  opponent it converges on a near-instant, near-certain DP instead of the
  same 75%/0-1-frame baseline used against everyone.
- Footsies now blends its approach-mode weights toward closing the
  distance fast (dash/tatsumaki, less walk/retreat) as the "zones a lot"
  read climbs, instead of walking into fireballs at a fixed pace.
- Considered and ruled out a real decision-tree/minimax search: that needs
  simulating the opponent's future moves, which isn't possible live
  against an unknown human (no rewind/save-state the way TAS tools use to
  get "perfect" play — those aren't reactive AI, they're offline
  rerecording against a known/fixed opponent).

## Max difficulty pass ("al palo")

- Re-enabled Footsies (had been temporarily commented out while debugging
  parry timing).
- Cut anti-air and block reaction delay to near frame-perfect (0-1 frames,
  down from 1-3 and 1-2), widened both their trigger ranges, and raised
  shoryuken/EX-shoryuken frequency (0.6→0.75, 0.3→0.5).
- Raised melee parry attempt chance (0.18→0.4) and widened whiff-punish
  range (100→130).
- Made footsies more aggressive: shorter poke cooldown, less retreating,
  and more weight on dash/tatsumaki over plain walking to close distance.
- All still probabilistic/randomized, not hard-reads or frame-perfect
  reflexes on every single interaction — see the trade-offs called out
  inline in each file (e.g. `SRK_CHANCE` staying under 1.0 in
  `anti_air.lua` so DP stays air-parryable, not a guaranteed reflex).

## Investigated a reported left/right blocking bug — found something else

- Live-debugged (console logging with scrollback) a report that Ken failed
  to block on one particular side. Ruled out: every direction/threat
  calculation checked out correct on both sides, and the user confirmed
  reproducing it on both sides too.
- Real finding: it's about range, not side. Point-blank hits sometimes beat
  the block, mid-range ones don't — likely because "close" normals in this
  game tend to have faster startup than their "far" versions, and reactive
  (react-only-once-active) blocking has zero lead time. Documented as a
  known limitation (see README) rather than a bug — fixing it for real
  needs predictive blocking with frame data for the whole cast.
- Along the way: Block no longer always crouches — only for lows (opponent
  crouching), standing block otherwise (including projectiles), which
  looked odd before.

## Evo Moment 37 easter egg: fix mash-vs-single-attempt bug

- Live-tested with `opponent_sa` debug confirmed correctly captured (1 =
  SA2), but Ken still ate the whole Houyoku Sen. Cause: the parry attempt
  only fired once, on the rising edge of "opponent has an active attack
  hitbox" — if that hitbox stays continuously active through the whole
  15-hit flurry instead of toggling per hit, that edge only happens once
  for the entire super, so a single missed attempt meant no more retries
  for the remaining hits. For this specific case, Ken now taps the parry
  direction repeatedly for as long as the threat lasts, giving many chances
  across the flurry instead of one.

## Evo Moment 37 easter egg

- Guaranteed melee parry (100% instead of 18%) if the opponent is Chun-Li
  and picked SA2 (Houyoku Sen) at character select.
- Live-verified that the framedata-based move-id candidate we had for
  Houyoku Sen (`5f54`) was wrong — the real `action_state` value doesn't
  match that format. Pivoted to a more robust approach that doesn't need
  to fingerprint the specific move: since a character can only pick one
  Super Art per match, knowing Chun-Li picked SA2 is enough on its own.

## Wake-up mixup

- On a knockdown, Ken now alternates between a throw attempt and a meaty
  poke instead of always standing there mashing the same grab input, which
  telegraphed exactly what was coming.

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
