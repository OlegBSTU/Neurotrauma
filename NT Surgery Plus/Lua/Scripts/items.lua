local experimentalEffects = {
	-- resistances and buffs
	vigor = {
		weight = 3,
		afflictions = { { identifier = "strengthen", minstrength = 200, maxstrength = 400, limbspecific = false } },
	},
	haste = {
		weight = 3,
		afflictions = { { identifier = "haste", minstrength = 200, maxstrength = 400, limbspecific = false } },
	},
	psychosisresistance = {
		weight = 2,
		afflictions = {
			{ identifier = "psychosisresistance", minstrength = 200, maxstrength = 400, limbspecific = false },
		},
	},
	huskinfectionresistance = {
		weight = 2,
		afflictions = {
			{ identifier = "huskinfectionresistance", minstrength = 200, maxstrength = 400, limbspecific = false },
		},
	},
	paralysisresistance = {
		weight = 2,
		afflictions = {
			{ identifier = "paralysisresistance", minstrength = 300, maxstrength = 600, limbspecific = false },
		},
	},
	analgesia = {
		weight = 1,
		afflictions = {
			{ identifier = "analgesia", minstrength = 20, maxstrength = 100, limbspecific = false },
		},
	},
	anesthesia = {
		weight = 0.5,
		afflictions = {
			{ identifier = "anesthesia", minstrength = 1, maxstrength = 100, limbspecific = false },
		},
	},
	ointmented = {
		weight = 1,
		afflictions = {
			{ identifier = "ointmented", minstrength = 20, maxstrength = 100, limbspecific = true },
		},
	},
	combatstimulant = {
		weight = 2,
		afflictions = { { identifier = "combatstimulant", minstrength = 30, maxstrength = 100, limbspecific = false } },
	},
	pressurestabilized = {
		weight = 1,
		afflictions = {
			{ identifier = "pressurestabilized", minstrength = 30, maxstrength = 100, limbspecific = false },
		},
	},
	-- other positive
	fullheal = {
		weight = 5,
		afflictions = {
			{ identifier = "bleeding", minstrength = -20, maxstrength = -100, limbspecific = true },
			{ identifier = "burn", minstrength = -20, maxstrength = -100, limbspecific = true },
			{ identifier = "explosiondamage", minstrength = -20, maxstrength = -100, limbspecific = true },
			{ identifier = "gunshotwound", minstrength = -20, maxstrength = -100, limbspecific = true },
			{ identifier = "bitewounds", minstrength = -20, maxstrength = -100, limbspecific = true },
			{ identifier = "lacerations", minstrength = -20, maxstrength = -100, limbspecific = true },
			{ identifier = "organdamage", minstrength = -20, maxstrength = -100, limbspecific = false },
			{ identifier = "cerebralhypoxia", minstrength = -20, maxstrength = -100, limbspecific = false },
			{ identifier = "bloodloss", minstrength = -20, maxstrength = -100, limbspecific = false },
			{ identifier = "blunttrauma", minstrength = -20, maxstrength = -100, limbspecific = true },
			{ identifier = "sepsis", minstrength = -200, maxstrength = -200, limbspecific = false },
		},
	},
	-- damage
	bleeding = {
		weight = 1,
		afflictions = { { identifier = "bleeding", minstrength = 30, maxstrength = 80, limbspecific = true } },
	},
	burn = {
		weight = 1,
		afflictions = { { identifier = "burn", minstrength = 5, maxstrength = 20, limbspecific = true } },
	},
	explosiondamage = {
		weight = 1,
		afflictions = { { identifier = "explosiondamage", minstrength = 5, maxstrength = 20, limbspecific = true } },
	},
	gunshotwound = {
		weight = 1,
		afflictions = {
			{ identifier = "gunshotwound", minstrength = 5, maxstrength = 20, limbspecific = true },
		},
	},
	bitewounds = {
		weight = 1,
		afflictions = {
			{ identifier = "bitewounds", minstrength = 5, maxstrength = 20, limbspecific = true },
		},
	},
	lacerations = {
		weight = 1,
		afflictions = {
			{ identifier = "lacerations", minstrength = 5, maxstrength = 20, limbspecific = true },
		},
	},
	organdamage = {
		weight = 1,
		afflictions = {
			{ identifier = "organdamage", minstrength = 5, maxstrength = 20, limbspecific = false },
		},
	},
	blunttrauma = {
		weight = 1,
		afflictions = {
			{ identifier = "blunttrauma", minstrength = 5, maxstrength = 20, limbspecific = true },
		},
	},
	-- other negative
	stun = {
		weight = 1,
		afflictions = { { identifier = "stun", minstrength = 2, maxstrength = 15, limbspecific = false } },
	},
}

Timer.Wait(function()
	NT.ItemMethods.artificialbrain = function(item, usingCharacter, targetCharacter, limb)
		local limbtype = limb.type
		if HF.HasAffliction(targetCharacter, "brainremoved", 1) and limbtype == LimbType.Head then
			HF.SetAffliction(targetCharacter, "cerebralhypoxia", 0, usingCharacter)
			HF.SetAffliction(targetCharacter, "brainremoved", 0, usingCharacter)
			HF.SetAffliction(targetCharacter, "artificialbrain", 100, usingCharacter)

			HF.RemoveItem(item)
		end
	end

	NT.ItemMethods.experimentaltreatment = function(item, usingCharacter, targetCharacter, limb)
		local limbtype = limb.type

		-- endocrine booster
		if HF.Chance(1 / 25) then
			HF.ApplyEndocrineBoost(targetCharacter)
		end

		local weightsum = 0
		for key, val in pairs(experimentalEffects) do
			weightsum = weightsum + val.weight
		end

		local triggerNewEffect = true
		while triggerNewEffect do
			triggerNewEffect = HF.Chance(0.5)

			local weightpick = math.random() * weightsum
			local currentweightsum = 0

			for key, val in pairs(experimentalEffects) do
				currentweightsum = currentweightsum + val.weight
				if currentweightsum > weightpick then
					-- picked effect: val

					for aff in val.afflictions do
						if aff.limbspecific then
							HF.AddAfflictionLimb(
								targetCharacter,
								aff.identifier,
								limbtype,
								HF.Lerp(aff.minstrength, aff.maxstrength, math.random()),
								usingCharacter
							)
						else
							HF.AddAffliction(
								targetCharacter,
								aff.identifier,
								HF.Lerp(aff.minstrength, aff.maxstrength, math.random()),
								usingCharacter
							)
						end
					end

					break
				end
			end
		end

		HF.RemoveItem(item)
		HF.GiveItem(targetCharacter, "ntsfx_syringe")
	end

	-- Triage tags
	local function IsTriageTagged(character)
		return HF.HasAffliction(character, "triagetag_green")
			or HF.HasAffliction(character, "triagetag_yellow")
			or HF.HasAffliction(character, "triagetag_red")
			or HF.HasAffliction(character, "triagetag_black")
	end
	local function RemoveTriageTag(character)
		HF.SetAffliction(character, "triagetag_green", 0)
		HF.SetAffliction(character, "triagetag_yellow", 0)
		HF.SetAffliction(character, "triagetag_red", 0)
		HF.SetAffliction(character, "triagetag_black", 0)
	end
	table.insert(NT.CuttableAfflictions, "triagetag_green")
	table.insert(NT.CuttableAfflictions, "triagetag_yellow")
	table.insert(NT.CuttableAfflictions, "triagetag_red")
	table.insert(NT.CuttableAfflictions, "triagetag_black")
	NT.ItemMethods.manualtriagetag = function(item, usingCharacter, targetCharacter, limb)
		local limbtype = HF.NormalizeLimbType(limb.type)

		local alreadyTagged = IsTriageTagged(targetCharacter)

		RemoveTriageTag(targetCharacter)

		if limbtype == LimbType.LeftLeg or limbtype == LimbType.RightLeg then
			HF.SetAffliction(targetCharacter, "triagetag_green", 100)
		elseif limbtype == LimbType.LeftArm or limbtype == LimbType.RightArm then
			HF.SetAffliction(targetCharacter, "triagetag_yellow", 100)
		elseif limbtype == LimbType.Torso then
			HF.SetAffliction(targetCharacter, "triagetag_red", 100)
		else
			HF.SetAffliction(targetCharacter, "triagetag_black", 100)
		end

		if not alreadyTagged then
			HF.RemoveItem(item)
		end
	end
	-- automatic triage tag
	NT.ItemMethods.triagetag = function(item, usingCharacter, targetCharacter, limb)
		local limbtype = HF.NormalizeLimbType(limb.type)

		local alreadyTagged = IsTriageTagged(targetCharacter)

		RemoveTriageTag(targetCharacter)

		local fuckedness = 0

		local charHealth = targetCharacter.CharacterHealth

		-- vitality
		local healthFraction = charHealth.Vitality / charHealth.MaxVitality
		fuckedness = math.max(fuckedness, (-healthFraction + 1) * 100)

		-- fractures
		if
			HF.HasAffliction(targetCharacter, "ll_fracture")
			or HF.HasAffliction(targetCharacter, "rl_fracture")
			or HF.HasAffliction(targetCharacter, "la_fracture")
			or HF.HasAffliction(targetCharacter, "ra_fracture")
			or HF.HasAffliction(targetCharacter, "h_fracture")
			or HF.HasAffliction(targetCharacter, "n_fracture")
			or HF.HasAffliction(targetCharacter, "t_fracture")
		then
			fuckedness = math.max(fuckedness + 5, 20)
		end

		-- arterial cuts
		if
			HF.HasAffliction(targetCharacter, "ll_arterialcut")
			or HF.HasAffliction(targetCharacter, "rl_arterialcut")
			or HF.HasAffliction(targetCharacter, "la_arterialcut")
			or HF.HasAffliction(targetCharacter, "ra_arterialcut")
			or HF.HasAffliction(targetCharacter, "h_arterialcut")
			or HF.HasAffliction(targetCharacter, "n_arterialcut")
			or HF.HasAffliction(targetCharacter, "t_arterialcut")
		then
			if not HF.HasAffliction(targetCharacter, "arteriesclamp") then
				fuckedness = math.max(fuckedness + 10, 100)
			else
				fuckedness = math.max(fuckedness + 5, 50)
			end
		end

		-- rads
		local rads = HF.GetAfflictionStrength(targetCharacter, "radiationsickness", 0)
		fuckedness = math.max(fuckedness + math.max(0, rads - 25) * 0.2, HF.Minimum(rads, 25, 0) * 1.5)

		-- hypoxemia
		local hypoxemia = HF.GetAfflictionStrength(targetCharacter, "hypoxemia", 0)
		fuckedness = math.max(fuckedness + hypoxemia * 0.2, HF.Clamp(hypoxemia * 2, 0, 100))

		-- bloodloss
		local bloodloss = HF.GetAfflictionStrength(targetCharacter, "bloodloss", 0)
		fuckedness = math.max(fuckedness + bloodloss * 0.1, HF.Clamp(bloodloss, 0, 100))

		if fuckedness < 5 then
			HF.SetAffliction(targetCharacter, "triagetag_green", 100)
		elseif fuckedness < 60 then
			HF.SetAffliction(targetCharacter, "triagetag_yellow", 100)
		elseif fuckedness < 200 then
			HF.SetAffliction(targetCharacter, "triagetag_red", 100)
		else
			HF.SetAffliction(targetCharacter, "triagetag_black", 100)
		end

		if not alreadyTagged then
			HF.RemoveItem(item)
		end
	end
end, 1)
