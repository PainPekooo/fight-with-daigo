-- Tatsumaki Senpuu Kyaku (214+K): spinning kick that advances. Used here as
-- an alternative tool to close distance (instead of always walking).
-- Sequence: down, down-back, back+MK — "back" in the sense of the move's
-- own notation (quarter circle back), it doesn't mean it retreats: it still
-- moves toward the opponent when it comes out.

Tatsumaki = {}

local SEQUENCE_FRAMES = 3
local step = 0

-- EX (2 kicks instead of 1) when there's meter available — more hits,
-- extra invincibility. Shrunk from 0.3 to 0.1: EX and Super Art both spend
-- the same gauge (`gauge >= 1`, see whiff_punish.lua/combo_punish.lua), so
-- burning it here just to close distance was directly competing with — and
-- often emptying — the meter the whiff-punish combo needs, reported live
-- as spamming EX to approach and losing the super in the process.
local EX_CHANCE = 0.1
local use_ex = false

function Tatsumaki.active()
  return step > 0
end

function Tatsumaki.start()
  if step == 0 then
    step = 1
    local self_state = Memory.read_player_state(AIUtil.SELF_ID)
    use_ex = self_state.gauge >= 1 and math.random() < EX_CHANCE
  end
end

function Tatsumaki.reset()
  step = 0
end

-- Returns true while it's executing the sequence.
function Tatsumaki.decide(input)
  if step == 0 then
    return false
  end

  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)
  local back = AIUtil.backward_input(self_state, opponent_state)

  if step == 1 then
    input["P2 Down"] = true
  elseif step == 2 then
    input["P2 Down"] = true
    input[back] = true
  elseif step == 3 then
    input[back] = true
    if use_ex then
      input["P2 Weak Kick"] = true
      input["P2 Strong Kick"] = true
    else
      input["P2 Medium Kick"] = true
    end
  end

  step = step + 1
  if step > SEQUENCE_FRAMES then
    step = 0
  end

  return true
end
