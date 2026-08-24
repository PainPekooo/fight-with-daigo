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
-- Used to have a known limitation here: reacting only once the hitbox is
-- already active gives no lead time, so a fast enough "close" normal could
-- connect before the block registered, especially point-blank. Now
-- partially addressed with a 3rd case:
-- 3) Predictive: if the opponent's current move is one we've already timed
--    before this session (see opponent_move_timing.lua), and it's within
--    PREDICT_LEAD_FRAMES of going active, block early instead of waiting
--    for the hitbox. Only helps for moves already seen at least once —
--    the very first time any given move shows up, there's nothing to
--    predict yet and this falls back to the same reactive path as before.
--
-- Blocking an active hit (or a predicted one) has no delay (the hit is
-- already coming, or about to — there's no room to simulate reaction
-- time). Blocking a projectile does have a random delay (it's coming from
-- far away, there's plenty of margin).

Block = {}

-- How many frames before a known move's measured active frame to start
-- blocking. A starting guess, not verified live yet -- tune based on
-- whether it's still eating fast close normals it's already seen once.
local PREDICT_LEAD_FRAMES = 2

-- Widened from 180 to 220 for max difficulty ("al palo") — starts reacting
-- to a fireball earlier.
local PROJECTILE_RANGE = 220

-- Shrunk from 2-5 to 1-2, then to 0-1 for max difficulty.
local REACTION_DELAY_MIN = 0
local REACTION_DELAY_MAX = 1
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

  local predicted = OpponentMoveTiming.frames_until_active()
  if predicted ~= nil and predicted <= PREDICT_LEAD_FRAMES then
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

  local active_now = Memory.has_active_attack_box(AIUtil.OPPONENT_ID)
    and not AIUtil.is_jumping(opponent_state.posture)

  local predicted = OpponentMoveTiming.frames_until_active()
  local predicted_soon = not active_now and predicted ~= nil and predicted <= PREDICT_LEAD_FRAMES
    and not AIUtil.is_jumping(opponent_state.posture)

  if active_now or predicted_soon then
    pending_delay = nil
    blocking_active = false
    -- Only crouch for lows (same approximation as parry_melee.lua: opponent
    -- crouching ~ probably a low hit). Used to always crouch regardless of
    -- the incoming hit, which blocked fine but looked odd against clearly
    -- high/mid attacks. Works the same for the predicted case: posture is
    -- known immediately, it's only the hitbox itself we're getting ahead of.
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
