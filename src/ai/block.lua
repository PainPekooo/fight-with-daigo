-- Bloqueo reactivo, dos casos:
-- 1) Cuerpo a cuerpo: el rival tiene una hitbox de ataque activa ahora mismo
--    (Memory.has_active_attack_box) -> agacha y bloquea hacia atrás. Ya NO
--    usa distancia: antes usábamos un rango fijo (BLOCK_RANGE) que era puro
--    adivine — muy chico y los barridos conectaban sin que Ken se
--    considerara "cerca"; agrandarlo tampoco alcanzaba porque Footsies
--    caminaba a través de esa zona sin que Block llegara a mirar nada, y
--    dárselo a Block por delante hacía que Ken se quedara bloqueando para
--    siempre apenas el rival estaba cerca (aunque no atacara). Leer la
--    hitbox real resuelve las dos cosas: no depende de un número de rango,
--    y no se activa solo por estar cerca sin pelear.
-- 2) Proyectil: si hay un hadouken del rival acercándose, bloquea sin
--    importar la distancia (esto sí sigue por proximidad — no hay hitbox de
--    ataque que leer en el objeto del jugador para un proyectil).
--
-- El bloqueo de golpe activo es sin delay (el golpe ya está saliendo, no
-- hay margen para simular tiempo de reacción). El de proyectil sí tiene
-- delay aleatorio (viene de lejos, hay margen de sobra).

Block = {}

local PROJECTILE_RANGE = 180 -- distancia para reaccionar a un proyectil acercándose

local REACTION_DELAY_MIN = 2
local REACTION_DELAY_MAX = 5
local pending_delay = nil
local blocking_active = false

local function nearest_incoming_projectile(self_state)
  local nearest, nearest_dist = nil, nil

  for _, obj in ipairs(Projectiles.list()) do
    if obj.emitter_id == AIUtil.OPPONENT_ID then
      local dist = math.abs(self_state.pos_x - obj.pos_x)
      if nearest_dist == nil or dist < nearest_dist then
        nearest, nearest_dist = obj, dist
      end
    end
  end

  return nearest, nearest_dist
end

-- Chequeo sin efectos secundarios: para que el orquestador le dé prioridad
-- al bloqueo por sobre Footsies (caminar/pokear en vez de bloquear un golpe
-- real es peor que perderse un frame de ofensiva).
function Block.has_threat()
  local self_state = Memory.read_player_state(AIUtil.SELF_ID)

  if Memory.has_active_attack_box(AIUtil.OPPONENT_ID) then
    return true
  end

  local threat, dist = nearest_incoming_projectile(self_state)
  return threat ~= nil and dist <= PROJECTILE_RANGE
end

function Block.decide(input)
  local self_state = Memory.read_player_state(AIUtil.SELF_ID)
  local opponent_state = Memory.read_player_state(AIUtil.OPPONENT_ID)

  if AIUtil.is_jumping(self_state.posture) then
    pending_delay = nil
    blocking_active = false
    return false
  end

  if Memory.has_active_attack_box(AIUtil.OPPONENT_ID) and not AIUtil.is_jumping(opponent_state.posture) then
    pending_delay = nil
    blocking_active = false
    input["P2 Down"] = true
    input[AIUtil.backward_input(self_state, opponent_state)] = true
    return true
  end

  local threat, dist = nearest_incoming_projectile(self_state)
  local projectile_incoming = threat ~= nil and dist <= PROJECTILE_RANGE

  if not projectile_incoming then
    pending_delay = nil
    blocking_active = false
    return false
  end

  if not blocking_active then
    if pending_delay == nil then
      pending_delay = math.random(REACTION_DELAY_MIN, REACTION_DELAY_MAX)
    end
    if pending_delay > 0 then
      pending_delay = pending_delay - 1
      return false
    end
    blocking_active = true
  end

  local backward = (threat.pos_x >= self_state.pos_x) and "P2 Left" or "P2 Right"
  input["P2 Down"] = true
  input[backward] = true
  return true
end
