-- Primera regla de IA: anti-air reactivo.
-- Si el rival entra en postura de salto y está a corta distancia horizontal,
-- Ken responde con un shoryuken (623+P). El umbral de distancia es un
-- parámetro nuestro para ajustar a mano, no un dato sacado de ninguna
-- fuente sobre Daigo.

AntiAir = {}

local ANTI_AIR_RANGE = 90 -- distancia horizontal (en unidades de pos_x) para reaccionar

-- Secuencia de shoryuken (623+P): adelante, abajo, abajo-adelante+HP.
-- (El primer intento tenía el orden invertido — 236 es hadouken, no
-- shoryuken; de ahí que saliera fireball en vez de dragon punch.)
local SRK_SEQUENCE_FRAMES = 3
local srk_step = 0

-- Enfriamiento después de tirar el shoryuken: sin esto, si el salto del
-- rival sigue en rango cuando termina la secuencia de 3 frames, se
-- retrigger inmediatamente y puede tirar varios shoryukens seguidos por un
-- solo salto, incluso mientras Ken sigue en animación del anterior. El
-- valor es una estimación nuestra (no un dato de framedata verificado) para
-- cubrir ejecución + recovery del movimiento.
local COOLDOWN_FRAMES = 45
local cooldown = 0

-- Delay aleatorio antes de arrancar la secuencia, para que no reaccione
-- siempre en el frame exacto en que el rival salta (se ve robótico). No es
-- un dato de tiempo de reacción humano verificado, es un rango razonable
-- para que se note variación sin perder el anti-air por completo.
local REACTION_DELAY_MIN = 2
local REACTION_DELAY_MAX = 6
local pending_delay = nil

-- Variedad: no siempre HP (el más vistoso/fuerte, con más golpes de
-- efecto). LP y MP también son shoryuken válido, solo cambia el botón.
local PUNCH_OPTIONS = { "P2 Weak Punch", "P2 Medium Punch", "P2 Strong Punch" }
local current_punch = nil

-- Variedad más importante: no siempre shoryuken. Un DP repetido siempre es
-- 100% predecible (se puede air-parry con certeza sabiendo que va a salir)
-- y arriesgado si falla (recovery largo, whiff punishable). A veces usamos
-- un anti-air normal (st.HP) en vez del especial — más seguro, menos
-- vistoso, pero rompe el patrón. Conecta con lo investigado sobre el
-- "Ume-Shoryu": una apuesta calculada, no un reflejo garantizado.
local SRK_CHANCE = 0.6

-- EX shoryuken (2 puños en vez de 1) cuando hay barra de meter — más daño e
-- invencibilidad extra. No siempre, para no gastar meter en cualquier salto.
local EX_CHANCE = 0.3

-- Devuelve true si tomó el frame (el orquestador no debe dejar que otra
-- regla de IA pise este input).
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
      -- anti-air normal en vez de shoryuken: un solo frame de HP alcanza,
      -- no hace falta secuencia de motion.
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
