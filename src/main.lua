-- Fight with Daigo — entry point
-- Load this file from Game -> Lua Scripting -> New Lua Script Window
--
-- Forces P2 = Ken (white gi), and during the match applies the AI rules
-- from src/ai/ (see src/ai/decide.lua for priority order).

-- require() looks for modules relative to the emulator process's working
-- directory, not this script's — so instead of relying on that, we locate
-- this file on disk and load its siblings by absolute path.
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
dofile(SCRIPT_DIR .. "opponent_tracker.lua")
dofile(SCRIPT_DIR .. "ai/anti_air.lua")
dofile(SCRIPT_DIR .. "ai/block.lua")
dofile(SCRIPT_DIR .. "ai/parry_fireball.lua")
dofile(SCRIPT_DIR .. "ai/parry_melee.lua")
dofile(SCRIPT_DIR .. "ai/throw_tech.lua")
dofile(SCRIPT_DIR .. "ai/tatsumaki.lua")
dofile(SCRIPT_DIR .. "ai/dash.lua")
dofile(SCRIPT_DIR .. "ai/jump_in.lua")
dofile(SCRIPT_DIR .. "ai/super_art.lua")
dofile(SCRIPT_DIR .. "ai/combo_punish.lua")
dofile(SCRIPT_DIR .. "ai/whiff_punish.lua")
dofile(SCRIPT_DIR .. "ai/wakeup_mixup.lua")
dofile(SCRIPT_DIR .. "ai/footsies.lua")
dofile(SCRIPT_DIR .. "ai/decide.lua")

rom_name = emu.romname()
if rom_name ~= "sfiii3nr1" then
  print("-----------------------------")
  print("WARNING: this script was tested against rom sfiii3nr1 (Japan 990512).")
  print("Detected rom: " .. tostring(rom_name) .. " — it may not work correctly.")
  print("-----------------------------")
end

local function on_start()
  print("Fight with Daigo — script loaded, rom: " .. tostring(rom_name))
end

-- Every P2 key this script might ever force. Cleared to `false` every frame
-- BEFORE deciding: otherwise a button we forced true on a previous frame
-- (e.g. "Weak Punch" to confirm character select, or a step of the
-- shoryuken sequence) stays stuck as true on later frames where we don't
-- need it, mixing with the new decision and producing commands we didn't
-- ask for (hadoukens, EX moves, etc).
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
  OpponentTracker.update()

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
