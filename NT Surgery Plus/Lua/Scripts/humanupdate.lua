local limbtypes = {
	LimbType.LeftArm,
	LimbType.RightArm,
	LimbType.LeftLeg,
	LimbType.RightLeg,
	LimbType.Torso,
	LimbType.Head,
}

-- multipliers that are used in humanupdate are set here
function NTSP.PreUpdateHuman(character)
	-- under pressure talent
	if HF.HasAffliction(character, "underpressure") and HF.HasAffliction(character, "sym_unconsciousness") then
		NTC.SetMultiplier(character, "anyorgandamage", 0.5)
		NTC.SetMultiplier(character, "neurotraumagain", 0.5)
	end

	-- fine bedisde manner talent
	if HF.HasTalent(character, "ntsp_bedsidemanner") then
		for _, targetcharacter in pairs(Character.CharacterList) do
			if
				character ~= targetcharacter
				and targetcharacter.IsHuman
				and not targetcharacter.IsDead
				and HF.CharacterDistance(character, targetcharacter) < 600
			then
				-- near surgeon, no bed: 200%
				-- near surgeon, on bed: 300%
				if HF.HasAffliction(targetcharacter, "table", 0.1) then
					NTC.SetMultiplier(targetcharacter, "healingrate", 3)
				else
					NTC.SetMultiplier(targetcharacter, "healingrate", 2)
				end
			end
		end
	end

	-- sterility during surgery
	if NTConfig.Get("NTSP_enableSurgicalInfection", false) and HF.HasAffliction(character, "surgeryincision") then
		local sterility = 50

		local wearsdrape = HF.GetOuterWearIdentifier(character) == "surgicaldrapes"
		if wearsdrape then
			-- wearing surgical drapes? 100 base sterility
			sterility = 100
		else
			-- if no drape, check for ointments
			for i, val in ipairs(limbtypes) do
				if HF.HasAfflictionLimb(character, "surgeryincision", val) then
					if HF.HasAfflictionLimb(character, "ointmented", val) then
						sterility = sterility + 50
					else
						sterility = -9001
					end
				end
			end
		end

		sterility = HF.Clamp(sterility, 0, 100)

		-- determine overall sterility based on present humans and their sterility
		for _, targetcharacter in pairs(Character.CharacterList) do
			if
				character ~= targetcharacter
				and targetcharacter.IsHuman
				and HF.CharacterDistance(character, targetcharacter) < 150
			then
				local charSterility = 10 + HF.GetSkillLevel(targetcharacter, "surgery") / 5

				-- inner wear sterile? +40
				charSterility = charSterility
					+ 40 * HF.BoolToNum(HF.ItemHasTag(HF.GetInnerWear(targetcharacter), "sterile"))
				-- headwear sterile? +40
				charSterility = charSterility
					+ 40 * HF.BoolToNum(HF.ItemHasTag(HF.GetHeadWear(targetcharacter), "sterile"))
				-- add sterility from Ultrasonic Cleaner perk
				if HF.HasTalent(character, "ntsp_ultrasoniccleaner") then
					charSterility = charSterility + 30
				end

				-- adjust overall sterility based on character sterility and distance to patient
				charSterility = HF.Clamp(charSterility, 0, 100)
				sterility = HF.Lerp(
					sterility,
					sterility * (charSterility / 100),
					(150 - HF.CharacterDistance(character, targetcharacter)) / 150
				)
			end
		end

		-- at max dirtyness, theres a 10% chance every update (two seconds) to cause sepsis
		local sepsischance = HF.Clamp(1 - (sterility / 100), 0, 1) * 0.1

		if HF.Chance(sepsischance) then
			-- oops...
			NTSP.TriggerUnsterilityEvent(character)
		end
	end

	-- artificial brain
	if HF.HasAffliction(character, "artificialbrain") then
		NTC.SetSymptomTrue(character, "sym_unconsciousness")
	end
end

-- multipliers that are used outside of humanupdate are set here
function NTSP.PostUpdateHuman(character)
	-- preventative permit talent
	if HF.HasAffliction(character, "preventativepermit") then
		NTC.SetMultiplier(character, "anyfracturechance", 0.5)
		NTC.SetMultiplier(character, "pneumothoraxchance", 0.5)
		NTC.SetMultiplier(character, "tamponadechance", 0.5)
		NTC.SetMultiplier(character, "traumamputatechance", 0.5)
	end

	-- rinse and repeat talent
	if HF.HasTalent(character, "ntsp_ultrasoniccleaner") then
		NTC.SetMultiplier(character, "drainageconsumechance", 0)
		NTC.SetMultiplier(character, "balloonconsumechance", 0)
		NTC.SetMultiplier(character, "needleconsumechance", 0)
	end

	-- medical licence talent
	if HF.HasTalent(character, "ntsp_brucereitzperk") then
		NTC.SetTag(character, "organssellforfull")
		NTC.SetMultiplier(character, "organrejectionchance", 0)
	end
end

-- this function can be overriden by other mods
-- nudge nudge, wink wink
function NTSP.TriggerUnsterilityEvent(character)
	HF.AddAffliction(character, "sepsis", 1)
end
