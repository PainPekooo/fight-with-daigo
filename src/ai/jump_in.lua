-- Salto ofensivo: salta hacia adelante y tira una patada en el aire. El
-- delay antes de pegar el golpe es una aproximación nuestra (no verificada
-- contra frame data real) para que caiga más o menos a media altura del
-- salto — no calculamos la altura real.
--
-- A diferencia de dash.lua/tatsumaki.lua, esto deja a Ken en el aire varios
-- frames — footsies.lua tiene que permitirle seguir actuando mientras esté
-- activo aunque su propia postura sea "saltando" (el chequeo normal de "no
-- hacer nada si estoy en el aire" es para saltos NO buscados, no para este).

JumpIn = {}

local JUMP_INPUT_FRAMES = 3   -- cuántos frames sostener arriba+adelante
local ATTACK_DELAY_FRAMES = 20 -- espera antes de tirar el golpe aéreo

local phase = "idle" -- "idle" | "jumping" | "waiting" | "attacking"
local step = 0
local wait_frames = 0

function JumpIn.active()
  return phase ~= "idle"
end

function JumpIn.start()
  if phase == "idle" then
    phase = "jumping"
    step = 0
    wait_frames = 0
  end
end

function JumpIn.reset()
  phase = "idle"
end

function JumpIn.decide(input)
  if phase == "idle" then
    return false
  end

  if phase == "jumping" then
    local self_state = Memory.read_player_state(AIUtil.SELF_ID)
    local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)
    local forward = AIUtil.forward_input(self_state, opponent_state)

    input["P2 Up"] = true
    input[forward] = true

    step = step + 1
    if step >= JUMP_INPUT_FRAMES then
      phase = "waiting"
    end
    return true
  end

  if phase == "waiting" then
    wait_frames = wait_frames + 1
    if wait_frames >= ATTACK_DELAY_FRAMES then
      phase = "attacking"
    end
    return true
  end

  if phase == "attacking" then
    input["P2 Medium Kick"] = true
    phase = "idle"
    return true
  end

  return false
end
