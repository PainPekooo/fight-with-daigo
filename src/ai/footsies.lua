-- Footsies: la ofensiva propia de Ken. Si el rival está lejos, cierra
-- distancia (caminando, o a veces con dash/tatsumaki/salto ofensivo para
-- variar); si está en rango de poke, tira uno de varios normales al azar, y
-- a veces retrocede después en vez de quedarse plantado. Los rangos,
-- tiempos, probabilidades y la lista de opciones son parámetros nuestros
-- para ajustar a mano, no datos sacados de ninguna fuente sobre el estilo
-- de Daigo.
--
-- Prioridad más alta que Block/ThrowTech en su propia zona (ver decide.lua)
-- para que el bloqueo no le robe siempre el frame.

Footsies = {}

local POKE_RANGE_MIN = 60  -- por debajo de esto no avanza (la defensa de cerca ya cubre)
local POKE_RANGE_MAX = 100 -- por encima de esto cierra distancia
local POKE_HOLD_FRAMES = 2
local POKE_COOLDOWN_FRAMES = 30

local RETREAT_CHANCE = 0.25
local RETREAT_FRAMES_MIN = 10
local RETREAT_FRAMES_MAX = 20

-- Cada poke: nombre para el debug, y las teclas de P2 que hay que sostener.
local POKES = {
  { name = "cr.MK", keys = { "P2 Down", "P2 Medium Kick" } },
  { name = "cr.MP", keys = { "P2 Down", "P2 Medium Punch" } },
  { name = "st.MP", keys = { "P2 Medium Punch" } },
}

-- Cómo cerrar distancia, con pesos (no todas las opciones igual de seguido).
local APPROACH_OPTIONS = { "walk", "tatsu", "dash", "jump" }
local APPROACH_WEIGHTS = { walk = 0.40, tatsu = 0.20, dash = 0.25, jump = 0.15 }

local poke_hold = 0
local poke_cooldown = 0
local current_poke = nil
local approach_mode = nil -- nil | "walk" | "tatsu" | "dash" | "jump"
local retreat_frames = 0
local last_action = "quieto"

local function apply_poke(input, poke)
  for _, key in ipairs(poke.keys) do
    input[key] = true
  end
end

local function pick_approach_mode()
  local roll = math.random()
  local acc = 0
  for _, name in ipairs(APPROACH_OPTIONS) do
    acc = acc + APPROACH_WEIGHTS[name]
    if roll <= acc then
      return name
    end
  end
  return "walk"
end

local function reset_approach()
  approach_mode = nil
  Tatsumaki.reset()
  Dash.reset()
  JumpIn.reset()
end

function Footsies.decide(input)
  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)

  -- Si Ken está en el aire PORQUE nosotros mandamos un salto ofensivo,
  -- seguimos manejando ese salto (subir, esperar, pegar) aunque su postura
  -- ahora sea "saltando". Si está en el aire por cualquier otro motivo (o
  -- si es el rival el que está saltando), no hacemos nada — eso lo maneja
  -- AntiAir con prioridad más alta.
  if AIUtil.is_jumping(self_state.posture) then
    if JumpIn.active() and JumpIn.decide(input) then
      last_action = "salto ofensivo"
      return true
    end
    poke_hold = 0
    retreat_frames = 0
    reset_approach()
    last_action = "quieto"
    return false
  end

  if AIUtil.is_jumping(opponent_state.posture) then
    poke_hold = 0
    retreat_frames = 0
    reset_approach()
    last_action = "quieto"
    return false
  end

  if poke_cooldown > 0 then
    poke_cooldown = poke_cooldown - 1
  end

  if retreat_frames > 0 then
    input[AIUtil.backward_input(self_state, opponent_state)] = true
    retreat_frames = retreat_frames - 1
    last_action = "retrocediendo"
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
    end

    if approach_mode == "tatsu" then
      Tatsumaki.start()
      if Tatsumaki.decide(input) then
        last_action = "tatsumaki (acercando)"
        return true
      end
      approach_mode = "walk"
    elseif approach_mode == "dash" then
      Dash.start()
      if Dash.decide(input) then
        last_action = "dash (acercando)"
        return true
      end
      approach_mode = "walk"
    elseif approach_mode == "jump" then
      JumpIn.start()
      if JumpIn.decide(input) then
        last_action = "salto ofensivo"
        return true
      end
      approach_mode = "walk"
    end

    input[AIUtil.forward_input(self_state, opponent_state)] = true
    last_action = "acercando"
    return true
  end

  reset_approach()

  if dist >= POKE_RANGE_MIN and poke_cooldown == 0 then
    current_poke = POKES[math.random(#POKES)]
    poke_hold = POKE_HOLD_FRAMES - 1 -- este frame ya cuenta como el primero
    poke_cooldown = POKE_COOLDOWN_FRAMES
    apply_poke(input, current_poke)
    last_action = "poke (" .. current_poke.name .. ")"

    if math.random() < RETREAT_CHANCE then
      retreat_frames = math.random(RETREAT_FRAMES_MIN, RETREAT_FRAMES_MAX)
    end

    return true
  end

  last_action = "quieto"
  return false
end

function Footsies.debug_action()
  return last_action
end
