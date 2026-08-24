-- Helpers compartidos entre las reglas de IA.

AIUtil = {}

AIUtil.SELF_ID = 2
AIUtil.OPPONENT_ID = 1

AIUtil.JUMP_POSTURES = {
  [Memory.POSTURE.NEUTRAL_JUMP] = true,
  [Memory.POSTURE.JUMP_FORWARD] = true,
  [Memory.POSTURE.JUMP_BACKWARD] = true,
  [Memory.POSTURE.HIGH_JUMP] = true,
}

function AIUtil.is_jumping(posture)
  return AIUtil.JUMP_POSTURES[posture] == true
end

-- Tecla de dirección "hacia el rival" según posición relativa (no usamos el
-- flag flip_x del juego, cuyo signo no tenemos verificado).
function AIUtil.forward_input(self_state, opponent_state)
  if self_state.pos_x <= opponent_state.pos_x then
    return "P2 Right"
  else
    return "P2 Left"
  end
end

-- Tecla de dirección "alejándose del rival" (para bloquear).
function AIUtil.backward_input(self_state, opponent_state)
  if self_state.pos_x <= opponent_state.pos_x then
    return "P2 Left"
  else
    return "P2 Right"
  end
end
