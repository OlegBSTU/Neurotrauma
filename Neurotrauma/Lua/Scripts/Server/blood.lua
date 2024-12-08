-- Neurotrauma blood types functions
-- Hooks Lua event "characterCreated" to create a randomized blood type for spawned character and sets their immunity to 100
---@diagnostic disable: undefined-global

-- functions

--- Assigns a random blood type based on the percentages in the `NTTypes.BloodChance ` table
--- @param character Character
--- @return string NT.BloodType
function NT.RandomizeBlood(character)
	local rand = math.random(1, 100)
	local sum = 0

	for _, bloodTypeAndChance in ipairs(NTTypes.BloodChance) do
		sum = sum + bloodTypeAndChance[2]
		if rand <= sum then
			HF.SetAffliction(character, bloodTypeAndChance[1], 100)
			return bloodTypeAndChance[1]
		end
	end

	return NTTypes.BloodType.ab_plus -- If by some magic we don't get a blood type after going through the cycle
end

--- Get character's blood type
--- @param character Character
--- @return string NT.BloodType
function NT.GetBloodtype(character)
	for _, affliction in pairs(NTTypes.BloodType) do
		local conditional = character.CharacterHealth.GetAffliction(affliction)

		if conditional ~= nil and conditional.Strength > 0 then
			return affliction -- TODO: give out abplus (AB+) to enemy team for blood infusions
		end
	end

	return NT.RandomizeBlood(character)
end

--- Get character's blood type
--- @param character Character
--- @return boolean
function NT.HasBloodtype(character)
	for _, affliction in pairs(NTTypes.BloodType) do
		local conditional = character.CharacterHealth.GetAffliction(affliction)

		if conditional ~= nil and conditional.Strength > 0 then
			return true
		end
	end

	return false
end

--- Adds immunity to the character if it is not present
--- @param character Character
function NT.AddImmunity(character)
	local conditional2 = character.CharacterHealth.GetAffliction("immunity")
	if conditional2 == nil then
		HF.SetAffliction(character, "immunity", 100)
	end
end

-- hooks

Hook.Add("characterCreated", "NT.BloodAndImmunity", function(createdCharacter)
	Timer.Wait(function()
		if not createdCharacter.IsHuman or createdCharacter.IsDead then
			return
		end

		NT.RandomizeBlood(createdCharacter)
		NT.AddImmunity(createdCharacter)
	end, 1000)
end)

Hook.Add("OnInsertedIntoBloodAnalyzer", "NT.BloodAnalyzer", function(effect, deltaTime, item, targets, position)
	-- Hematology Analyzer (bloodanalyzer) can scan inserted blood bags
	if item.ParentInventory == nil or item.ParentInventory.Owner == nil or not item.ParentInventory.Owner.IsPlayer then
		return
	end

	local character = item.ParentInventory.Owner
	local contained = item.OwnInventory.GetItemAt(0)

	-- NT adds bloodbag; NT Blood Work or 'Real Sonar Medical Item Recipes Patch for Neurotrauma' add allblood, lets check for either
	if contained == nil or not (contained.HasTag("bloodbag") or contained.HasTag("allblood")) then
		return
	end

	HF.GiveItem(character, "ntsfx_syringe")
	Timer.Wait(function()
		if item == nil or character == nil or item.OwnInventory.GetItemAt(0) ~= contained then
			return
		end

		local identifier = contained.Prefab.Identifier.Value
		local packtype = "o-"
		if identifier ~= "antibloodloss2" then
			packtype = string.sub(identifier, string.len("bloodpack") + 1)
		end

		local bloodTypeDisplay = string.gsub(packtype, "abc", "c")
		bloodTypeDisplay = string.gsub(bloodTypeDisplay, "plus", "+")
		bloodTypeDisplay = string.gsub(bloodTypeDisplay, "minus", "-")
		bloodTypeDisplay = string.upper(bloodTypeDisplay)

		local readoutString = "Bloodpack: " .. bloodTypeDisplay

		-- check if acidosis, alkalosis or sepsis
		local tags = HF.SplitString(contained.Tags, ",")
		for tag in tags do
			if tag == "sepsis" then
				readoutString = readoutString .. "\nSepsis detected"
			end

			if HF.StartsWith(tag, "acid") then
				local split = HF.SplitString(tag, ":")
				if split[2] ~= nil then
					readoutString = readoutString .. "\nAcidosis: " .. tonumber(split[2]) .. "%"
				end
			elseif HF.StartsWith(tag, "alkal") then
				local split = HF.SplitString(tag, ":")
				if split[2] ~= nil then
					readoutString = readoutString .. "\nAlkalosis: " .. tonumber(split[2]) .. "%"
				end
			end
		end

		HF.DMClient(HF.CharacterToClient(character), readoutString, Color(127, 255, 255, 255))
	end, 1500)
end)
