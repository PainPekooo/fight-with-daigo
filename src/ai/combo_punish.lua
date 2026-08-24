-- Punish combo: cr.MK canceled into Super Art (if there's meter) or into
-- shoryuken (if not). Triggered from whiff_punish.lua instead of a single
-- hit.
--
-- The first attempt came out separated (blockable in the middle): we
-- started the special's motion right as the cr.MK button was released
-- (frame 3), but in Ken's real framedata
-- (data/sfiii3nr1/framedata/ken_framedata.json from the reference repo)
-- cr.MK (move id "b0e8") only becomes active — able to connect, and that's
-- when it can be canceled — between frames 6 and 10 of its animation. We
-- now wait until that point before starting the motion. Still an estimate
-- (we haven't confirmed the exact cancel window, which isn't necessarily
-- identical to hit_frames) — needs re-confirming live.
--
-- The shoryuken motion here is a local copy, deliberately NOT sharing a
-- module with anti_air.lua: if two callers claim the same shared module on
-- the same frame (e.g. AntiAir triggers while this combo is halfway
-- through), one stomps the other's state — simpler to duplicate a few
-- lines than risk that bug.

ComboPunish = {}

local STARTER_FRAMES = 2 -- hold Down+MK
local WAIT_FRAMES = 4    -- wait until ~frame 6 (cr.MK active) before canceling

local phase = "idle" -- "idle" | "starter" | "wait" | "special"
local frame_in_phase = 0
local use_super = false
local srk_step = 0

function ComboPunish.active()
  return phase ~= "idle"
end

function ComboPunish.start(super_available)
  if phase == "idle" then
    phase = "starter"
    frame_in_phase = 0
    use_super = super_available
  end
end

function ComboPunish.reset()
  phase = "idle"
  srk_step = 0
  SuperArt.reset()
end

local function decide_srk(input)
  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)
  local forward = AIUtil.forward_input(self_state, opponent_state)

  srk_step = srk_step + 1
  if srk_step == 1 then
    input[forward] = true
  elseif srk_step == 2 then
    input["P2 Down"] = true
  elseif srk_step == 3 then
    input["P2 Down"] = true
    input[forward] = true
    input["P2 Strong Punch"] = true
  end

  if srk_step >= 3 then
    srk_step = 0
    return false -- done
  end
  return true
end

function ComboPunish.decide(input)
  if phase == "idle" then
    return false
  end

  if phase == "starter" then
    input["P2 Down"] = true
    input["P2 Medium Kick"] = true
    frame_in_phase = frame_in_phase + 1
    if frame_in_phase >= STARTER_FRAMES then
      phase = "wait"
      frame_in_phase = 0
    end
    return true
  end

  if phase == "wait" then
    input["P2 Down"] = true -- stays crouched, cr.MK's posture
    frame_in_phase = frame_in_phase + 1
    if frame_in_phase >= WAIT_FRAMES then
      phase = "special"
      if use_super then
        SuperArt.start()
      end
    end
    return true
  end

  -- phase == "special"
  if use_super then
    local acting = SuperArt.decide(input)
    if not SuperArt.active() then
      phase = "idle"
    end
    return acting
  end

  local still_going = decide_srk(input)
  if not still_going then
    phase = "idle"
  end
  return true
end
