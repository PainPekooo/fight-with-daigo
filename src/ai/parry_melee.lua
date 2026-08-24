-- Parry cuerpo a cuerpo, intento ocasional. Evo Moment 37 fue justamente
-- esto — un parry a un combo cuerpo a cuerpo (el Super Art de Chun-Li), no
-- a un proyectil como parry_fireball.lua. Probabilidad baja a propósito: si
-- falla, Ken se come el golpe entero sin bloquear nada, mucho peor que el
-- bloqueo normal (que es confiable). La mayoría de las veces Block.decide()
-- sigue manejando esto (ver decide.lua) — esto es un intento ocasional
-- encima, no un reemplazo.
--
-- Dirección del parry: adelante para golpes altos/medios, abajo para
-- bajos. Aproximamos "bajo" mirando si el rival está agachado (la mayoría
-- de los barridos/golpes bajos son movimientos agachados) — no es
-- perfecto, pero es razonable.

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
    return false -- esta vez que bloquee Block, no lo intentamos
  end

  if opponent_state.posture == Memory.POSTURE.CROUCHING then
    input["P2 Down"] = true
  else
    input[AIUtil.forward_input(self_state, opponent_state)] = true
  end

  return true
end
