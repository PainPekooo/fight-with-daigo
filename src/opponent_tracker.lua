-- Tracks facts about the opponent (P1) that only make sense to read once,
-- at character select, and remember for the rest of the match — right now
-- just which Super Art they picked. Used by the Evo Moment 37 easter egg
-- (parry_melee.lua) to know whether Chun-Li's super THIS match is
-- specifically Houyoku Sen (SA2): since a character can only have one SA
-- selected per match, if she picked SA2, any super she throws for the rest
-- of the match is Houyoku Sen by definition — no need to fingerprint the
-- specific move by its action_state id.
--
-- Only captures the value on the rising edge of "just locked in" (state
-- crossing into >= 5), instead of re-reading every frame while not in a
-- round: it didn't work live (Ken kept eating Houyoku Sen unparried) —
-- between rounds of the SAME match (not a new match, just round 2/3),
-- Memory.is_round_active() goes false too, and the select-state addresses
-- likely don't hold anything meaningful during that transition, so
-- continuously re-reading them risked overwriting the correct captured
-- value with stale/garbage data.

OpponentTracker = {}

OpponentTracker.selected_sa = nil

local was_locked = false

function OpponentTracker.update()
  if Memory.is_round_active() then
    was_locked = false -- re-arm for the next character-select cycle
    return
  end

  local sel = Memory.read_select_state(AIUtil.OPPONENT_ID)
  local locked = sel.state >= 5

  if locked and not was_locked then
    OpponentTracker.selected_sa = sel.sa
  end
  was_locked = locked
end
