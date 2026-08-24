-- Whiff punish: unlike the rest of the moveset (generic fighting-game
-- fundamentals we made up ourselves), this one is actually based on real
-- research about Daigo (see README) — his documented strength is
-- "whiff-punishing over reacting," not any particular anti-air or footsie.
--
-- When the opponent enters recovery (whiffed a hit, or simply ended up
-- vulnerable after throwing something out that didn't connect with
-- anything protecting them), Ken punishes instantly with a combo (cr.MK
-- canceled into Super Art if there's meter, or into shoryuken if not — see
-- combo_punish.lua), instead of waiting for Footsies' normal poke pacing.
-- Fires only once per recovery window (the rising edge of recovery_time),
-- not for the whole duration.

WhiffPunish = {}

local PUNISH_RANGE = 100 -- reasonable reach for a strong punish hit
local was_recovering = false

function WhiffPunish.decide(input)
  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)

  if AIUtil.is_jumping(self_state.posture) or AIUtil.is_jumping(opponent_state.posture) then
    was_recovering = false
    return false
  end

  local recovering = opponent_state.recovery_time > 0
  local just_started = recovering and not was_recovering
  was_recovering = recovering

  if not just_started then
    return false
  end

  local dist = math.abs(self_state.pos_x - opponent_state.pos_x)
  if dist > PUNISH_RANGE then
    return false
  end

  ComboPunish.start(self_state.gauge >= 1)
  return ComboPunish.decide(input)
end
