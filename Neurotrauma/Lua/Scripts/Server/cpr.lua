-- Hooks Lua event "human.CPRSuccess" to prevent fractures from ragdoll jank, and
-- apply NT affliction cpr_buff or cause rib fractures in Hooked Lua event "human.CPRFailed"
-- human.CPRSuccess was changed to character.CPRSuccess? Way above my paygrade - Lukako

Hook.Add("character.CPRSuccess", "NT.CPRSuccess", function(animcontroller)
	if
		animcontroller == nil
		or animcontroller.Character == nil
		or animcontroller.Character.SelectedCharacter == nil
	then
		return
	end

	local character = animcontroller.Character.SelectedCharacter

	if not HF.HasAffliction(character, "luabotomy") then HF.SetAffliction(character, "luabotomy", 1) end

	if not HF.HasAffliction(character, "cpr_buff_auto") then HF.AddAffliction(character, "cpr_buff", 2) end

	HF.AddAffliction(character, "cpr_fracturebuff", 2) -- prevent fractures during CPR (fuck baro physics)
end)

Hook.Add("character.CPRFailed", "NT.CPRFailed", function(animcontroller)
	if
		animcontroller == nil
		or animcontroller.Character == nil
		or animcontroller.Character.SelectedCharacter == nil
	then
		return
	end

	local character = animcontroller.Character.SelectedCharacter

	if not HF.HasAffliction(character, "luabotomy") then HF.SetAffliction(character, "luabotomy", 1) end

	HF.AddAffliction(character, "cpr_fracturebuff", 2) -- prevent fractures during CPR (fuck baro physics)
	HF.AddAfflictionLimb(character, "blunttrauma", LimbType.Torso, 0.3)

	if
		HF.Chance(
			NTConfig.Get("NT_fractureChance", 1)
				* NTConfig.Get("NT_CPRFractureChance", 1)
				* 0.2
				/ HF.GetSkillLevel(animcontroller.Character, "medical")
		)
	then
		HF.AddAffliction(character, "t_fracture", 1)
	end
end)
