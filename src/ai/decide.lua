-- Orquestador de IA: llama a cada regla en orden de prioridad.
-- AntiAir es exclusivo en sus frames activos (mezclar otro input rompe la
-- secuencia de shoryuken). ParryFireball también: si toca "adelante" ese
-- frame, no debe mezclarse con el "atrás" del bloqueo.
--
-- Block va antes que Footsies: si hay una amenaza real (golpe activo del
-- rival o un proyectil acercándose), bloquear siempre gana. Como Block ya
-- no depende de distancia para el caso cuerpo a cuerpo (lee si el rival
-- tiene una hitbox de ataque activa, ver block.lua), esto no reintroduce el
-- bug viejo de "Ken bloqueando todo el partido": si el rival está cerca
-- pero no atacando, Block.has_threat() da false y Footsies puede
-- caminar/pokear tranquilo.

AI = {}

-- Devuelve además una etiqueta legible de qué hizo, para mostrar en
-- pantalla sin tener que volcar el estado interno de cada regla.
function AI.decide(input)
  if AntiAir.decide(input) then return "shoryuken (anti-air)" end
  if ParryFireball.decide(input) then return "parry (hadouken)" end

  if Block.has_threat() then
    if Block.decide(input) then
      return "bloqueando"
    end
    return "reaccionando..." -- en el delay antes de bloquear un proyectil
  end

  if Footsies.decide(input) then
    return "footsies: " .. Footsies.debug_action()
  end

  if ThrowTech.decide(input) then
    return "zafando agarre"
  end

  return "neutral"
end
