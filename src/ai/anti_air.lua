-- First AI rule: reactive anti-air.
-- If the opponent enters a jump posture at close horizontal range, Ken
-- responds with a shoryuken (623+P). The distance threshold is a parameter
-- we set by hand, not a value sourced from anything about Daigo.

AntiAir = {}

local ANTI_AIR_RANGE = 90 -- horizontal distance (in pos_x units) to react

-- Shoryuken sequence (623+P): forward, down, down-forward+HP.
-- (The first attempt had the order reversed — 236 is hadouken, not
-- shoryuken; that's why a fireball came out instead of a dragon punch.)
local SRK_SEQUENCE_FRAMES = 3
local srk_step = 0

-- Cooldown after throwing the shoryuken: without this, if the opponent's
-- jump is still in range when the 3-frame sequence ends, it retriggers
-- immediately and can throw out several shoryukens in a row for a single
-- jump, even while Ken is still in the previous one's animation. The value
-- is our own estimate (not verified framedata) to cover execution +
-- recovery of the move.
local COOLDOWN_FRAMES = 45
local cooldown = 0

-- Random delay before starting the sequence, so it doesn't always react on
-- the exact frame the opponent jumps (looks robotic). Not a verified human
-- reaction-time figure, just a reasonable range so variation shows without
-- losing the anti-air entirely. Shrunk from 2-6 to 1-3 on request (wanted
-- more difficulty) — still some variation, but tighter.
local REACTION_DELAY_MIN = 1
local REACTION_DELAY_MAX = 3
local pending_delay = nil

-- Variety: not always HP (the flashiest/strongest, with the most hits).
-- LP and MP are also a valid shoryuken, only the button changes.
local PUNCH_OPTIONS = { "P2 Weak Punch", "P2 Medium Punch", "P2 Strong Punch" }
local current_punch = nil

-- More important variety: not always shoryuken. A repeated DP is always
-- 100% predictable (can be air-parried with certainty, knowing it's
-- coming) and risky if it whiffs (long recovery, whiff punishable).
-- Sometimes we use a normal anti-air (st.HP) instead of the special —
-- safer, less flashy, but breaks the pattern. Ties into the research on
-- the "Ume-Shoryu": a calculated gamble, not a guaranteed reflex.
local SRK_CHANCE = 0.6

-- EX shoryuken (2 punches instead of 1) when there's meter available —
-- more damage and extra invincibility. Not always, so we don't burn meter
-- on every jump.
local EX_CHANCE = 0.3

-- Returns true if it took the frame (the orchestrator must not let another
-- AI rule override this input).
function AntiAir.decide(input)
  if cooldown > 0 then
    cooldown = cooldown - 1
    return false
  end

  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)

  if srk_step == 0 then
    local in_range = math.abs(self_state.pos_x - opponent_state.pos_x) <= ANTI_AIR_RANGE
    local triggered = AIUtil.is_jumping(opponent_state.posture) and in_range

    if not triggered then
      pending_delay = nil
      return false
    end

    if pending_delay == nil then
      pending_delay = math.random(REACTION_DELAY_MIN, REACTION_DELAY_MAX)
    end

    if pending_delay > 0 then
      pending_delay = pending_delay - 1
      return false
    end

    pending_delay = nil

    if math.random() >= SRK_CHANCE then
      -- normal anti-air instead of shoryuken: a single HP frame is enough,
      -- no motion sequence needed.
      input["P2 Strong Punch"] = true
      cooldown = COOLDOWN_FRAMES
      return true
    end

    srk_step = 1
    if self_state.gauge >= 1 and math.random() < EX_CHANCE then
      current_punch = "EX"
    else
      current_punch = PUNCH_OPTIONS[math.random(#PUNCH_OPTIONS)]
    end
  end

  local forward = AIUtil.forward_input(self_state, opponent_state)

  if srk_step == 1 then
    input[forward] = true
  elseif srk_step == 2 then
    input["P2 Down"] = true
  elseif srk_step == 3 then
    input["P2 Down"] = true
    input[forward] = true
    if current_punch == "EX" then
      input["P2 Weak Punch"] = true
      input["P2 Strong Punch"] = true
    else
      input[current_punch] = true
    end
  end

  srk_step = srk_step + 1
  if srk_step > SRK_SEQUENCE_FRAMES then
    srk_step = 0
    cooldown = COOLDOWN_FRAMES
  end

  return true
end

function AntiAir.debug_step()
  return srk_step
end
