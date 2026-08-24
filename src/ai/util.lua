-- Helpers shared between the AI rules.

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

-- Direction key "toward the opponent" based on relative position (we don't
-- use the game's flip_x flag, whose sign we haven't verified).
function AIUtil.forward_input(self_state, opponent_state)
  if self_state.pos_x <= opponent_state.pos_x then
    return "P2 Right"
  else
    return "P2 Left"
  end
end

-- Direction key "away from the opponent" (for blocking).
function AIUtil.backward_input(self_state, opponent_state)
  if self_state.pos_x <= opponent_state.pos_x then
    return "P2 Left"
  else
    return "P2 Right"
  end
end
