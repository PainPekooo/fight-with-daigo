-- Projectile parry, second attempt. The first one (blindly mashing
-- "forward" based on distance) always failed — we didn't know the real
-- moment of contact, only that "it's getting close." Now that we read the
-- projectile's real hitbox (the same mechanism used for melee blocking),
-- we compute the exact frame its edge enters Ken's zone and tap "forward"
-- right there — two attempts, one frame apart, instead of mashing across
-- the whole approach.
--
-- Doesn't replace Block: if this fails, Block.decide() still acts as a
-- proximity-based fallback (see decide.lua).
--
-- Live-debugged (console logging with scrollback, same as the earlier
-- left/right block bug): the tap itself is what was pressing forward,
-- interrupting whatever backward hold Block had going — normal, documented
-- tradeoff. But this used to attempt on EVERY overlap, unconditionally
-- (unlike parry_melee.lua, which only attempts a fraction of the time and
-- lets Block cover the rest). That meant every single incoming projectile
-- carried a guaranteed one-frame guard-drop risk. Now gated the same way
-- melee is: roll once per incoming projectile, and only take the risk that
-- fraction of the time.
--
-- (Tried gating this further on Memory.can_attempt_parry -- "is Ken's own
-- parry input currently eligible" -- but live logging showed the
-- validity/cooldown `state` field cycles through 5 values (0-4), not the
-- simple 1-can/3-cannot binary effie3rd's code implied. That binary was
-- what THEY force-write for their auto-parry cheat, not necessarily what
-- the state machine does natively. Reverted rather than gate on a disproven
-- assumption -- see memory.lua.)

ParryFireball = {}

-- From the reference repo's framedata.lua (character_specific.ken.half_width).
local KEN_HALF_WIDTH = 30

-- Higher than parry_melee's (0.4): this one is timed off the real hitbox
-- overlap frame, not a guess, so it's inherently more reliable — still not
-- 100%, so a fully safe block is always available some of the time too.
local ATTEMPT_CHANCE = 0.5

local was_overlapping = false
local overlap_frames = 0
local will_attempt = false

local function overlapping_projectile(self_state)
  for _, obj in ipairs(Projectiles.list()) do
    if obj.emitter_id == AIUtil.OPPONENT_ID and obj.attack_box then
      local box_left = obj.pos_x + obj.attack_box.left
      local box_right = box_left + obj.attack_box.width
      local self_left = self_state.pos_x - KEN_HALF_WIDTH
      local self_right = self_state.pos_x + KEN_HALF_WIDTH

      if box_right >= self_left and box_left <= self_right then
        return obj
      end
    end
  end
  return nil
end

function ParryFireball.decide(input)
  local self_state = Memory.read_player_state(AIUtil.SELF_ID)

  if AIUtil.is_jumping(self_state.posture) then
    was_overlapping = false
    overlap_frames = 0
    return false
  end

  local obj = overlapping_projectile(self_state)

  if not obj then
    was_overlapping = false
    overlap_frames = 0
    return false
  end

  local just_started = not was_overlapping
  overlap_frames = was_overlapping and (overlap_frames + 1) or 0
  was_overlapping = true

  if just_started then
    will_attempt = math.random() < ATTEMPT_CHANCE
  end

  if not will_attempt then
    return false -- let Block handle this one, no guard-drop risk taken
  end

  -- Taps on frame 0 (right as the overlap starts) and on frame 2 (in case
  -- the first one landed a bit early/late) — one frame of release in
  -- between so it counts as a fresh tap, not a held input.
  if overlap_frames == 0 or overlap_frames == 2 then
    local forward = (obj.pos_x >= self_state.pos_x) and "P2 Right" or "P2 Left"
    input[forward] = true
    return true
  end

  return false
end
