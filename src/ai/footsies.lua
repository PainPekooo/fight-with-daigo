-- Footsies: Ken's own offense. If the opponent is far, close the distance
-- (walking, or sometimes with dash/tatsumaki/offensive jump for variety);
-- if they're in poke range, throw one of several normals at random, and
-- sometimes step back afterward instead of staying put. The ranges,
-- timings, probabilities, and option list are parameters we set by hand,
-- not data sourced from anything about Daigo's style.
--
-- Higher priority than Block/ThrowTech in its own zone (see decide.lua) so
-- blocking doesn't always steal the frame.

Footsies = {}

local POKE_RANGE_MIN = 60  -- below this it doesn't advance (close-range defense already covers it)
local POKE_RANGE_MAX = 100 -- above this it closes the distance
local POKE_HOLD_FRAMES = 2
-- Shrunk from 30 to 18 for max difficulty ("al palo") -- pokes come out
-- noticeably more often.
local POKE_COOLDOWN_FRAMES = 18

-- Shrunk from 0.25 to 0.12 for max difficulty -- backs off less, stays on
-- the offensive more.
local RETREAT_CHANCE = 0.12
local RETREAT_FRAMES_MIN = 10
local RETREAT_FRAMES_MAX = 20

-- Each poke: a name for debugging, and the P2 keys to hold.
local POKES = {
  { name = "cr.MK", keys = { "P2 Down", "P2 Medium Kick" } },
  { name = "cr.MP", keys = { "P2 Down", "P2 Medium Punch" } },
  { name = "st.MP", keys = { "P2 Medium Punch" } },
}

-- How to close the distance, with weights (not every option equally
-- often). "retreat" is the exception: instead of closing in, it backs off
-- for a stretch — so the approach isn't always a straight line forward.
-- Reweighted for max difficulty ("al palo"): less walk/retreat, more
-- dash/tatsu closing the gap fast. ANTI_ZONE is the "read": the more this
-- opponent throws projectiles OR just plays keep-away on foot (see
-- opponent_reads.lua's zoner/turtle -- whichever reads higher), the more
-- the mix shifts from BASE toward ANTI_ZONE -- rushing down a runaway
-- opponent instead of closing at the same pace as against anyone else.
-- Both tables sum to 1.0 so the blend between them does too.
local APPROACH_OPTIONS = { "walk", "tatsu", "dash", "jump", "retreat" }
local APPROACH_WEIGHTS_BASE = { walk = 0.25, tatsu = 0.20, dash = 0.30, jump = 0.15, retreat = 0.10 }
local APPROACH_WEIGHTS_ANTI_ZONE = { walk = 0.10, tatsu = 0.30, dash = 0.45, jump = 0.10, retreat = 0.05 }

local RETREAT_APPROACH_FRAMES_MIN = 15
local RETREAT_APPROACH_FRAMES_MAX = 30
local retreat_approach_frames = 0

local poke_hold = 0
local poke_cooldown = 0
local current_poke = nil
local approach_mode = nil -- nil | "walk" | "tatsu" | "dash" | "jump" | "retreat"
local last_approach_mode = nil
local retreat_frames = 0
local last_action = "idle"

local function apply_poke(input, poke)
  for _, key in ipairs(poke.keys) do
    input[key] = true
  end
end

-- Discounts whatever approach mode was picked last time, so a long
-- retreat/chase (many independent picks in a row) doesn't keep landing on
-- the same one -- live-tested and reported as Ken visibly spamming
-- tatsumaki over and over while chasing a retreating opponent. Doesn't
-- forbid an immediate repeat outright (still occasionally happens, 15% of
-- its normal weight), just makes it uncommon instead of "as likely as
-- anything else every single time."
local REPEAT_DISCOUNT = 0.15

local function pick_approach_mode()
  local anti_zone_read = math.max(OpponentReads.zoner(), OpponentReads.turtle())
  local roll = math.random()
  local acc = 0
  for _, name in ipairs(APPROACH_OPTIONS) do
    local base, anti_zone = APPROACH_WEIGHTS_BASE[name], APPROACH_WEIGHTS_ANTI_ZONE[name]
    local weight = base + (anti_zone - base) * anti_zone_read
    if name == last_approach_mode then
      weight = weight * REPEAT_DISCOUNT
    end
    acc = acc + weight
    if roll <= acc then
      last_approach_mode = name
      return name
    end
  end
  last_approach_mode = "walk"
  return "walk"
end

local function reset_approach()
  approach_mode = nil
  retreat_approach_frames = 0
  Tatsumaki.reset()
  Dash.reset()
  JumpIn.reset()
end

function Footsies.decide(input)
  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)

  -- If Ken is airborne BECAUSE we sent an offensive jump or a tatsumaki
  -- (which briefly leaves the ground), we keep handling that sequence even
  -- though his posture now reads as "jumping" — otherwise the check below
  -- cuts it off halfway through (this genuinely happened: the tatsumaki
  -- would abort on the first frame and look stuck/repeating instead of
  -- completing the move). If he's airborne for any other reason (or if
  -- it's the opponent who's jumping), we do nothing — that's handled by
  -- AntiAir at higher priority.
  if AIUtil.is_jumping(self_state.posture) then
    if JumpIn.active() and JumpIn.decide(input) then
      last_action = "offensive jump"
      return true
    end
    if Tatsumaki.active() and Tatsumaki.decide(input) then
      last_action = "tatsumaki (closing in)"
      return true
    end
    poke_hold = 0
    retreat_frames = 0
    reset_approach()
    last_action = "idle"
    return false
  end

  if AIUtil.is_jumping(opponent_state.posture) then
    poke_hold = 0
    retreat_frames = 0
    reset_approach()
    last_action = "idle"
    return false
  end

  if poke_cooldown > 0 then
    poke_cooldown = poke_cooldown - 1
  end

  if retreat_frames > 0 then
    input[AIUtil.backward_input(self_state, opponent_state)] = true
    retreat_frames = retreat_frames - 1
    last_action = "retreating"
    return true
  end

  if poke_hold > 0 then
    apply_poke(input, current_poke)
    poke_hold = poke_hold - 1
    last_action = "poke (" .. current_poke.name .. ")"
    return true
  end

  local dist = math.abs(self_state.pos_x - opponent_state.pos_x)

  if dist > POKE_RANGE_MAX then
    if approach_mode == nil then
      approach_mode = pick_approach_mode()
      if approach_mode == "retreat" then
        retreat_approach_frames = math.random(RETREAT_APPROACH_FRAMES_MIN, RETREAT_APPROACH_FRAMES_MAX)
      end
    end

    if approach_mode == "retreat" then
      if retreat_approach_frames > 0 then
        input[AIUtil.backward_input(self_state, opponent_state)] = true
        retreat_approach_frames = retreat_approach_frames - 1
        last_action = "holding distance"
        return true
      end
      approach_mode = nil -- stretch is over, next frame decides again
      last_action = "holding distance"
      return true
    end

    if approach_mode == "tatsu" then
      Tatsumaki.start()
      if Tatsumaki.decide(input) then
        last_action = "tatsumaki (closing in)"
        return true
      end
      approach_mode = "walk"
    elseif approach_mode == "dash" then
      Dash.start()
      if Dash.decide(input) then
        last_action = "dash (closing in)"
        return true
      end
      approach_mode = "walk"
    elseif approach_mode == "jump" then
      JumpIn.start()
      if JumpIn.decide(input) then
        last_action = "offensive jump"
        return true
      end
      approach_mode = "walk"
    end

    input[AIUtil.forward_input(self_state, opponent_state)] = true
    last_action = "closing in"
    return true
  end

  reset_approach()

  if dist >= POKE_RANGE_MIN and poke_cooldown == 0 then
    current_poke = POKES[math.random(#POKES)]
    poke_hold = POKE_HOLD_FRAMES - 1 -- this frame already counts as the first one
    poke_cooldown = POKE_COOLDOWN_FRAMES
    apply_poke(input, current_poke)
    last_action = "poke (" .. current_poke.name .. ")"

    if math.random() < RETREAT_CHANCE then
      retreat_frames = math.random(RETREAT_FRAMES_MIN, RETREAT_FRAMES_MAX)
    end

    return true
  end

  last_action = "idle"
  return false
end

function Footsies.debug_action()
  return last_action
end
