-- Neurotrauma human update functions
-- Hooks Lua event "think" to update and use for applying NT specific character data (its called 'c') with
-- values/functions defined here in NT.UpdateHuman, NT.LimbAfflictions and NT.Afflictions
NT.UpdateCooldown = 0
NT.UpdateInterval = 120
NT.Deltatime = NT.UpdateInterval / 60 -- Time in seconds that transpires between updates

Hook.Add("think", "NT.update", function()
	if HF.GameIsPaused() then
		return
	end

	NT.UpdateCooldown = NT.UpdateCooldown - 1
	if NT.UpdateCooldown <= 0 then
		NT.UpdateCooldown = NT.UpdateInterval
		NT.Update()
	end

	NT.TickUpdate()
end)

-- gets run once every two seconds
function NT.Update()
	local updateHumans = {}
	local amountHumans = 0
	local updateMonsters = {}
	local amountMonsters = 0

	-- fetchcharacters to update
	for key, character in pairs(Character.CharacterList) do
		if not character.IsDead then
			if character.IsHuman then
				table.insert(updateHumans, character)
				amountHumans = amountHumans + 1
			else
				table.insert(updateMonsters, character)
				amountMonsters = amountMonsters + 1
			end
		end
	end

	-- we spread the characters out over the duration of an update so that the load isnt done all at once
	for key, value in pairs(updateHumans) do
		-- make sure theyre still alive and human
		if value ~= nil and not value.Removed and value.IsHuman and not value.IsDead then
			Timer.Wait(function()
				if value ~= nil and not value.Removed and value.IsHuman and not value.IsDead then
					NT.UpdateHuman(value)
				end
			end, ((key + 1) / amountHumans) * NT.Deltatime * 1000)
		end
	end

	-- we spread the monsters out over the duration of an update so that the load isnt done all at once
	for key, value in pairs(updateMonsters) do
		-- make sure theyre still alive
		if value ~= nil and not value.Removed and not value.IsDead then
			Timer.Wait(function()
				if value ~= nil and not value.Removed and not value.IsDead then
					NT.UpdateMonster(value)
				end
			end, ((key + 1) / amountMonsters) * NT.Deltatime * 1000)
		end
	end
end

NT.organDamageCalc = function(c, damagevalue)
	if damagevalue >= 99 then
		return 100
	end

	return damagevalue - 0.01 * c.stats.healingrate * c.stats.specificOrganDamageHealMultiplier * NT.Deltatime
end

function NT.UpdateHuman(character)
	-- pre humanupdate hooks
	for _, val in pairs(NTC.PreHumanUpdateHooks) do
		val(character)
	end

	local charData = { character = character, afflictions = {}, stats = {} }

	-- fetch all the current affliction data
	for identifier, data in pairs(NT.Afflictions) do
		local strength = HF.GetAfflictionStrength(character, identifier, data.default or 0)
		charData.afflictions[identifier] = { prev = strength, strength = strength }
	end

	-- fetch and calculate all the current stats
	for identifier, data in pairs(NT.CharStats) do
		if data.getter ~= nil then
			charData.stats[identifier] = data.getter(charData)
		else
			charData.stats[identifier] = data.default or 1
		end
	end

	-- update non-limb-specific afflictions
	for identifier, data in pairs(NT.Afflictions) do
		if data.update ~= nil then
			data.update(charData, identifier)
		end
	end

	-- update and apply limb specific stuff
	local function FetchLimbData(type)
		local keystring = tostring(type) .. "afflictions"
		charData[keystring] = {}
		for identifier, data in pairs(NT.LimbAfflictions) do
			local strength = HF.GetAfflictionStrengthLimb(character, type, identifier, data.default or 0)
			charData[keystring][identifier] = { prev = strength, strength = strength }
		end
	end

	local function UpdateLimb(type)
		local keystring = tostring(type) .. "afflictions"
		for identifier, data in pairs(NT.LimbAfflictions) do
			if data.update ~= nil then
				data.update(charData, charData[keystring], identifier, type)
			end
		end
	end

	local function ApplyLimb(type)
		local keystring = tostring(type) .. "afflictions"
		for identifier, data in pairs(charData[keystring]) do
			local newval = HF.Clamp(
				data.strength,
				NT.LimbAfflictions[identifier].min or 0,
				NT.LimbAfflictions[identifier].max or 100
			)
			if newval ~= data.prev then
				if NT.LimbAfflictions[identifier].apply == nil then
					HF.SetAfflictionLimb(character, identifier, type, newval)
				else
					NT.LimbAfflictions[identifier].apply(charData, identifier, type, newval)
				end
			end
		end
	end

	-- stasis completely halts activity in limbs
	if not charData.stats.stasis then
		for _, type in ipairs(NTTypes.LimbTypes) do
			FetchLimbData(type)
		end
		for _, type in ipairs(NTTypes.LimbTypes) do
			UpdateLimb(type)
		end
		for _, type in ipairs(NTTypes.LimbTypes) do
			ApplyLimb(type)
		end
	end

	-- non-limb-specific late update (useful for things that use stats that are altered by limb specifics)
	for identifier, data in pairs(NT.Afflictions) do
		if data.lateupdate ~= nil then
			data.lateupdate(charData, identifier)
		end
	end

	-- apply non-limb-specific changes
	for identifier, data in pairs(charData.afflictions) do
		local newval =
			HF.Clamp(data.strength, NT.Afflictions[identifier].min or 0, NT.Afflictions[identifier].max or 100)
		if newval ~= data.prev then
			if NT.Afflictions[identifier].apply == nil then
				HF.SetAffliction(character, identifier, newval)
			else
				NT.Afflictions[identifier].apply(charData, identifier, newval)
			end
		end
	end

	-- compatibility
	NTC.TickCharacter(character)
	-- humanupdate hooks
	for key, val in pairs(NTC.HumanUpdateHooks) do
		val(character)
	end

	NTC.CharacterSpeedMultipliers[character] = nil
end

function NT.UpdateMonster(character)
	-- trade bloodloss on this creature for organ damage so that creatures can still bleed out
	local bloodloss = HF.GetAfflictionStrength(character, "bloodloss", 0)
	if bloodloss > 0 then
		HF.AddAffliction(character, "organdamage", bloodloss * 2)
		HF.SetAffliction(character, "bloodloss", 0)
	end
	-- TOOD: oxygen low conversion
end

-- gets run every tick, shouldnt be used unless necessary

function NT.TickUpdate()
	for key, value in pairs(NT.tickTasks) do
		value.duration = value.duration - 1
		if value.duration <= 0 then
			NT.tickTasks[key] = nil
		end
	end
end

NT.tickTasks = {}
NT.tickTaskID = 0
function NT.AddTickTask(type, duration, character)
	local newtask = {}
	newtask.type = type
	newtask.duration = duration
	newtask.character = character
	NT.tickTasks[NT.tickTaskID] = newtask
	NT.tickTaskID = NT.tickTaskID + 1
end
