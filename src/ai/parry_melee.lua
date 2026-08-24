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

ParryMelee = {}

local ATTEMPT_CHANCE = 0.18
local was_threatened = false

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

  if math.random() >= ATTEMPT_CHANCE then
    return false -- let Block handle it this time, we don't attempt it
  end

  if opponent_state.posture == Memory.POSTURE.CROUCHING then
    input["P2 Down"] = true
  else
    input[AIUtil.forward_input(self_state, opponent_state)] = true
  end

  return true
end
