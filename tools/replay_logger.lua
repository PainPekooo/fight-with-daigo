-- Passive replay logger — NOT part of the mod, a one-off research tool.
--
-- Purpose: watch a real high-level match (a downloaded/opened Fightcade
-- replay, or just any live match) and log what's actually happening to a
-- file, so we can extract real reference data (parry timing, combo cancel
-- windows, the still-not-fully-decoded parry `state` cycle from
-- memory.lua) instead of guessing.
--
-- Deliberately does NOT call joypad.set at all -- read-only, so it's safe
-- to run alongside a replay (or a live match) without fighting over
-- inputs the way main.lua would (main.lua actively controls P2). Load
-- ONLY this script for replay analysis; don't also have main.lua running.
--
-- Writes to replay_log.txt next to this file (overwritten each time the
-- script (re)starts) instead of the console -- a full match generates way
-- more lines than fits in scrollback, and a file can just be read back
-- directly afterward.

local function script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then source = source:sub(2) end
  return source:match("(.*[/\\])") or "./"
end

local SCRIPT_DIR = script_dir()
local SRC_DIR = SCRIPT_DIR .. "../src/"
local LOG_PATH = SCRIPT_DIR .. "replay_log.txt"

dofile(SRC_DIR .. "memory.lua")
dofile(SRC_DIR .. "ai/util.lua")

local INPUT_KEYS = {
  "Up", "Down", "Left", "Right",
  "Weak Punch", "Medium Punch", "Strong Punch",
  "Weak Kick", "Medium Kick", "Strong Kick",
}

local function input_summary(joypad_state, player_prefix)
  local parts = {}
  for _, key in ipairs(INPUT_KEYS) do
    if joypad_state[player_prefix .. " " .. key] then
      table.insert(parts, key)
    end
  end
  if #parts == 0 then
    return "-"
  end
  return table.concat(parts, "+")
end

local function parry_summary(player_id)
  local t = Memory.read_parry_timers(player_id)
  return string.format("fwd:%d/%d/%d down:%d/%d/%d air:%d/%d/%d aa:%d/%d/%d",
    t.forward.validity, t.forward.cooldown, t.forward.state,
    t.down.validity, t.down.cooldown, t.down.state,
    t.air.validity, t.air.cooldown, t.air.state,
    t.antiair.validity, t.antiair.cooldown, t.antiair.state)
end

local log_file = io.open(LOG_PATH, "w")
log_file:write("frame,side,pos_x,posture,action_state,life,gauge,meter_count,atkbox,input,parry\n")
log_file:close()

local previous = nil

local function player_snapshot(player_id, joypad_state, prefix)
  local state = Memory.read_player_state(player_id)
  return {
    pos_x = state.pos_x,
    posture = state.posture,
    action_state = state.action_state,
    life = state.life,
    gauge = state.gauge,
    meter_count = state.meter_count,
    atkbox = Memory.has_active_attack_box(player_id),
    input = input_summary(joypad_state, prefix),
    parry = parry_summary(player_id),
  }
end

local function snapshot_changed(a, b)
  if a == nil then
    return true
  end
  return a.action_state ~= b.action_state
    or a.atkbox ~= b.atkbox
    or a.input ~= b.input
    or a.parry ~= b.parry
end

local function write_line(frame, side, snap)
  local f = io.open(LOG_PATH, "a")
  f:write(string.format("%d,%s,%d,%d,%d,%d,%d,%d,%s,%s,%s\n",
    frame, side, snap.pos_x, snap.posture, snap.action_state, snap.life,
    snap.gauge, snap.meter_count, tostring(snap.atkbox), snap.input, snap.parry))
  f:close()
end

local function on_frame()
  if not Memory.is_round_active() then
    previous = nil
    return
  end

  local joypad_state = joypad.get()
  local frame = Memory.frame_number()
  local p1 = player_snapshot(1, joypad_state, "P1")
  local p2 = player_snapshot(2, joypad_state, "P2")

  if snapshot_changed(previous and previous.p1, p1) then
    write_line(frame, "P1", p1)
  end
  if snapshot_changed(previous and previous.p2, p2) then
    write_line(frame, "P2", p2)
  end

  previous = { p1 = p1, p2 = p2 }
end

emu.registerbefore(on_frame)
print("replay_logger.lua loaded -- writing to " .. LOG_PATH)
