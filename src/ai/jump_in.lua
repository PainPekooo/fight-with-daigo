-- Offensive jump: jumps forward and throws a kick in the air. The delay
-- before throwing the hit is our own approximation (not verified against
-- real frame data) so it lands roughly at mid-jump height — we don't
-- compute the actual height.
--
-- Unlike dash.lua/tatsumaki.lua, this leaves Ken in the air for several
-- frames — footsies.lua has to let it keep acting while active even though
-- its own posture is "jumping" (the normal check for "do nothing if I'm in
-- the air" is meant for jumps we didn't cause, not this one).

JumpIn = {}

local JUMP_INPUT_FRAMES = 3   -- how many frames to hold up+forward
local ATTACK_DELAY_FRAMES = 20 -- wait before throwing the air hit

local phase = "idle" -- "idle" | "jumping" | "waiting" | "attacking"
local step = 0
local wait_frames = 0

function JumpIn.active()
  return phase ~= "idle"
end

function JumpIn.start()
  if phase == "idle" then
    phase = "jumping"
    step = 0
    wait_frames = 0
  end
end

function JumpIn.reset()
  phase = "idle"
end

function JumpIn.decide(input)
  if phase == "idle" then
    return false
  end

  if phase == "jumping" then
    local self_state = Memory.read_player_state(AIUtil.SELF_ID)
    local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)
    local forward = AIUtil.forward_input(self_state, opponent_state)

    input["P2 Up"] = true
    input[forward] = true

    step = step + 1
    if step >= JUMP_INPUT_FRAMES then
      phase = "waiting"
    end
    return true
  end

  if phase == "waiting" then
    wait_frames = wait_frames + 1
    if wait_frames >= ATTACK_DELAY_FRAMES then
      phase = "attacking"
    end
    return true
  end

  if phase == "attacking" then
    input["P2 Medium Kick"] = true
    phase = "idle"
    return true
  end

  return false
end
