Hook.Patch("Barotrauma.Character", "Control", function(instance)
	if instance.CharacterHealth.GetAfflictionStrengthByIdentifier("forceprone") > 1 then
		instance.SetInput(InputType.Crouch, false, true)
	end
end)

Hook.Patch("Barotrauma.Ragdoll", "get_ColliderHeightFromFloor", function(instance, ptable)
	if instance.Character and instance.Character.CharacterHealth then
		if instance.Character.CharacterHealth.GetAfflictionStrengthByIdentifier("forceprone") > 1 then
			return Single(0.1)
		end
	end
end, Hook.HookMethodType.After)
