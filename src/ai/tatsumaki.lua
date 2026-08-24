-- Tatsumaki Senpuu Kyaku (214+K): patada giratoria que avanza. Se usa acá
-- como herramienta alternativa para cerrar distancia (en vez de caminar
-- siempre). Secuencia: abajo, abajo-atrás, atrás+MK — "atrás" en el sentido
-- de la notación del movimiento (quarter circle back), no significa que
-- retroceda: igual avanza hacia el rival al ejecutarse.

Tatsumaki = {}

local SEQUENCE_FRAMES = 3
local step = 0

function Tatsumaki.active()
  return step > 0
end

function Tatsumaki.start()
  if step == 0 then
    step = 1
  end
end

function Tatsumaki.reset()
  step = 0
end

-- Devuelve true mientras está ejecutando la secuencia.
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
    input["P2 Medium Kick"] = true
  end

  step = step + 1
  if step > SEQUENCE_FRAMES then
    step = 0
  end

  return true
end
