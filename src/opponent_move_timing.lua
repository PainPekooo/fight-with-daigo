-- Live-learned move startup timing, used for predictive blocking.
--
-- The documented block limitation (see block.lua) is that reacting only
-- once a hit is already active gives zero lead time -- fast "close"
-- normals can connect before the block registers. Fixing that for real
-- needs knowing a move's startup (time from the move beginning to its
-- hitbox going active) ahead of time. Rather than hand-transcribing
-- framedata for the whole cast (a huge effort, and it'd mean leaning on
-- someone else's GPL-licensed compiled data -- see CHANGELOG), the bot
-- measures it live: the first time it sees a given (character,
-- action_state) start, it has no idea how long the startup is, so Block
-- stays purely reactive for it. But it times how long that state took to
-- produce an active attack box, remembers it, and the next time it sees
-- the SAME move from the SAME character, it knows roughly when the hit is
-- coming and can start blocking a couple of frames early.
--
-- `action_state` is assumed to hold constant for a whole move's animation
-- (startup + active + recovery), based on how the reference project
-- (effie3rd/3rd_training_lua, GPL-3.0 -- consulted only to understand the
-- shape of the data, not copied) describes framedata as one animation per
-- state. Re-measured every time the same state recurs (overwriting the
-- previous value), so a one-off noisy reading (e.g. hitstop from an
-- unrelated hit landing mid-startup) self-corrects on the next repeat
-- instead of being stuck forever.

OpponentMoveTiming = {}

local known_startup = {} -- "charname|action_state" -> frames observed from state-start to active box

local current_state = nil
local state_start_frame = nil
local resolved_this_state = false

local function key(char_name, action_state)
  return char_name .. "|" .. tostring(action_state)
end

function OpponentMoveTiming.update()
  if not Memory.is_round_active() then
    current_state = nil
    return
  end

  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)
  local frame = Memory.frame_number()

  if opponent_state.action_state ~= current_state then
    current_state = opponent_state.action_state
    state_start_frame = frame
    resolved_this_state = false
  end

  if not resolved_this_state and Memory.has_active_attack_box(AIUtil.OPPONENT_ID) then
    known_startup[key(opponent_state.char_name, current_state)] = frame - state_start_frame
    resolved_this_state = true
  end
end

-- Frames until the opponent's CURRENT move is expected to go active, based
-- on a startup we've already measured for this exact (character,
-- action_state) earlier in the session. Nil if we don't recognize this
-- move yet (first time seeing it) or it's already active (reactive
-- blocking handles that case, see block.lua).
function OpponentMoveTiming.frames_until_active()
  if current_state == nil or resolved_this_state then
    return nil
  end

  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)
  local startup = known_startup[key(opponent_state.char_name, current_state)]
  if startup == nil then
    return nil
  end

  local remaining = startup - (Memory.frame_number() - state_start_frame)
  if remaining < 0 then
    return nil
  end
  return remaining
end
