-- Super Art 3 (Shippu Jinraikyaku): doble quarter-circle-forward + patada
-- (↓↘→↓↘→+K). Confirmado en EventHubs y coincide con la búsqueda —
-- distinto motion al shoryuken (623), no hay riesgo de repetir el error de
-- confundir 236 con 623 que tuvimos antes.
--
-- Se dispara desde whiff_punish.lua cuando hay barra de meter disponible.

SuperArt = {}

local SEQUENCE_FRAMES = 6
local step = 0

function SuperArt.active()
  return step > 0
end

function SuperArt.start()
  if step == 0 then
    step = 1
  end
end

function SuperArt.reset()
  step = 0
end

function SuperArt.decide(input)
  if step == 0 then
    return false
  end

  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)
  local forward = AIUtil.forward_input(self_state, opponent_state)

  if step == 1 or step == 4 then
    input["P2 Down"] = true
  elseif step == 2 or step == 5 then
    input["P2 Down"] = true
    input[forward] = true
  elseif step == 3 then
    input[forward] = true
  elseif step == 6 then
    input[forward] = true
    input["P2 Medium Kick"] = true
  end

  step = step + 1
  if step > SEQUENCE_FRAMES then
    step = 0
  end

  return true
end
