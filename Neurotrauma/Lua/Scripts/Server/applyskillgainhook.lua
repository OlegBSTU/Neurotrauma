Hook.Patch("Barotrauma.CharacterInfo", "ApplySkillGain", function(instance, ptable)
	if ptable["skillIdentifier"].ToString() == "medical" and not ptable["gainedFromAbility"] then
		ptable.PreventExecution = true
	end
end, Hook.HookMethodType.Before)
