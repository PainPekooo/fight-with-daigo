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
-- character select, the attempt chance goes to 100% instead of 18% — the
-- Evo Moment 37 recreation. We originally tried to identify Houyoku Sen by
-- its exact action_state id using the reference repo's framedata as a
-- shortcut (candidate "5f54"), but a live test showed the real value
-- doesn't match that format at all — so instead we lean on the fact that a
-- character can only have one Super Art selected per match (see
-- opponent_tracker.lua): if she picked SA2, any super she throws for the
-- rest of the match IS Houyoku Sen, no move-fingerprinting needed. Since
-- this re-triggers on every rising edge of "opponent has an active attack
-- hitbox", it naturally re-attempts the parry on each hit of the flurry,
-- not just the first one.

ParryMelee = {}

local ATTEMPT_CHANCE = 0.18
local CHUNLI_SA2_INDEX = 1 -- 0-based: SA1=0, SA2=1, SA3=2 (same convention as ours)
local was_threatened = false

local function is_evo_moment_37(opponent_state)
  return opponent_state.char_name == "chunli" and OpponentTracker.selected_sa == CHUNLI_SA2_INDEX
end

function ParryMelee.decide(input)
  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)

  if AIUtil.is_jumping(self_state.posture) then
    was_threatened = false
    return false
  end

  local threatened = Memory.has_active_attack_box(AIUtil.OPPONENT_ID)
    and not AIUtil.is_jumping(opponent_state.posture)

  local just_started = threatened and not was_threatened
  was_threatened = threatened

  if not just_started then
    return false
  end

  local attempt_chance = is_evo_moment_37(opponent_state) and 1.0 or ATTEMPT_CHANCE
  if math.random() >= attempt_chance then
    return false -- let Block handle it this time, we don't attempt it
  end

  if opponent_state.posture == Memory.POSTURE.CROUCHING then
    input["P2 Down"] = true
  else
    input[AIUtil.forward_input(self_state, opponent_state)] = true
  end

  return true
end
