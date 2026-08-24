-- Fight with Daigo — punto de entrada
-- Cargar este archivo desde Game -> Lua Scripting -> New Lua Script Window
--
-- Fuerza a P2 = Ken (traje blanco), y durante el combate le aplica las
-- reglas de IA de src/ai/ (ver src/ai/decide.lua para el orden de prioridad).

-- require() busca módulos relativos al directorio de trabajo del proceso del
-- emulador, no al de este script — así que en vez de depender de eso,
-- ubicamos este archivo en disco y cargamos sus hermanos por ruta absoluta.
local function script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then source = source:sub(2) end
  return source:match("(.*[/\\])") or "./"
end

local SCRIPT_DIR = script_dir()
dofile(SCRIPT_DIR .. "memory.lua")
dofile(SCRIPT_DIR .. "character_select.lua")
dofile(SCRIPT_DIR .. "projectiles.lua")
dofile(SCRIPT_DIR .. "ai/util.lua")
dofile(SCRIPT_DIR .. "ai/anti_air.lua")
dofile(SCRIPT_DIR .. "ai/block.lua")
dofile(SCRIPT_DIR .. "ai/parry_fireball.lua")
dofile(SCRIPT_DIR .. "ai/throw_tech.lua")
dofile(SCRIPT_DIR .. "ai/tatsumaki.lua")
dofile(SCRIPT_DIR .. "ai/dash.lua")
dofile(SCRIPT_DIR .. "ai/jump_in.lua")
dofile(SCRIPT_DIR .. "ai/footsies.lua")
dofile(SCRIPT_DIR .. "ai/decide.lua")

rom_name = emu.romname()
if rom_name ~= "sfiii3nr1" then
  print("-----------------------------")
  print("AVISO: este script fue probado con la rom sfiii3nr1 (Japan 990512).")
  print("Rom detectada: " .. tostring(rom_name) .. " — puede no funcionar correctamente.")
  print("-----------------------------")
end

local function on_start()
  print("Fight with Daigo — script cargado, rom: " .. tostring(rom_name))
end

-- Todas las teclas de P2 que este script puede llegar a forzar. Se limpian a
-- `false` en cada frame ANTES de decidir: si no, un botón que forzamos true
-- en un frame anterior (ej. el "Weak Punch" para confirmar en la selección
-- de personaje, o un paso de la secuencia de shoryuken) queda pegado como
-- true en frames siguientes donde no lo necesitamos, mezclándose con la
-- decisión nueva y generando comandos que no pedimos (hadoukens, EX, etc).
local P2_KEYS = {
  "P2 Up", "P2 Down", "P2 Left", "P2 Right",
  "P2 Weak Punch", "P2 Medium Punch", "P2 Strong Punch",
  "P2 Weak Kick", "P2 Medium Kick", "P2 Strong Kick",
}

local function clear_p2_input(input)
  for _, key in ipairs(P2_KEYS) do
    input[key] = false
  end
end

local function before_frame()
  local input = joypad.get()
  clear_p2_input(input)

  if not Memory.is_round_active() then
    CharacterSelect.force_ken(input)
    joypad.set(input)
    return
  end

  AI.decide(input)
  joypad.set(input)
end

emu.registerstart(on_start)
emu.registerbefore(before_frame)
