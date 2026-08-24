-- Zafar de agarres: a distancia de agarre, machaca el propio input de
-- agarre (LP+LK) — es la técnica real que usan los jugadores para tech-ear
-- un throw sin necesitar detectar el agarre del rival específicamente. El
-- juego lo reconoce como intento de zafarse. De paso, si el rival no agarra,
-- esto también tira su propio agarre cuando hay ventana.
--
-- No reemplaza el bloqueo (Block.decide) — se aplica encima, en frames
-- alternados, para no cancelar el guard con el input de agarre sostenido.

ThrowTech = {}

-- El primer valor (30) estaba mal: era un número puesto a ojo, sin chequear
-- contra nada. En framedata.lua del repo de referencia figura el medio-ancho
-- de cada personaje (Ken = 30, el resto entre 25 y 45) — dos personajes
-- pegados de verdad quedan separados por la SUMA de esos medio-anchos, o
-- sea entre 50 y 75, no 30. Con 30 la condición casi nunca se cumplía.
-- Sigue siendo aproximado (no sabemos el medio-ancho del rival en runtime).
local THROW_RANGE = 55
local PRESS_FRAMES = 2
local RELEASE_FRAMES = 2
local CYCLE_FRAMES = PRESS_FRAMES + RELEASE_FRAMES
local frame_counter = 0

function ThrowTech.decide(input)
  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)

  if AIUtil.is_jumping(self_state.posture) or AIUtil.is_jumping(opponent_state.posture) then
    frame_counter = 0
    return false
  end

  local in_range = math.abs(self_state.pos_x - opponent_state.pos_x) <= THROW_RANGE
  if not in_range then
    frame_counter = 0
    return false
  end

  frame_counter = (frame_counter + 1) % CYCLE_FRAMES
  if frame_counter >= PRESS_FRAMES then
    return false
  end

  input["P2 Weak Punch"] = true
  input["P2 Weak Kick"] = true
  return true
end
