-- Tatsumaki Senpuu Kyaku (214+K): patada giratoria que avanza. Se usa acá
-- como herramienta alternativa para cerrar distancia (en vez de caminar
-- siempre). Secuencia: abajo, abajo-atrás, atrás+MK — "atrás" en el sentido
-- de la notación del movimiento (quarter circle back), no significa que
-- retroceda: igual avanza hacia el rival al ejecutarse.

Tatsumaki = {}

local SEQUENCE_FRAMES = 3
local step = 0

-- EX (2 patadas en vez de 1) cuando hay barra de meter — más golpes,
-- invencibilidad extra. No siempre, para no gastar meter en cualquier
-- acercamiento.
local EX_CHANCE = 0.3
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
