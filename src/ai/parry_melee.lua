-- Occasional melee parry attempt. Evo Moment 37 was exactly this — a parry
-- against a melee combo (Chun-Li's Super Art), not a projectile like
-- parry_fireball.lua. Low probability on purpose: if it fails, Ken eats the
-- hit clean without blocking at all, much worse than the normal block
-- (which is reliable). Most of the time Block.decide() still handles this
-- (see decide.lua) — this is an occasional attempt on top, not a
-- replacement.
--
-- Parry direction: forward for high/mid hits, down for low ones. We
-- approximate "low" by checking whether the opponent is crouching (most
-- sweeps/low hits are crouching moves) — not perfect, but reasonable.
--
-- Easter egg: if the opponent is Chun-Li and picked SA2 (Houyoku Sen) at
-- character select, Ken taps the parry direction repeatedly for as long as
-- the hitbox stays active, instead of the normal single edge-triggered
-- attempt — the Evo Moment 37 recreation. We originally tried to identify
-- Houyoku Sen by its exact action_state id using the reference repo's
-- framedata as a shortcut (candidate "5f54"), but a live test showed the
-- real value doesn't match that format at all — so instead we lean on the
-- fact that a character can only have one Super Art selected per match
-- (see opponent_tracker.lua): if she picked SA2, any super she throws for
-- the rest of the match IS Houyoku Sen, no move-fingerprinting needed.
--
-- The single-attempt version (used for every other melee threat) also
-- turned out to be the wrong shape for a 15-hit flurry: it only fires on
-- the rising edge of "has an active attack hitbox", so if that hitbox
-- stays continuously active through the whole multi-hit super (rather than
-- toggling between individual hits), the edge only happens ONCE for the
-- entire flurry — one missed attempt and there's no retry for the
-- remaining ~14 hits, which looked from the outside exactly like never
-- attempting at all. Mashing for the whole duration instead gives many
-- chances across the flurry.

ParryMelee = {}

-- Raised from 0.18 to 0.4 for max difficulty ("al palo") — more parry
-- attempts, and therefore more whiffed ones too when it fails (Block still
-- covers most hits either way, see decide.lua).
local ATTEMPT_CHANCE = 0.4
local CHUNLI_SA2_INDEX = 1 -- 0-based: SA1=0, SA2=1, SA3=2 (same convention as ours)
local was_threatened = false

local MASH_CYCLE_FRAMES = 2 -- 1 tap, 1 release
local mash_counter = 0

local function is_evo_moment_37(opponent_state)
  return opponent_state.char_name == "chunli" and OpponentTracker.selected_sa == CHUNLI_SA2_INDEX
end

local function parry_direction(self_state, opponent_state)
  if opponent_state.posture == Memory.POSTURE.CROUCHING then
    return "P2 Down"
  end
  return AIUtil.forward_input(self_state, opponent_state)
end

function ParryMelee.decide(input)
  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)

  if AIUtil.is_jumping(self_state.posture) then
    was_threatened = false
    mash_counter = 0
    return false
  end

  local threatened = Memory.has_active_attack_box(AIUtil.OPPONENT_ID)
    and not AIUtil.is_jumping(opponent_state.posture)

  if threatened and is_evo_moment_37(opponent_state) then
    was_threatened = true
    mash_counter = (mash_counter + 1) % MASH_CYCLE_FRAMES
    if mash_counter == 0 then
      input[parry_direction(self_state, opponent_state)] = true
      return true
    end
    return false
  end
  mash_counter = 0

  local just_started = threatened and not was_threatened
  was_threatened = threatened

  if not just_started then
    return false
  end

  if math.random() >= ATTEMPT_CHANCE then
    return false -- let Block handle it this time, we don't attempt it
  end

  input[parry_direction(self_state, opponent_state)] = true
  return true
end
