-- Hooks Lua event "changeFallDamage" to cause more damage and NT afflictions like fractures and artery cuts on extremities depending on severity
local limbtypes = {
	LimbType.Torso,
	LimbType.Head,
	LimbType.LeftArm,
	LimbType.RightArm,
	LimbType.LeftLeg,
	LimbType.RightLeg,
}
local function HasLungs(c)
	return not HF.HasAffliction(c, "lungremoved")
end

local function getCalculatedReductionSuit(armor, strength, limbtype)
	if armor == nil then
		return 0
	end
	local reduction = 0

	if armor.HasTag("deepdivinglarge") or armor.HasTag("deepdiving") then
		local modifiers = armor.GetComponentString("Wearable").DamageModifiers
		for modifier in modifiers do
			if string.find(modifier.AfflictionIdentifiers, "blunttrauma") ~= nil then
				reduction = strength - strength * modifier.DamageMultiplier
			end
		end
	elseif armor.HasTag("clothing") and armor.HasTag("smallitem") and limbtype == LimbType.Torso then
		local modifiers = armor.GetComponentString("Wearable").DamageModifiers
		for modifier in modifiers do
			if string.find(modifier.AfflictionIdentifiers, "blunttrauma") ~= nil then
				reduction = strength - strength * modifier.DamageMultiplier
			end
		end
	end
	return reduction
end
local function getCalculatedReductionClothes(armor, strength, limbtype)
	if armor == nil then
		return 0
	end
	local reduction = 0
	if armor.HasTag("deepdiving") or armor.HasTag("diving") then
		local modifiers = armor.GetComponentString("Wearable").DamageModifiers
		for modifier in modifiers do
			if string.find(modifier.AfflictionIdentifiers, "blunttrauma") ~= nil then
				reduction = strength - strength * modifier.DamageMultiplier
			end
		end
	elseif armor.HasTag("clothing") and armor.HasTag("smallitem") then
		local modifiers = armor.GetComponentString("Wearable").DamageModifiers
		for modifier in modifiers do
			if string.find(modifier.AfflictionIdentifiers, "blunttrauma") ~= nil then
				reduction = strength - strength * modifier.DamageMultiplier
			end
		end
	end
	return reduction
end
local function getCalculatedReductionHelmet(armor, strength)
	if armor == nil then
		return 0
	end
	local reduction = 0

	if armor.HasTag("smallitem") then
		local modifiers = armor.GetComponentString("Wearable").DamageModifiers
		for modifier in modifiers do
			if string.find(modifier.AfflictionIdentifiers, "blunttrauma") ~= nil then
				reduction = strength - strength * modifier.DamageMultiplier
			end
		end
	end
	return reduction
end
local function getCalculatedConcussionReduction(armor, strength)
	if armor == nil then
		return 0
	end
	local reduction = 0

	if armor.HasTag("deepdiving") or armor.HasTag("deepdivinglarge") then
		local modifiers = armor.GetComponentString("Wearable").DamageModifiers
		for modifier in modifiers do
			if string.find(modifier.AfflictionIdentifiers, "concussion") ~= nil then
				reduction = strength - strength * modifier.DamageMultiplier
			end
		end
	elseif armor.HasTag("smallitem") then
		local modifiers = armor.GetComponentString("Wearable").DamageModifiers
		for modifier in modifiers do
			if string.find(modifier.AfflictionIdentifiers, "concussion") ~= nil then
				reduction = strength - strength * modifier.DamageMultiplier
			end
		end
	end
	return reduction
end
Hook.Add("changeFallDamage", "NT.falldamage", function(impactDamage, character, impactPos, velocity)
	-- dont bother with creatures
	if not character.IsHuman then
		return
	end

	-- dont apply fall damage in water
	if character.InWater then
		return 0
	end

	-- dont apply fall damage when dragged by someone
	if character.SelectedBy ~= nil then
		return 0
	end

	local velocityMagnitude = HF.Magnitude(velocity)
	velocityMagnitude = velocityMagnitude ^ 1.5

	-- apply fall damage to all limbs based on fall direction
	local mainlimbPos = character.AnimController.MainLimb.WorldPosition

	local limbDotResults = {}
	local minDotRes = 1000

	for limb in character.AnimController.Limbs do
		for type in limbtypes do
			if limb.type == type then
				-- fetch the direction of each limb relative to the torso
				local limbPosition = limb.WorldPosition
				local posDif = limbPosition - mainlimbPos
				posDif.X = posDif.X / 100
				posDif.Y = posDif.Y / 100
				local posDifMagnitude = HF.Magnitude(posDif)
				if posDifMagnitude > 1 then
					posDif.Normalize()
				end

				local normalizedVelocity = Vector2(velocity.X, velocity.Y)
				normalizedVelocity.Normalize()

				-- compare those directions to the direction we're moving
				-- this will later be used to hurt the limbs facing impact more than the others
				local limbDot = Vector2.Dot(posDif, normalizedVelocity)
				limbDotResults[type] = limbDot
				if minDotRes > limbDot then
					minDotRes = limbDot
				end
				break
			end
		end
	end

	-- shift all weights out of the negatives
	-- increase the weight of all limbs if speed is high
	-- the effect of this is that, at higher speeds, all limbs take damage instead of mainly the ones facing the impact site
	for type, dotResult in pairs(limbDotResults) do
		limbDotResults[type] = dotResult - minDotRes + math.max(0, (velocityMagnitude - 30) / 10)
	end

	-- count weight so we're able to distribute the damage fractionally
	local weightsum = 0
	for dotResult in limbDotResults do
		weightsum = weightsum + dotResult
	end

	for type, dotResult in pairs(limbDotResults) do
		local relativeWeight = dotResult / weightsum

		-- lets limit the numbers to the max value of blunttrauma so that resistances make sense
		local damageInflictedToThisLimb = math.min(
			relativeWeight * math.max(0, velocityMagnitude - 10) ^ 1.5 * NTConfig.Get("NT_falldamage", 1) * 0.5,
			200
		)
		NT.CauseFallDamage(character, type, damageInflictedToThisLimb)
	end

	-- make the normal damage not run
	return 0
end)
NT.CauseFallDamage = function(character, limbtype, strength)
	local armor1 = character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
	local armor2 = character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
	if limbtype ~= LimbType.Head then
		strength = math.max(
			strength
				- getCalculatedReductionSuit(armor1, strength, limbtype)
				- getCalculatedReductionClothes(armor2, strength, limbtype),
			0
		)
	else
		armor2 = character.Inventory.GetItemInLimbSlot(InvSlotType.Head)
		strength = math.max(
			strength
				- getCalculatedReductionSuit(armor1, strength, limbtype)
				- getCalculatedReductionHelmet(armor2, strength, limbtype),
			0
		)
	end
	HF.AddAfflictionLimb(character, "blunttrauma", limbtype, strength)

	-- additionally calculate the affliction reduced damage
	local prefab = AfflictionPrefab.Prefabs["blunttrauma"]
	local resistance = character.CharacterHealth.GetResistance(prefab, limbtype)
	if resistance >= 1 then
		return
	end
	strength = strength * (1 - resistance)

	-- return earlier if the strength value is not high enough for damage checks
	if strength < 1 then
		return
	end

	local fractureImmune = false

	local injuryChanceMultiplier = NTConfig.Get("NT_falldamageSeriousInjuryChance", 1)

	-- torso
	if not fractureImmune and strength >= 1 and limbtype == LimbType.Torso then
		if
			HF.Chance(
				(strength - 15)
					/ 100
					* NTC.GetMultiplier(character, "anyfracturechance")
					* NTConfig.Get("NT_fractureChance", 1)
					* injuryChanceMultiplier
			)
		then
			NT.BreakLimb(character, limbtype)
			if
				HasLungs(character)
				and strength >= 5
				and HF.Chance(
					strength
						/ 70
						* NTC.GetMultiplier(character, "pneumothoraxchance")
						* NTConfig.Get("NT_pneumothoraxChance", 1)
				)
			then
				HF.AddAffliction(character, "pneumothorax", 5)
			end
		end
	end

	-- head
	if not fractureImmune and strength >= 1 and limbtype == LimbType.Head then
		if strength >= 15 and HF.Chance(math.min(strength / 100, 0.7)) then
			HF.AddAfflictionResisted(
				character,
				"concussion",
				math.max(
					10
						- getCalculatedConcussionReduction(armor1, 10, limbtype)
						- getCalculatedConcussionReduction(armor2, 10, limbtype),
					0
				)
			)
		end
		if
			strength >= 15
			and HF.Chance(
				math.min((strength - 15) / 100, 0.7)
					* NTC.GetMultiplier(character, "anyfracturechance")
					* NTConfig.Get("NT_fractureChance", 1)
					* injuryChanceMultiplier
			)
		then
			NT.BreakLimb(character, limbtype)
		end
		if
			strength >= 55
			and HF.Chance(
				math.min((strength - 55) / 100, 0.7)
					* NTC.GetMultiplier(character, "anyfracturechance")
					* NTConfig.Get("NT_fractureChance", 1)
					* injuryChanceMultiplier
			)
		then
			HF.AddAffliction(character, "n_fracture", 5)
		end
		if strength >= 5 and HF.Chance(0.7) then
			HF.AddAffliction(character, "cerebralhypoxia", strength * HF.RandomRange(0.1, 0.4))
		end
	end

	-- extremities
	if not fractureImmune and strength >= 1 and HF.LimbIsExtremity(limbtype) then
		if
			HF.Chance(
				(strength - 15)
					/ 100
					* NTC.GetMultiplier(character, "anyfracturechance")
					* NTConfig.Get("NT_fractureChance", 1)
					* injuryChanceMultiplier
			)
		then
			NT.BreakLimb(character, limbtype)
			if HF.Chance((strength - 2) / 60) then
				-- this is here to simulate open fractures
				NT.ArteryCutLimb(character, limbtype)
			end
		end
		if
			HF.Chance(
				HF.Clamp((strength - 5) / 120, 0, 0.5)
					* NTC.GetMultiplier(character, "dislocationchance")
					* NTConfig.Get("NT_dislocationChance", 1)
					* injuryChanceMultiplier
			) and not NT.LimbIsAmputated(character, limbtype)
		then
			NT.DislocateLimb(character, limbtype)
		end
	end
end
