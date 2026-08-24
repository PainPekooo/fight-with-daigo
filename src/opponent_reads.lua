-- Lightweight opponent profiling ("reads"), as opposed to a game-tree/
-- minimax search. A real decision tree needs to simulate the opponent's
-- future moves, which isn't possible live against an unknown human (their
-- next input is unknowable until they press it, and we have no rewind/
-- save-state the way TAS tools do). What we CAN do is what a human player
-- does: notice a habit after a few repeats and start countering it harder.
--
-- Each tendency below is a simple saturating counter, persisted for the
-- whole session (not reset per round/match) so the bot keeps "remembering"
-- the same opponent across a long set, the way a person would. A handful
-- of observations is enough to act on — we're modeling a hunch, not
-- waiting for statistical significance.

OpponentReads = {}

-- --- Jump-happy: jumps in close (anti-air range) a lot -> counter harder.
-- Kept in sync by hand with anti_air.lua's ANTI_AIR_RANGE; doesn't need to
-- be exact, just "close enough to be a real anti-air situation."
local JUMP_READ_RANGE = 110
local JUMP_SATURATION = 4
local close_jump_count = 0
local was_jumping = false

-- --- Zoner: throws a lot of projectiles -> close the gap more aggressively.
local PROJECTILE_SATURATION = 4
local projectile_count = 0
local seen_projectile_bases = {}

function OpponentReads.update()
  if not Memory.is_round_active() then
    return
  end

  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)

  local jumping = AIUtil.is_jumping(opponent_state.posture)
  if jumping and not was_jumping then
    local dist = math.abs(self_state.pos_x - opponent_state.pos_x)
    if dist <= JUMP_READ_RANGE then
      close_jump_count = math.min(close_jump_count + 1, JUMP_SATURATION)
    end
  end
  was_jumping = jumping

  -- Edge-detect "new" projectiles by object slot address: a projectile
  -- keeps the same base address for its whole lifetime, so anything not in
  -- last frame's set just spawned this frame.
  local live_bases = {}
  for _, obj in ipairs(Projectiles.list()) do
    if obj.emitter_id == AIUtil.OPPONENT_ID then
      live_bases[obj.base] = true
      if not seen_projectile_bases[obj.base] then
        projectile_count = math.min(projectile_count + 1, PROJECTILE_SATURATION)
      end
    end
  end
  seen_projectile_bases = live_bases
end

-- 0..1: how confident we are that this opponent jumps in a lot.
function OpponentReads.jump_happy()
  return close_jump_count / JUMP_SATURATION
end

-- 0..1: how confident we are that this opponent zones with projectiles.
function OpponentReads.zoner()
  return projectile_count / PROJECTILE_SATURATION
end
