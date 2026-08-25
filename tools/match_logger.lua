-- Live match logger — a copy of main.lua's real bot control loop, plus
-- structured logging to a file. Load this INSTEAD OF main.lua when you
-- want a log of what the bot decided and why, to hand over for debugging
-- without needing to paste console output.
--
-- Logs to match_log.txt next to this file (overwritten each script
-- (re)start), one line per notable change: the AI's decision label
-- (e.g. "blocking", "footsies: poke (cr.MK)", "whiff punish") alongside
-- both players' state, so it's possible to see not just what happened but
-- what Ken THOUGHT he was doing at that moment.

local function script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then source = source:sub(2) end
  return source:match("(.*[/\\])") or "./"
end

local SCRIPT_DIR = script_dir()
local SRC_DIR = SCRIPT_DIR .. "../src/"
local LOG_PATH = SCRIPT_DIR .. "match_log.txt"

dofile(SRC_DIR .. "memory.lua")
dofile(SRC_DIR .. "character_select.lua")
dofile(SRC_DIR .. "projectiles.lua")
dofile(SRC_DIR .. "ai/util.lua")
dofile(SRC_DIR .. "opponent_tracker.lua")
dofile(SRC_DIR .. "opponent_reads.lua")
dofile(SRC_DIR .. "opponent_move_timing.lua")
dofile(SRC_DIR .. "ai/anti_air.lua")
dofile(SRC_DIR .. "ai/block.lua")
dofile(SRC_DIR .. "ai/parry_fireball.lua")
dofile(SRC_DIR .. "ai/parry_melee.lua")
dofile(SRC_DIR .. "ai/throw_tech.lua")
dofile(SRC_DIR .. "ai/tatsumaki.lua")
dofile(SRC_DIR .. "ai/dash.lua")
dofile(SRC_DIR .. "ai/jump_in.lua")
dofile(SRC_DIR .. "ai/super_art.lua")
dofile(SRC_DIR .. "ai/combo_punish.lua")
dofile(SRC_DIR .. "ai/whiff_punish.lua")
dofile(SRC_DIR .. "ai/wakeup_mixup.lua")
dofile(SRC_DIR .. "ai/footsies.lua")
dofile(SRC_DIR .. "ai/decide.lua")

rom_name = emu.romname()

local function on_start()
  print("match_logger.lua loaded, rom: " .. tostring(rom_name) .. " -- writing to " .. LOG_PATH)
end

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

local log_file = io.open(LOG_PATH, "w")
log_file:write("frame,decision,dist,p1_x,p1_posture,p1_action_state,p1_life,p1_dmg,p1_recovery,p2_x,p2_posture,p2_action_state,p2_life,p2_dmg,p2_gauge,p2_meter\n")
log_file:close()

local previous = nil

local function write_log(frame, decision, dist, p1, p2)
  local f = io.open(LOG_PATH, "a")
  f:write(string.format("%d,%s,%d,%d,%d,%d,%d,%s,%d,%d,%d,%d,%d,%s,%d,%d\n",
    frame, decision, dist,
    p1.pos_x, p1.posture, p1.action_state, p1.life, tostring(p1.dmg), p1.recovery_time,
    p2.pos_x, p2.posture, p2.action_state, p2.life, tostring(p2.dmg),
    p2.gauge, p2.meter_count))
  f:close()
end

local function before_frame()
  local input = joypad.get()
  clear_p2_input(input)
  OpponentTracker.update()
  OpponentReads.update()
  OpponentMoveTiming.update()

  if not Memory.is_round_active() then
    CharacterSelect.force_ken(input)
    joypad.set(input)
    previous = nil
    return
  end

  local decision = AI.decide(input)
  joypad.set(input)

  local p1_state = Memory.read_player_state(1)
  local p2_state = Memory.read_player_state(2)
  local p1 = {
    pos_x = p1_state.pos_x, posture = p1_state.posture,
    action_state = p1_state.action_state, life = p1_state.life,
    recovery_time = p1_state.recovery_time,
    dmg = previous ~= nil and p1_state.life < previous.p1_life,
  }
  local p2 = {
    pos_x = p2_state.pos_x, posture = p2_state.posture,
    action_state = p2_state.action_state, life = p2_state.life,
    gauge = p2_state.gauge, meter_count = p2_state.meter_count,
    dmg = previous ~= nil and p2_state.life < previous.p2_life,
  }
  local dist = math.abs(p1_state.pos_x - p2_state.pos_x)

  -- Force a line every single frame while ComboPunish is active (a short
  -- window, ~10-13 frames, no flood risk) -- chasing a reported "supers
  -- never connect" issue that needs frame-by-frame detail the normal
  -- on-change logging would blur together.
  local changed = previous == nil
    or decision ~= previous.decision
    or p1.action_state ~= previous.p1_action_state
    or p2.action_state ~= previous.p2_action_state
    or p1.dmg or p2.dmg
    or ComboPunish.active()

  if changed then
    write_log(Memory.frame_number(), decision, dist, p1, p2)
  end

  previous = {
    decision = decision,
    p1_action_state = p1.action_state, p1_life = p1_state.life,
    p2_action_state = p2.action_state, p2_life = p2_state.life,
  }
end

emu.registerstart(on_start)
emu.registerbefore(before_frame)
