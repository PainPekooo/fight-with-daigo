-- Parry de proyectiles, segundo intento. El primero (mash de "adelante" a
-- ciegas según distancia) fallaba siempre — no sabíamos el momento real de
-- contacto, solo que "venía cerca". Ahora que leemos la hitbox real del
-- proyectil (mismo mecanismo que usamos para el bloqueo cuerpo a cuerpo),
-- calculamos el frame exacto en que su borde entra en la zona de Ken y
-- tanteamos "adelante" ahí — dos intentos, con un frame de margen, en vez
-- de mashear a lo largo de toda la aproximación.
--
-- No reemplaza a Block: si esto falla, Block.decide() sigue actuando como
-- red de respaldo por proximidad (ver decide.lua).

ParryFireball = {}

-- De framedata.lua del repo de referencia (character_specific.ken.half_width).
local KEN_HALF_WIDTH = 30

local was_overlapping = false
local overlap_frames = 0

local function overlapping_projectile(self_state)
  for _, obj in ipairs(Projectiles.list()) do
    if obj.emitter_id == AIUtil.OPPONENT_ID and obj.attack_box then
      local box_left = obj.pos_x + obj.attack_box.left
      local box_right = box_left + obj.attack_box.width
      local self_left = self_state.pos_x - KEN_HALF_WIDTH
      local self_right = self_state.pos_x + KEN_HALF_WIDTH

      if box_right >= self_left and box_left <= self_right then
        return obj
      end
    end
  end
  return nil
end

function ParryFireball.decide(input)
  local self_state = Memory.read_player_state(AIUtil.SELF_ID)

  if AIUtil.is_jumping(self_state.posture) then
    was_overlapping = false
    overlap_frames = 0
    return false
  end

  local obj = overlapping_projectile(self_state)

  if not obj then
    was_overlapping = false
    overlap_frames = 0
    return false
  end

  overlap_frames = was_overlapping and (overlap_frames + 1) or 0
  was_overlapping = true

  -- Toca en el frame 0 (apenas empieza el solape) y en el 2 (por si el
  -- primero llegó un poco temprano/tarde) — un frame de descanso entre
  -- medio para que cuente como un toque nuevo, no un input sostenido.
  if overlap_frames == 0 or overlap_frames == 2 then
    local forward = (obj.pos_x >= self_state.pos_x) and "P2 Right" or "P2 Left"
    input[forward] = true
    return true
  end

  return false
end
