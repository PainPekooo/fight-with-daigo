-- Throw tech: at grab range, mash the throw input itself (LP+LK) — this is
-- the real technique players use to tech a throw without needing to detect
-- the opponent's grab specifically. The game recognizes it as a tech
-- attempt. As a bonus, if the opponent doesn't grab, this also throws our
-- own grab whenever there's a window — alternating between a neutral throw
-- (throws them forward, same side) and a back throw (crosses them to the
-- other side of the screen) so it isn't 100% predictable on wake-up, where
-- always mashing the same throw is easy to read.
--
-- Doesn't replace blocking (Block.decide) — it's layered on top, on
-- alternating frames, so it doesn't cancel the guard with a held throw
-- input.

ThrowTech = {}

-- The first value (30) was wrong: a number picked by eye, never checked
-- against anything. The reference repo's framedata.lua lists each
-- character's half-width (Ken = 30, the rest between 25 and 45) — two
-- characters truly pressed together end up separated by the SUM of those
-- half-widths, i.e. somewhere between 50 and 75, not 30. With 30 the
-- condition almost never triggered. Still an approximation (we don't know
-- the opponent's half-width at runtime).
local THROW_RANGE = 55
local PRESS_FRAMES = 2
local RELEASE_FRAMES = 2
local CYCLE_FRAMES = PRESS_FRAMES + RELEASE_FRAMES
local BACK_THROW_CHANCE = 0.4

local frame_counter = 0
local use_back_throw = false

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

  if frame_counter == 0 then
    use_back_throw = math.random() < BACK_THROW_CHANCE
  end

  frame_counter = (frame_counter + 1) % CYCLE_FRAMES
  if frame_counter >= PRESS_FRAMES then
    return false
  end

  if use_back_throw then
    input[AIUtil.backward_input(self_state, opponent_state)] = true
  end

  input["P2 Weak Punch"] = true
  input["P2 Weak Kick"] = true
  return true
end
