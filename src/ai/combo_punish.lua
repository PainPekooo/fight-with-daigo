-- Punish combo: a crouching normal canceled into Super Art (if there's
-- meter) or into shoryuken (if not). Triggered from whiff_punish.lua
-- instead of a single hit.
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
-- Second starter, cr.MP, added the same way: real Ken bread-and-butter per
-- EventHubs' guide (Ken confirms into specials from his crouching
-- medium-strength normals, not just cr.MK —
-- https://www.eventhubs.com/guides/2009/may/11/ken-street-fighter-3-third-strike-character-guide/),
-- with its own cancel window read from the same local framedata (move id
-- "aeb8", active frames 5-8, one frame earlier than cr.MK). The move id ->
-- name mapping ("b0e8" = d_MK, "aeb8" = d_MP) came from cross-referencing
-- effie3rd/3rd_training_lua's actiondata (GPL-3.0, read only for the
-- names, not copied — see reference memory); the actual frame numbers used
-- here are our own, from the already-trusted local reference data. Picked
-- randomly between the two so the punish isn't always the same starter.
--
-- The shoryuken motion here is a local copy, deliberately NOT sharing a
-- module with anti_air.lua: if two callers claim the same shared module on
-- the same frame (e.g. AntiAir triggers while this combo is halfway
-- through), one stomps the other's state — simpler to duplicate a few
-- lines than risk that bug.

ComboPunish = {}

local STARTERS = {
  { key = "P2 Medium Kick", starter_frames = 2, wait_frames = 4 }, -- cr.MK, active at frame 6 (b0e8)
  { key = "P2 Medium Punch", starter_frames = 2, wait_frames = 3 }, -- cr.MP, active at frame 5 (aeb8)
}

local phase = "idle" -- "idle" | "starter" | "wait" | "special"
local frame_in_phase = 0
local use_super = false
local srk_step = 0
local current_starter = nil

function ComboPunish.active()
  return phase ~= "idle"
end

function ComboPunish.start(super_available)
  if phase == "idle" then
    phase = "starter"
    frame_in_phase = 0
    use_super = super_available
    current_starter = STARTERS[math.random(#STARTERS)]
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
    input[current_starter.key] = true
    frame_in_phase = frame_in_phase + 1
    if frame_in_phase >= current_starter.starter_frames then
      phase = "wait"
      frame_in_phase = 0
    end
    return true
  end

  if phase == "wait" then
    input["P2 Down"] = true -- stays crouched, the starter's posture
    frame_in_phase = frame_in_phase + 1
    if frame_in_phase >= current_starter.wait_frames then
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
