-- Tracks facts about the opponent (P1) that only make sense to read once,
-- at character select, and remember for the rest of the match — right now
-- just which Super Art they picked. Used by the Evo Moment 37 easter egg
-- (parry_melee.lua) to know whether Chun-Li's super THIS match is
-- specifically Houyoku Sen (SA2): since a character can only have one SA
-- selected per match, if she picked SA2, any super she throws for the rest
-- of the match is Houyoku Sen by definition — no need to fingerprint the
-- specific move by its action_state id.

OpponentTracker = {}

OpponentTracker.selected_sa = nil

function OpponentTracker.update()
  if Memory.is_round_active() then
    return
  end

  local sel = Memory.read_select_state(AIUtil.OPPONENT_ID)
  if sel.state == 0 then
    OpponentTracker.selected_sa = nil -- no player joined (yet), or just left
  elseif sel.state >= 5 then
    OpponentTracker.selected_sa = sel.sa
  end
end
