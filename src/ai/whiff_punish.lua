-- Whiff punish: a diferencia del resto del moveset (fundamentos genéricos
-- inventados por nosotros), esto sí está basado en la investigación real
-- sobre Daigo (ver README) — su fortaleza documentada es "whiff-punish over
-- reacción", no un anti-air o footsie en particular.
--
-- Cuando el rival queda en recovery (falló un golpe, o simplemente quedó
-- vulnerable después de tirar algo y no conectar con nada que lo proteja),
-- Ken lo castiga en el instante con un combo (cr.MK cancelado en Super Art
-- si hay meter, o en shoryuken si no — ver combo_punish.lua), en vez de
-- esperar el enfriamiento normal de pokes de Footsies. Dispara una sola vez
-- por ventana de recovery (el flanco de subida de recovery_time), no
-- mientras dure entera.

WhiffPunish = {}

local PUNISH_RANGE = 100 -- alcance razonable para un golpe fuerte de castigo
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
