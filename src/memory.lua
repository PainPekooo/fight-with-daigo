-- Memory addresses for Street Fighter III: 3rd Strike
-- Target ROM: sfiii3nr1 (Japan 990512), FBNeo / Fightcade v2.0.91 emulator
--
-- These addresses describe where each piece of data lives while the game
-- runs in the emulator (they're external observations about the RAM state,
-- not game code or assets). Research into several of these addresses used
-- as reference the public mapping done by Grouflon's 3rd_training_lua
-- project (https://github.com/Grouflon/3rd_training_lua); this
-- implementation is original.

-- Defined as a global table (no `local ... return`): main.lua loads this
-- file with dofile() by absolute path, so there's no return value to
-- capture — state is shared via a global variable, like the rest of this
-- emulator's scripts do.
Memory = {}
local M = Memory

-- Player object bases. All PLAYER_OFFSETS are relative to this.
M.PLAYER_BASE = {
  [1] = 0x02068C6C,
  [2] = 0x02069104,
}

-- Offsets inside a player's struct (relative to PLAYER_BASE[n])
M.PLAYER_OFFSETS = {
  pos_x          = { addr = 0x64,  type = "word_s" },
  pos_y          = { addr = 0x68,  type = "word_s" },
  char_id        = { addr = 0x3C0, type = "word" },
  life           = { addr = 0x9F,  type = "byte" },
  posture        = { addr = 0x20E, type = "byte" },
  action_state   = { addr = 0xAC,  type = "dword" }, -- current animation state
  recovery_time  = { addr = 0x187, type = "byte" },
  freeze_frames  = { addr = 0x45,  type = "byte" },  -- remaining hitstop
  input_capacity = { addr = 0x46C, type = "word" },
  flip_x         = { addr = 0x0A,  type = "byte_s" }, -- sprite faces left by default
}

-- Known values for the "posture" field
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

-- Global addresses (not per-player)
M.GLOBAL = {
  frame_number = 0x02007F00, -- dword
  match_state  = 0x020154A7, -- byte, 0x02 = round in progress
}

-- Fixed per-player pointers that aren't part of the base struct
-- `state` (cooldown + 2 bytes) is new: not something we mapped ourselves,
-- cross-checked against effie3rd/3rd_training_lua's memory_addresses.lua
-- (GPL-3.0 — only read to confirm addresses/facts about the game, no code
-- copied, see reference memory). Their P1 addresses matched ours exactly,
-- and their P2 addresses matched our own +0x406/+0x620 offset math, which
-- is good independent confirmation our mapping was already right.
-- `state` itself: their code treats 1 as "can attempt" and 3 as "can't",
-- but that's what THEY force-write for an auto-parry cheat feature, not
-- necessarily the state machine's natural values. Live-logged it
-- ourselves and it isn't that simple: it cycles through (at least) 0-4
-- during normal play — roughly idle (0/1, the two seem to alternate at
-- rest for reasons we haven't identified) -> window opens (2, validity and
-- cooldown both near their max) -> window closing while cooldown ticks
-- down (3) -> tail end (4) -> back to idle. Not decoded well enough to
-- gate live behavior on yet — kept mapped for whenever someone wants to
-- take another pass at it, but nothing in ai/ reads `state` right now.
-- gauge/meter_count were swapped from the start (never verified live).
-- Live-logged both this session: the address now under `gauge` cycles 0 up
-- to ~76-79 and then wraps back down to a small number WHILE the address
-- now under `meter_count` ticks up by 1 -- i.e. what we had backwards: the
-- old `gauge` address was really the fine progress within the current bar,
-- and the old `meter_count` address was really the full-bar count. Swapped
-- here so `gauge` (the name every `gauge >= 1` check in ai/ already reads
-- as "do I have a usable bar") points at the address that's actually that.
M.PLAYER_FIXED = {
  [1] = {
    gauge       = 0x020695BF, -- super meter, full bars
    meter_count = 0x020695B5, -- super meter, progress within the current bar
    stun_max    = 0x020695F7,
    parry = {
      forward = { validity = 0x02026335, cooldown = 0x02025731, state = 0x02025733 },
      down    = { validity = 0x02026337, cooldown = 0x0202574D, state = 0x0202574F },
      air     = { validity = 0x02026339, cooldown = 0x02025769, state = 0x0202576B },
      antiair = { validity = 0x02026347, cooldown = 0x0202582D, state = 0x0202582F },
    },
  },
  [2] = {
    gauge       = 0x020695EB,
    meter_count = 0x020695E1,
    stun_max    = 0x0206960B,
    parry = {
      forward = { validity = 0x02026335 + 0x406, cooldown = 0x02025731 + 0x620, state = 0x02025733 + 0x620 },
      down    = { validity = 0x02026337 + 0x406, cooldown = 0x0202574D + 0x620, state = 0x0202574F + 0x620 },
      air     = { validity = 0x02026339 + 0x406, cooldown = 0x02025769 + 0x620, state = 0x0202576B + 0x620 },
      antiair = { validity = 0x02026347 + 0x406, cooldown = 0x0202582D + 0x620, state = 0x0202582F + 0x620 },
    },
  },
}

-- Character select screen addresses.
-- row/col: position in the grid. color: chosen palette. state: phase of
-- the select flow (0=out, 1..5 progressing until locked in).
-- state == 4 is the Super Art select phase. sa holds the chosen index
-- (0..2 = SA1..SA3).
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

-- Mapped at the very start of the project, before we even had a working
-- script — long unused because we didn't know the semantics. See the
-- M.PLAYER_FIXED comment above for the current (incomplete) understanding.
function M.read_parry_timers(player_id)
  local p = M.PLAYER_FIXED[player_id].parry
  local function triple(addrs)
    return {
      validity = memory.readbyte(addrs.validity),
      cooldown = memory.readbyte(addrs.cooldown),
      state    = memory.readbyte(addrs.state),
    }
  end
  return {
    forward = triple(p.forward),
    down    = triple(p.down),
    air     = triple(p.air),
    antiair = triple(p.antiair),
  }
end

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

-- Verified live with RAM watch: selecting Ken on the grid and staying on
-- the white gi during a real match (not on the fixed portrait of the
-- Super Art select screen, which doesn't reflect the chosen costume).
M.KEN_SELECT = { row = 0, col = 2 }

-- SA3 (Shippu Jinraikyaku): the one Daigo Umehara used at Evo Moment 37
-- (https://en.wikipedia.org/wiki/Evo_Moment_37).
-- Mapping SA1=0,SA2=1,SA3=2 confirmed by selecting SA3 by hand (sa:2 was
-- seen on the overlay). See character_select.lua for the automatic forcing.
M.KEN_DEFAULT_SA = 2
M.KEN_WHITE_GI_COLOR = 5

M.CHARACTERS = {
  "gill", "alex", "ryu", "yun", "dudley", "necro", "hugo", "ibuki", "elena",
  "oro", "yang", "ken", "sean", "urien", "gouki", "gill", "chunli", "makoto",
  "q", "twelve", "remy",
}
M.KEN_CHAR_ID = 11 -- 0-based index within CHARACTERS ("ken")

local READERS = {
  byte   = function(addr) return memory.readbyte(addr) end,
  byte_s = function(addr) return memory.readbytesigned(addr) end,
  word   = function(addr) return memory.readword(addr) end,
  word_s = function(addr) return memory.readwordsigned(addr) end,
  dword  = function(addr) return memory.readdword(addr) end,
}

function M.read_player_field(player_id, field_name)
  local offset_def = M.PLAYER_OFFSETS[field_name]
  assert(offset_def, "unknown field: " .. tostring(field_name))
  local base = M.PLAYER_BASE[player_id]
  assert(base, "invalid player_id: " .. tostring(player_id))
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

-- Offset of the attack hitbox list inside a player's struct (same
-- mechanism 3rd_training_lua uses to draw hitboxes on screen). Up to 4
-- boxes of 8 bytes each (left, width, bottom, height, 2 bytes per field);
-- a box at 0,0,0,0 means "empty".
local ATTACK_BOXES_OFFSET = 0x2C8
local ATTACK_BOXES_COUNT = 4

-- Reads the first active attack hitbox of a "game object" (player or
-- projectile — the game uses the same struct for both, which is why this
-- works the same for either). Returns nil if none is active, or
-- {left, width, bottom, height} if there is one (relative to the object's
-- position).
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

-- true if the player has an active attack hitbox right now (i.e. is in
-- the middle of a hit that can connect this instant) — unlike checking
-- distance, this doesn't depend on guessing each move's reach.
function M.has_active_attack_box(player_id)
  return M.read_attack_box(M.PLAYER_BASE[player_id]) ~= nil
end
