-- Reads the list of active projectiles in memory (hadoukens, etc.).
-- Based on 3rd_training_lua's "game object" reading mechanism: a linked
-- list of slots, indexed by a head pointer per list type (here we use the
-- projectile list, id 3).

Projectiles = {}

local OBJECT_LIST_INDEX = 0x02068A96
local OBJECT_LIST_BASE = 0x02028990
local PROJECTILE_LIST_ID = 3
local MAX_OBJECTS = 30

function Projectiles.list()
  local result = {}
  local obj_index = memory.readwordsigned(OBJECT_LIST_INDEX + (PROJECTILE_LIST_ID * 2))
  local slot = 1

  while slot <= MAX_OBJECTS and obj_index ~= -1 do
    local base = OBJECT_LIST_BASE + bit.lshift(obj_index, 11)

    if memory.readdword(base + 0x2A0) ~= 0 then -- valid object
      table.insert(result, {
        base = base,
        pos_x = memory.readwordsigned(base + 0x64),
        pos_y = memory.readwordsigned(base + 0x68),
        emitter_id = memory.readbyte(base + 0x2) + 1,
        attack_box = Memory.read_attack_box(base),
      })
    end

    obj_index = memory.readwordsigned(base + 0x1C)
    slot = slot + 1
  end

  return result
end
