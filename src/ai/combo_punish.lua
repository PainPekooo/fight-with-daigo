-- Combo de castigo: cr.MK cancelado en Super Art (si hay meter) o en
-- shoryuken (si no). Se dispara desde whiff_punish.lua en vez de un golpe
-- suelto.
--
-- Primer intento salió separado (bloqueable en el medio): arrancábamos el
-- motion del especial apenas se soltaba el botón de cr.MK (frame 3), pero
-- en el framedata real de Ken (data/sfiii3nr1/framedata/ken_framedata.json
-- del repo de referencia) cr.MK (move id "b0e8") recién se vuelve activa —
-- puede conectar, y ahí es cuando se puede cancelar — entre los frames 6 y
-- 10 de su animación. Ahora esperamos hasta ese punto antes de arrancar el
-- motion. Sigue siendo una estimación (no confirmamos la ventana exacta de
-- cancelación, que no es necesariamente idéntica a hit_frames) — falta
-- reconfirmar en vivo.
--
-- El motion de shoryuken de acá es una copia local, NO comparte módulo con
-- anti_air.lua a propósito: si dos llamadores reclaman el mismo módulo
-- compartido el mismo frame (ej. AntiAir se dispara mientras este combo
-- está a mitad de camino), uno le pisa el estado al otro — más simple
-- duplicar unas pocas líneas que arriesgar ese bug.

ComboPunish = {}

local STARTER_FRAMES = 2 -- sostener Down+MK
local WAIT_FRAMES = 4    -- esperar hasta ~frame 6 (cr.MK activa) antes de cancelar

local phase = "idle" -- "idle" | "starter" | "wait" | "special"
local frame_in_phase = 0
local use_super = false
local srk_step = 0

function ComboPunish.active()
  return phase ~= "idle"
end

function ComboPunish.start(super_available)
  if phase == "idle" then
    phase = "starter"
    frame_in_phase = 0
    use_super = super_available
  end
end

function ComboPunish.reset()
  phase = "idle"
  srk_step = 0
  SuperArt.reset()
end

local function decide_srk(input)
  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)
  local forward = AIUtil.forward_input(self_state, opponent_state)

  srk_step = srk_step + 1
  if srk_step == 1 then
    input[forward] = true
  elseif srk_step == 2 then
    input["P2 Down"] = true
  elseif srk_step == 3 then
    input["P2 Down"] = true
    input[forward] = true
    input["P2 Strong Punch"] = true
  end

  if srk_step >= 3 then
    srk_step = 0
    return false -- terminó
  end
  return true
end

function ComboPunish.decide(input)
  if phase == "idle" then
    return false
  end

  if phase == "starter" then
    input["P2 Down"] = true
    input["P2 Medium Kick"] = true
    frame_in_phase = frame_in_phase + 1
    if frame_in_phase >= STARTER_FRAMES then
      phase = "wait"
      frame_in_phase = 0
    end
    return true
  end

  if phase == "wait" then
    input["P2 Down"] = true -- se mantiene agachado, la postura de cr.MK
    frame_in_phase = frame_in_phase + 1
    if frame_in_phase >= WAIT_FRAMES then
      phase = "special"
      if use_super then
        SuperArt.start()
      end
    end
    return true
  end

  -- phase == "special"
  if use_super then
    local acting = SuperArt.decide(input)
    if not SuperArt.active() then
      phase = "idle"
    end
    return acting
  end

  local still_going = decide_srk(input)
  if not still_going then
    phase = "idle"
  end
  return true
end
