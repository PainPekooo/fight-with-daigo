-- Forward dash (66): quick double-tap of "forward". Used as an alternative
-- to walking to close distance, same as tatsumaki.lua.

Dash = {}

local SEQUENCE_FRAMES = 4 -- tap, release (so the second tap counts as fresh), tap, hold
local step = 0

function Dash.active()
  return step > 0
end

function Dash.start()
  if step == 0 then
    step = 1
  end
end

function Dash.reset()
  step = 0
end

function Dash.decide(input)
  if step == 0 then
    return false
  end

  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)
  local forward = AIUtil.forward_input(self_state, opponent_state)

  if step == 1 then
    input[forward] = true
  elseif step == 2 then
    -- deliberately released
  elseif step == 3 or step == 4 then
    input[forward] = true
  end

  step = step + 1
  if step > SEQUENCE_FRAMES then
    step = 0
  end

  return true
end
