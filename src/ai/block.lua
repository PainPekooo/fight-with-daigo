-- Reactive blocking, two cases:
-- 1) Melee: the opponent has an active attack hitbox right now
--    (Memory.has_active_attack_box) -> block backward, crouching only if
--    the opponent is crouching too (approximating a low hit — same trick
--    as parry_melee.lua). No longer uses distance: we used to use a fixed
--    range (BLOCK_RANGE) that was pure guesswork — too small and sweeps
--    connected without Ken considering himself "close"; widening it wasn't
--    enough either because Footsies would walk straight through that zone
--    without Block ever getting a look, and giving Block priority instead
--    made Ken stand there blocking forever as soon as the opponent was
--    close (even if not attacking). Reading the real hitbox solves both
--    problems: it doesn't depend on a range number, and it doesn't trigger
--    just from being close without actually fighting.
-- 2) Projectile: if there's an opponent hadouken incoming, block standing
--    (no need to crouch for a mid-height fireball) regardless of distance
--    (this one still goes by proximity — there's no attack hitbox to read
--    on a projectile object).
--
-- Known limitation: reacting only once the hitbox is already active means
-- there's no lead time at all — a fast enough move (in particular, "close"
-- normals in this game tend to have quicker startup than their "far"
-- counterparts) can still connect before the block registers, especially
-- at point-blank range. Fixing this for real would mean predicting the
-- block from the opponent's move startup instead of reacting to the active
-- hitbox, which needs frame data for the whole cast, not just Ken — out of
-- scope for now.
--
-- Blocking an active hit has no delay (the hit is already coming out,
-- there's no room to simulate reaction time). Blocking a projectile does
-- have a random delay (it's coming from far away, there's plenty of
-- margin).

Block = {}

local PROJECTILE_RANGE = 180 -- distance to react to an incoming projectile

-- Shrunk from 2-5 to 1-2 on request (wanted more difficulty).
local REACTION_DELAY_MIN = 1
local REACTION_DELAY_MAX = 2
local pending_delay = nil
local blocking_active = false

local function nearest_incoming_projectile(self_state)
  local nearest, nearest_dist = nil, nil

  for _, obj in ipairs(Projectiles.list()) do
    if obj.emitter_id == AIUtil.OPPONENT_ID then
      local dist = math.abs(self_state.pos_x - obj.pos_x)
      if nearest_dist == nil or dist < nearest_dist then
        nearest, nearest_dist = obj, dist
      end
    end
  end

  return nearest, nearest_dist
end

-- Side-effect-free check: so the orchestrator can give blocking priority
-- over Footsies (walking/poking instead of blocking a real hit is worse
-- than missing a frame of offense).
function Block.has_threat()
  local self_state = Memory.read_player_state(AIUtil.SELF_ID)

  if Memory.has_active_attack_box(AIUtil.OPPONENT_ID) then
    return true
  end

  local threat, dist = nearest_incoming_projectile(self_state)
  return threat ~= nil and dist <= PROJECTILE_RANGE
end

function Block.decide(input)
  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)

  if AIUtil.is_jumping(self_state.posture) then
    pending_delay = nil
    blocking_active = false
    return false
  end

  if Memory.has_active_attack_box(AIUtil.OPPONENT_ID) and not AIUtil.is_jumping(opponent_state.posture) then
    pending_delay = nil
    blocking_active = false
    -- Only crouch for lows (same approximation as parry_melee.lua: opponent
    -- crouching ~ probably a low hit). Used to always crouch regardless of
    -- the incoming hit, which blocked fine but looked odd against clearly
    -- high/mid attacks.
    if opponent_state.posture == Memory.POSTURE.CROUCHING then
      input["P2 Down"] = true
    end
    input[AIUtil.backward_input(self_state, opponent_state)] = true
    return true
  end

  local threat, dist = nearest_incoming_projectile(self_state)
  local projectile_incoming = threat ~= nil and dist <= PROJECTILE_RANGE

  if not projectile_incoming then
    pending_delay = nil
    blocking_active = false
    return false
  end

  if not blocking_active then
    if pending_delay == nil then
      pending_delay = math.random(REACTION_DELAY_MIN, REACTION_DELAY_MAX)
    end
    if pending_delay > 0 then
      pending_delay = pending_delay - 1
      return false
    end
    blocking_active = true
  end

  -- Standing block, not crouching: fireballs are mid-height, no need to
  -- crouch for them (was crouching for every projectile before, which
  -- blocked fine but looked odd).
  local backward = (threat.pos_x >= self_state.pos_x) and "P2 Left" or "P2 Right"
  input[backward] = true
  return true
end
