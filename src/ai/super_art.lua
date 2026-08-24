-- Super Art 3 (Shippu Jinraikyaku): double quarter-circle-forward + kick
-- (↓↘→↓↘→+K). Confirmed on EventHubs and matches the search results —
-- a different motion family from the shoryuken (623), so there's no risk
-- of repeating the earlier mistake of confusing 236 with 623.
--
-- Triggered from whiff_punish.lua when there's meter available.

SuperArt = {}

local SEQUENCE_FRAMES = 6
local step = 0

function SuperArt.active()
  return step > 0
end

function SuperArt.start()
  if step == 0 then
    step = 1
  end
end

function SuperArt.reset()
  step = 0
end

function SuperArt.decide(input)
  if step == 0 then
    return false
  end

  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)
  local forward = AIUtil.forward_input(self_state, opponent_state)

  if step == 1 or step == 4 then
    input["P2 Down"] = true
  elseif step == 2 or step == 5 then
    input["P2 Down"] = true
    input[forward] = true
  elseif step == 3 then
    input[forward] = true
  elseif step == 6 then
    input[forward] = true
    input["P2 Medium Kick"] = true
  end

  step = step + 1
  if step > SEQUENCE_FRAMES then
    step = 0
  end

  return true
end
