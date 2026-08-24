-- AI orchestrator: calls each rule in priority order.
-- AntiAir is exclusive during its active frames (mixing in another input
-- breaks the shoryuken sequence). Same for ParryFireball and ParryMelee: if
-- they tap "forward"/"down" that frame, it must not mix with Block's
-- "backward". ParryMelee only acts a fraction of the time (see the file) —
-- the rest of the time it returns false and Block stays as the fallback.
--
-- Block comes before Footsies: if there's a real threat (an active hit
-- from the opponent, a predicted one about to go active for a move we've
-- already timed this session, or an incoming projectile), blocking always
-- wins.
-- Since Block no longer depends on distance for the melee case (it reads
-- whether the opponent has an active attack hitbox, see block.lua), this
-- doesn't reintroduce the old "Ken blocks the whole match" bug: if the
-- opponent is close but not attacking, Block.has_threat() returns false
-- and Footsies is free to walk/poke.

AI = {}

-- Also returns a readable label describing what it did, to show on screen
-- without having to dump each rule's internal state.
function AI.decide(input)
  if AntiAir.decide(input) then return "shoryuken (anti-air)" end
  if ParryFireball.decide(input) then return "parry (hadouken)" end
  if ParryMelee.decide(input) then return "parry (melee)" end

  -- If the punish combo is already underway (started by WhiffPunish), keep
  -- finishing its sequence (starter + special) before anything else.
  if ComboPunish.active() and ComboPunish.decide(input) then
    return "combo punish"
  end

  if Block.has_threat() then
    if Block.decide(input) then
      return "blocking"
    end
    return "reacting..." -- during the delay before blocking a projectile
  end

  if WhiffPunish.decide(input) then return "whiff punish" end

  -- Wake-up situations get their own mixup (throw vs. meaty poke) with
  -- priority over Footsies/ThrowTech, so the opponent's knockdown doesn't
  -- always get met with the same telegraphed throw attempt.
  if WakeupMixup.decide(input) then return "wakeup mixup" end

  if Footsies.decide(input) then
    return "footsies: " .. Footsies.debug_action()
  end

  if ThrowTech.decide(input) then
    return "throw tech"
  end

  return "idle"
end
