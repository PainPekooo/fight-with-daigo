-- Direcciones de memoria para Street Fighter III: 3rd Strike
-- ROM objetivo: sfiii3nr1 (Japan 990512), emulador FBNeo / Fightcade v2.0.91
--
-- Estas direcciones describen dónde vive cada dato mientras el juego corre
-- en el emulador (son observaciones externas sobre el estado en RAM, no
-- código ni assets del juego). La investigación de varias de estas direcciones
-- se apoyó como referencia en el mapeo público hecho por el proyecto
-- 3rd_training_lua de Grouflon (https://github.com/Grouflon/3rd_training_lua);
-- esta implementación es propia.

-- Definido como tabla global (no `local ... return`): main.lua carga este
-- archivo con dofile() por ruta absoluta, así que no hay un valor de retorno
-- que capturar — se comparte estado por variable global, como hace el resto
-- de los scripts de este emulador.
Memory = {}
local M = Memory

-- Bases de objeto de jugador. Todos los PLAYER_OFFSETS son relativos a esto.
M.PLAYER_BASE = {
  [1] = 0x02068C6C,
  [2] = 0x02069104,
}

-- Offsets dentro del struct de un jugador (relativos a PLAYER_BASE[n])
M.PLAYER_OFFSETS = {
  pos_x          = { addr = 0x64,  type = "word_s" },
  pos_y          = { addr = 0x68,  type = "word_s" },
  char_id        = { addr = 0x3C0, type = "word" },
  life           = { addr = 0x9F,  type = "byte" },
  posture        = { addr = 0x20E, type = "byte" },
  action_state   = { addr = 0xAC,  type = "dword" }, -- estado de animación actual
  recovery_time  = { addr = 0x187, type = "byte" },
  freeze_frames  = { addr = 0x45,  type = "byte" },  -- hitstop restante
  input_capacity = { addr = 0x46C, type = "word" },
  flip_x         = { addr = 0x0A,  type = "byte_s" }, -- sprite mira a la izquierda por defecto
}

-- Valores conocidos del campo "posture"
M.POSTURE = {
  STANDING      = 0x00,
  WALK_BACK     = 0x08,
  WALK_FORWARD  = 0x06,
  CROUCHING     = 0x20,
  NEUTRAL_JUMP  = 0x16,
  JUMP_FORWARD  = 0x14,
  JUMP_BACKWARD = 0x18,
  HIGH_JUMP     = 0x1A,
  KNOCKED_DOWN  = 0x26,
}

-- Direcciones globales (no dependen del jugador)
M.GLOBAL = {
  frame_number = 0x02007F00, -- dword
  match_state  = 0x020154A7, -- byte, 0x02 = ronda en curso
}

-- Punteros fijos por jugador que no forman parte del struct base
M.PLAYER_FIXED = {
  [1] = {
    gauge       = 0x020695B5, -- super meter, barras llenas
    meter_count = 0x020695BF, -- super meter, progreso de la barra actual
    stun_max    = 0x020695F7,
    parry = {
      forward = { validity = 0x02026335, cooldown = 0x02025731 },
      down    = { validity = 0x02026337, cooldown = 0x0202574D },
      air     = { validity = 0x02026339, cooldown = 0x02025769 },
      antiair = { validity = 0x02026347, cooldown = 0x0202582D },
    },
  },
  [2] = {
    gauge       = 0x020695E1,
    meter_count = 0x020695EB,
    stun_max    = 0x0206960B,
    parry = {
      forward = { validity = 0x02026335 + 0x406, cooldown = 0x02025731 + 0x620 },
      down    = { validity = 0x02026337 + 0x406, cooldown = 0x0202574D + 0x620 },
      air     = { validity = 0x02026339 + 0x406, cooldown = 0x02025769 + 0x620 },
      antiair = { validity = 0x02026347 + 0x406, cooldown = 0x0202582D + 0x620 },
    },
  },
}

-- Direcciones de la pantalla de selección de personaje.
-- row/col: posición en la grilla. color: paleta elegida. state: fase del
-- flujo de selección (0=fuera, 1..5 avanzando hasta bloqueado).
-- state == 4 es la fase de selección de Super Art. sa guarda el índice
-- elegido (0..2 = SA1..SA3).
M.PLAYER_SELECT = {
  [1] = {
    row   = 0x020154CF,
    col   = 0x0201566B,
    color = 0x02015683,
    state = 0x0201553D,
    sa    = 0x020154D3,
  },
  [2] = {
    row   = 0x020154D1,
    col   = 0x0201566D,
    color = 0x02015684,
    state = 0x02015545,
    sa    = 0x020154D5,
  },
}

function M.read_select_state(player_id)
  local a = M.PLAYER_SELECT[player_id]
  return {
    row   = memory.readbyte(a.row),
    col   = memory.readbyte(a.col),
    color = memory.readbyte(a.color),
    state = memory.readbyte(a.state),
    sa    = memory.readbyte(a.sa),
  }
end

-- Verificado en vivo con RAM watch: seleccionar a Ken en la grilla y quedarse
-- en el traje blanco durante un combate real (no en el portrait fijo de la
-- pantalla de Super Art, que no refleja el traje elegido).
M.KEN_SELECT = { row = 0, col = 2 }

-- SA3 (Shippu Jinraikyaku): la que usó Daigo Umehara en Evo Moment 37
-- (https://en.wikipedia.org/wiki/Evo_Moment_37).
-- Mapeo SA1=0,SA2=1,SA3=2 confirmado seleccionando SA3 a mano (se vio sa:2
-- en el overlay). Ver character_select.lua para el forzado automático.
M.KEN_DEFAULT_SA = 2
M.KEN_WHITE_GI_COLOR = 5

M.CHARACTERS = {
  "gill", "alex", "ryu", "yun", "dudley", "necro", "hugo", "ibuki", "elena",
  "oro", "yang", "ken", "sean", "urien", "gouki", "gill", "chunli", "makoto",
  "q", "twelve", "remy",
}
M.KEN_CHAR_ID = 11 -- índice 0-based dentro de CHARACTERS ("ken")

local READERS = {
  byte   = function(addr) return memory.readbyte(addr) end,
  byte_s = function(addr) return memory.readbytesigned(addr) end,
  word   = function(addr) return memory.readword(addr) end,
  word_s = function(addr) return memory.readwordsigned(addr) end,
  dword  = function(addr) return memory.readdword(addr) end,
}

function M.read_player_field(player_id, field_name)
  local offset_def = M.PLAYER_OFFSETS[field_name]
  assert(offset_def, "campo desconocido: " .. tostring(field_name))
  local base = M.PLAYER_BASE[player_id]
  assert(base, "player_id inválido: " .. tostring(player_id))
  return READERS[offset_def.type](base + offset_def.addr)
end

function M.read_player_state(player_id)
  local state = {}
  for field_name, _ in pairs(M.PLAYER_OFFSETS) do
    state[field_name] = M.read_player_field(player_id, field_name)
  end
  local fixed = M.PLAYER_FIXED[player_id]
  state.gauge = memory.readbyte(fixed.gauge)
  state.meter_count = memory.readbyte(fixed.meter_count)
  state.stun_max = memory.readbyte(fixed.stun_max)
  state.char_name = M.CHARACTERS[state.char_id + 1]
  return state
end

function M.frame_number()
  return memory.readdword(M.GLOBAL.frame_number)
end

function M.is_round_active()
  return memory.readbyte(M.GLOBAL.match_state) == 0x02
end

-- Offset de la lista de hitboxes de ataque dentro del struct de jugador
-- (mismo mecanismo que usa 3rd_training_lua para dibujar hitboxes en
-- pantalla). Hasta 4 boxes de 8 bytes cada uno (left, width, bottom,
-- height, 2 bytes cada campo); un box en 0,0,0,0 significa "vacío".
local ATTACK_BOXES_OFFSET = 0x2C8
local ATTACK_BOXES_COUNT = 4

-- Lee la primera hitbox de ataque activa de un "game object" (jugador o
-- proyectil — el juego usa el mismo struct para los dos, por eso funciona
-- igual para ambos). Devuelve nil si no hay ninguna activa, o
-- {left, width, bottom, height} si la hay (relativo a la posición del
-- objeto).
function M.read_attack_box(object_base)
  local list_base = memory.readdword(object_base + ATTACK_BOXES_OFFSET)
  if list_base == 0 then
    return nil
  end

  for i = 0, ATTACK_BOXES_COUNT - 1 do
    local box_ptr = list_base + i * 8
    local left   = memory.readwordsigned(box_ptr + 0x0)
    local width  = memory.readwordsigned(box_ptr + 0x2)
    local bottom = memory.readwordsigned(box_ptr + 0x4)
    local height = memory.readwordsigned(box_ptr + 0x6)
    if left ~= 0 or width ~= 0 or bottom ~= 0 or height ~= 0 then
      return { left = left, width = width, bottom = bottom, height = height }
    end
  end

  return nil
end

-- true si el jugador tiene una hitbox de ataque activa en este momento (o
-- sea, está en medio de un golpe que puede conectar ahora mismo) — a
-- diferencia de mirar distancia, esto no depende de adivinar el alcance de
-- cada movimiento.
function M.has_active_attack_box(player_id)
  return M.read_attack_box(M.PLAYER_BASE[player_id]) ~= nil
end
