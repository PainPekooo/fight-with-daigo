-- Forces P2 to pick Ken (white gi) on the character select screen, without
-- needing to touch P2's controller by hand. Built for this project's flow:
-- P2 is the slot the AI will pilot from here on, so there's no real human
-- player whose input we'd be stepping on on this screen.
--
-- Writing to character_select_color isn't confirmed to actually work (in
-- the reference mapping it's only documented as readable) — we try it
-- anyway since it's a normal RAM byte; if it doesn't stick, it needs to be
-- checked live and adjusted.

CharacterSelect = {}

local PLAYER_ID = 2
local OPPONENT_ID = 1
local NO_PLAYER = 0 -- see enum in memory.lua (PLAYER_SELECT.state)
local CHARACTER_SELECT_PHASE = 2
local SA_SELECT_PHASE = 4

-- The first attempt to force the SA (with and without a delay before
-- confirming) ended up locking in SA2 instead of KEN_DEFAULT_SA. At the
-- time we thought the address was read-only, but it was actually the
-- "Weak Punch" used to confirm Ken in CHARACTER_SELECT_PHASE getting stuck
-- true from one frame to the next (an input-clearing bug, already fixed in
-- main.lua), confirming the default SA before our delay got a chance to
-- act. Retrying now that bug is fixed.
local SA_CONFIRM_DELAY_FRAMES = 5
local sa_select_frames = 0

-- Auto-join: while P2 has no player (state == 0) and P1 has already
-- started the flow (inserted their coin), we send coin + start to P2
-- instead of waiting for someone to do it by hand. Not verified yet
-- whether Start is actually needed or if the coin alone is enough — to be
-- tested live.
local JOIN_COIN_FRAMES = 5
local JOIN_START_FRAMES = 5
local join_frames = 0

local function reset()
  sa_select_frames = 0
  join_frames = 0
end

function CharacterSelect.force_ken(input)
  if Memory.is_round_active() then
    reset()
    return
  end

  local select_state = Memory.read_select_state(PLAYER_ID)
  local opponent_select_state = Memory.read_select_state(OPPONENT_ID)
  local addr = Memory.PLAYER_SELECT[PLAYER_ID]

  if select_state.state == NO_PLAYER and opponent_select_state.state ~= NO_PLAYER then
    join_frames = join_frames + 1
    if join_frames <= JOIN_COIN_FRAMES then
      input["P2 Coin"] = true
    elseif join_frames <= JOIN_COIN_FRAMES + JOIN_START_FRAMES then
      input["P2 Start"] = true
    end
  elseif select_state.state == CHARACTER_SELECT_PHASE then
    reset()
    memory.writebyte(addr.row, Memory.KEN_SELECT.row)
    memory.writebyte(addr.col, Memory.KEN_SELECT.col)
    memory.writebyte(addr.color, Memory.KEN_WHITE_GI_COLOR)
    input["P2 Weak Punch"] = true
  elseif select_state.state == SA_SELECT_PHASE then
    memory.writebyte(addr.sa, Memory.KEN_DEFAULT_SA)
    sa_select_frames = sa_select_frames + 1
    if sa_select_frames > SA_CONFIRM_DELAY_FRAMES then
      input["P2 Weak Punch"] = true
    end
  else
    reset()
  end
end
