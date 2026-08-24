-- Wake-up mixup: when the opponent is knocked down and Ken is standing
-- over them, don't always go for the same throw attempt — mashing the same
-- grab input the whole time telegraphs exactly what's coming (tech it or
-- jump out). Randomize between a throw attempt and a meaty poke (cr.MK,
-- re-attempted periodically since we don't compute the exact wake-up
-- frame) instead.
--
-- Takes priority over ThrowTech/Footsies for the whole knockdown window
-- (claims the frame continuously, holding position with no input during
-- the gaps between attempts) so they don't also try to act and mix in.

WakeupMixup = {}

local RANGE = 55 -- same ballpark as throw range
local THROW_CHANCE = 0.5 -- vs. meaty poke

local PRESS_FRAMES = 2
local RELEASE_FRAMES = 2
local CYCLE_FRAMES = PRESS_FRAMES + RELEASE_FRAMES

local POKE_HOLD_FRAMES = 2
local POKE_COOLDOWN_FRAMES = 25

local was_active = false
local choice = nil -- "throw" | "poke"
local frame_counter = 0
local poke_hold = 0
local poke_cooldown = 0

function WakeupMixup.decide(input)
  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)

  local knocked_down = opponent_state.posture == Memory.POSTURE.KNOCKED_DOWN
  local in_range = math.abs(self_state.pos_x - opponent_state.pos_x) <= RANGE
  local active = knocked_down and in_range

  if not active then
    was_active = false
    choice = nil
    frame_counter = 0
    poke_hold = 0
    poke_cooldown = 0
    return false
  end

  if not was_active then
    choice = (math.random() < THROW_CHANCE) and "throw" or "poke"
  end
  was_active = true

  if choice == "poke" then
    if poke_hold > 0 then
      input["P2 Down"] = true
      input["P2 Medium Kick"] = true
      poke_hold = poke_hold - 1
    elseif poke_cooldown > 0 then
      poke_cooldown = poke_cooldown - 1
    else
      poke_hold = POKE_HOLD_FRAMES - 1
      poke_cooldown = POKE_COOLDOWN_FRAMES
      input["P2 Down"] = true
      input["P2 Medium Kick"] = true
    end
    return true
  end

  -- choice == "throw": mash like throw_tech.lua
  frame_counter = (frame_counter + 1) % CYCLE_FRAMES
  if frame_counter < PRESS_FRAMES then
    input["P2 Weak Punch"] = true
    input["P2 Weak Kick"] = true
  end
  return true
end
