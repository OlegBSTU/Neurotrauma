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
		if NTConfig.Get("NT_Calculations", true) then
			NT.Update()
		end
	end

	-- I'm not entirely sure this should even exist, but lets keep it for reference
	--NT.TickUpdate()
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
			local client = HF.CharacterToClient(character)
			if
				character.IsHuman
				and (not Game.IsMultiplayer or character.IsPlayer == false or (client ~= nil and client.HasSpawned))
			then
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

-- some local functions to avoid code duplicates
local function limbLockedInitial(c, limbtype, key)
	return not NTC.GetSymptomFalse(c.character, key)
		and (
			NTC.GetSymptom(c.character, key)
			or NT.LimbIsAmputated(c.character, limbtype)
			or (HF.GetAfflictionStrengthLimb(c.character, limbtype, "bandaged", 0) <= 0 and HF.GetAfflictionStrengthLimb(
				c.character,
				limbtype,
				"dirtybandage",
				0
			) <= 0 and NT.LimbIsDislocated(c.character, limbtype))
			or (
				HF.GetAfflictionStrengthLimb(c.character, limbtype, "gypsumcast", 0) <= 0
				and NT.LimbIsBroken(c.character, limbtype)
			)
		)
end
NT.organDamageCalc = function(c, damagevalue, nomaxstrength)
	if damagevalue >= 99 and (nomaxstrength == nil or nomaxstrength == false) then
		return 100
	end
	return damagevalue - 0.01 * c.stats.healingrate * c.stats.specificOrganDamageHealMultiplier * NT.Deltatime
end
local function kidneyDamageCalc(c, damagevalue)
	if damagevalue >= 99 then
		return 100
	end
	if damagevalue >= 50 then
		if damagevalue <= 51 then
			return damagevalue
		end
		return damagevalue - 0.01 * c.stats.healingrate * c.stats.specificOrganDamageHealMultiplier * NT.Deltatime
	end
	return damagevalue - 0.02 * c.stats.healingrate * c.stats.specificOrganDamageHealMultiplier * NT.Deltatime
end
local function isExtremity(type)
	return type ~= LimbType.Torso and type ~= LimbType.Head
end
local limbtypes = {
	LimbType.Torso,
	LimbType.Head,
	LimbType.LeftArm,
	LimbType.RightArm,
	LimbType.LeftLeg,
	LimbType.RightLeg,
}

-- define all the afflictions and their update functions
NT.Afflictions = {
	-- Arterial cuts
	t_arterialcut = {},
	-- Fractures and amputations
	t_fracture = {
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				c.afflictions[i].strength = c.afflictions[i].strength
					+ 2
						* HF.BoolToNum(not HF.HasAfflictionLimb(c.character, "gypsumcast", LimbType.Torso))
						* NT.Deltatime
			end
		end,
	},
	h_fracture = {
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				c.afflictions[i].strength = c.afflictions[i].strength
					+ 2
						* HF.BoolToNum(not HF.HasAfflictionLimb(c.character, "gypsumcast", LimbType.Head))
						* NT.Deltatime
			end
		end,
	},
	la_fracture = {
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				c.afflictions[i].strength = c.afflictions[i].strength
					+ 2
						* HF.BoolToNum(not HF.HasAfflictionLimb(c.character, "gypsumcast", LimbType.LeftArm))
						* NT.Deltatime
			end
		end,
	},
	ra_fracture = {
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				c.afflictions[i].strength = c.afflictions[i].strength
					+ 2
						* HF.BoolToNum(not HF.HasAfflictionLimb(c.character, "gypsumcast", LimbType.RightArm))
						* NT.Deltatime
			end
		end,
	},
	ll_fracture = {
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				c.afflictions[i].strength = c.afflictions[i].strength
					+ 2
						* HF.BoolToNum(not HF.HasAfflictionLimb(c.character, "gypsumcast", LimbType.LeftLeg))
						* NT.Deltatime
			end
		end,
	},
	rl_fracture = {
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				c.afflictions[i].strength = c.afflictions[i].strength
					+ 2
						* HF.BoolToNum(not HF.HasAfflictionLimb(c.character, "gypsumcast", LimbType.RightLeg))
						* NT.Deltatime
			end
		end,
	},
	n_fracture = {
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				c.afflictions[i].strength = c.afflictions[i].strength
					+ 2
						* HF.BoolToNum(not HF.HasAfflictionLimb(c.character, "gypsumcast", LimbType.Head))
						* NT.Deltatime
			end
		end,
	},
	tla_amputation = {},
	tra_amputation = {},
	tll_amputation = {},
	trl_amputation = {},
	sla_amputation = {},
	sra_amputation = {},
	sll_amputation = {},
	srl_amputation = {},
	t_paralysis = {},
	alv = {}, -- artificial ventilation
	needlec = {
		update = function(c, i)
			c.afflictions[i].strength = c.afflictions[i].strength - 0.15 * NT.Deltatime
		end,
	},
	forceprone = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and c.afflictions.sym_unconsciousness.strength <= 0
					and not c.character.IsClimbing
					and (
						NTC.GetSymptom(c.character, i)
						or (c.stats.lockleftleg and c.stats.lockrightleg and not c.stats.wheelchaired)
					),
				2
			)
		end,
	},
	onwheelchair = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and c.afflictions.sym_unconsciousness.strength <= 0
					and (NTC.GetSymptom(c.character, i) or c.stats.wheelchaired),
				2
			)
		end,
	},

	-- Organ conditions
	cardiacarrest = {
		update = function(c, i)
			-- triggers
			if
				not NTC.GetSymptomFalse(c.character, "triggersym_cardiacarrest")
				and (
					NTC.GetSymptom(c.character, "triggersym_cardiacarrest")
					or c.stats.stasis
					or c.afflictions.heartremoved.strength > 0
					or c.afflictions.brainremoved.strength > 0
					or (c.afflictions.heartdamage.strength > 99 and HF.Chance(0.3))
					or (c.afflictions.traumaticshock.strength > 40 and HF.Chance(0.1))
					or (c.afflictions.coma.strength > 40 and HF.Chance(0.03))
					or (c.afflictions.hypoxemia.strength > 80 and HF.Chance(0.01))
					or (
						c.afflictions.fibrillation.strength > 20
						and HF.Chance((c.afflictions.fibrillation.strength / 100) ^ 4)
					)
				)
			then
				c.afflictions[i].strength = c.afflictions[i].strength + 10
			end
		end,
	},
	respiratoryarrest = {
		update = function(c, i)
			-- passive regen
			c.afflictions[i].strength = c.afflictions[i].strength
				- (0.05 + HF.BoolToNum(c.afflictions.sym_unconsciousness.strength < 0.1, 0.45)) * NT.Deltatime
			-- triggers
			if
				not NTC.GetSymptomFalse(c.character, "triggersym_respiratoryarrest")
				and (
					NTC.GetSymptom(c.character, "triggersym_respiratoryarrest")
					or c.stats.stasis
					or c.afflictions.lungremoved.strength > 0
					or c.afflictions.brainremoved.strength > 0
					or c.afflictions.opiateoverdose.strength > 60
					or (c.afflictions.lungdamage.strength > 99 and HF.Chance(0.8))
					or (c.afflictions.traumaticshock.strength > 30 and HF.Chance(0.2))
					or (
						(c.afflictions.cerebralhypoxia.strength > 100 or c.afflictions.hypoxemia.strength > 70)
						and HF.Chance(0.05)
					)
				)
			then
				c.afflictions[i].strength = c.afflictions[i].strength + 10
			end
		end,
	},
	pneumothorax = {
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				c.afflictions[i].strength = HF.Clamp(
					c.afflictions[i].strength
						+ NT.Deltatime
							* (
								0.5 -- gain 0.5/s
								- HF.BoolToNum(c.afflictions[i].strength > 15)
									* HF.Clamp(c.afflictions.needlec.strength, 0, 1)
							), -- ...except if needled and >15%, then lose 0.5/s
					0,
					100
				)
			end
		end,
	},
	tamponade = {
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				c.afflictions[i].strength = c.afflictions[i].strength + NT.Deltatime * 0.5
			end

			if c.afflictions.heartremoved.strength > 0 then
				c.afflictions[i].strength = 0
			end
		end,
	},
	heartattack = {
		update = function(c, i)
			c.afflictions[i].strength = c.afflictions[i].strength - NT.Deltatime

			-- triggers
			if
				not NTC.GetSymptomFalse(c.character, "triggersym_heartattack")
				and not c.stats.stasis
				and c.afflictions.afstreptokinase.strength <= 0
				and c.afflictions.heartremoved.strength <= 0
				and (
					NTC.GetSymptom(c.character, "triggersym_heartattack")
					or (
						c.afflictions.bloodpressure.strength > 150
						and HF.Chance(
							NTConfig.Get("NT_heartattackChance", 1)
								* ((c.afflictions.bloodpressure.strength - 150) / 50 * 0.02)
						)
					)
				)
			then
				c.afflictions[i].strength = c.afflictions[i].strength + 50
			end

			if c.afflictions.heartremoved.strength > 0 then
				c.afflictions[i].strength = 0
			end
		end,
	},
	-- Organs removed
	brainremoved = {
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				c.afflictions[i].strength = 1
					+ HF.BoolToNum(HF.HasAfflictionLimb(c.character, "retractedskin", LimbType.Head, 99), 99)
			end
		end,
	},
	heartremoved = {
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				c.afflictions[i].strength = 1
					+ HF.BoolToNum(HF.HasAfflictionLimb(c.character, "retractedskin", LimbType.Torso, 99), 99)
			end
		end,
	},
	lungremoved = {
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				c.afflictions[i].strength = 1
					+ HF.BoolToNum(HF.HasAfflictionLimb(c.character, "retractedskin", LimbType.Torso, 99), 99)
			end
		end,
	},
	liverremoved = {
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				c.afflictions[i].strength = 1
					+ HF.BoolToNum(HF.HasAfflictionLimb(c.character, "retractedskin", LimbType.Torso, 99), 99)
			end
		end,
	},
	kidneyremoved = {
		update = function(c, i)
			if c.afflictions[i].strength > 0 then
				c.afflictions[i].strength = 1
					+ HF.BoolToNum(HF.HasAfflictionLimb(c.character, "retractedskin", LimbType.Torso, 99), 99)
			end
		end,
	},
	-- Organ damage
	cerebralhypoxia = {
		max = 200,
		update = function(c, i)
			if c.stats.stasis then
				return
			end
			-- calculate new neurotrauma
			local skull = HF.HasAffliction(c.character, "h_fracture", 1) -- check for skullfracture
			local skullmod = skull and 0 or 1 -- invert bool
			local gain = (
				-0.1 * c.stats.healingrate * skullmod -- passive regen and fractured skull
				+ c.afflictions.hypoxemia.strength / 100 -- from hypoxemia
				+ HF.Clamp(c.afflictions.stroke.strength, 0, 20) * 0.1 -- from stroke
				+ c.afflictions.sepsis.strength / 100 * 0.4 -- from sepsis
				+ c.afflictions.liverdamage.strength / 800 -- from liverdamage
				+ c.afflictions.kidneydamage.strength / 1000 -- from kidneydamage
				+ c.afflictions.traumaticshock.strength / 100 -- from traumatic shock
			) * NT.Deltatime

			if gain > 0 then
				gain = gain
					* NTC.GetMultiplier(c.character, "neurotraumagain") -- NTC multiplier
					* NTConfig.Get("NT_neurotraumaGain", 1) -- Config multiplier
					* (1 - HF.Clamp(c.afflictions.afmannitol.strength, 0, 0.5)) -- half if mannitol
			end

			c.afflictions[i].strength = c.afflictions[i].strength + gain

			c.afflictions[i].strength = HF.Clamp(c.afflictions[i].strength, 0, 200)
		end,
	},
	heartdamage = {
		update = function(c, i)
			if c.stats.stasis then
				return
			end
			c.afflictions[i].strength = NT.organDamageCalc(
				c,
				c.afflictions[i].strength
					+ NTC.GetMultiplier(c.character, "heartdamagegain")
						* (c.stats.neworgandamage + HF.Clamp(c.afflictions.heartattack.strength, 0, 0.5) * NT.Deltatime)
			)
		end,
	},
	lungdamage = {
		update = function(c, i)
			if c.stats.stasis then
				return
			end
			c.afflictions[i].strength = NT.organDamageCalc(
				c,
				c.afflictions.lungdamage.strength
					+ NTC.GetMultiplier(c.character, "lungdamagegain")
						* (c.stats.neworgandamage + math.max(c.afflictions.radiationsickness.strength - 25, 0) / 800 * NT.Deltatime)
			)
		end,
	},
	liverdamage = {
		update = function(c, i)
			if c.stats.stasis then
				return
			end
			c.afflictions[i].strength = NT.organDamageCalc(
				c,
				c.afflictions.liverdamage.strength
					+ NTC.GetMultiplier(c.character, "liverdamagegain") * c.stats.neworgandamage
			)
			if
				c.afflictions[i].strength >= 99
				and not NTC.GetSymptom(c.character, "sym_hematemesis")
				and HF.Chance(0.05)
			then
				-- if liver failed: 5% chance for 6-20 seconds of blood vomiting and internal bleeding
				NTC.SetSymptomTrue(c.character, "sym_hematemesis", math.random(3, 10))
				c.afflictions.internalbleeding.strength = c.afflictions.internalbleeding.strength + 2
			end
		end,
	},
	kidneydamage = {
		update = function(c, i)
			if c.stats.stasis then
				return
			end
			c.afflictions[i].strength = kidneyDamageCalc(
				c,
				c.afflictions.kidneydamage.strength
					+ NTC.GetMultiplier(c.character, "kidneydamagegain")
						* (c.stats.neworgandamage + HF.Clamp((c.afflictions.bloodpressure.strength - 120) / 160, 0, 0.5) * NT.Deltatime * 0.5)
			)
			if
				c.afflictions[i].strength >= 60
				and not NTC.GetSymptom(c.character, "sym_vomiting")
				and HF.Chance((c.afflictions[i].strength - 60) / 40 * 0.07)
			then
				-- at 60% kidney damage: 0% chance for vomiting
				-- at 100% kidney damage: 7% chance for vomiting
				NTC.SetSymptomTrue(c.character, "sym_vomiting", math.random(3, 10))
			end
		end,
	},
	bonedamage = {
		update = function(c, i)
			if c.stats.stasis then
				return
			end
			c.afflictions[i].strength = NT.organDamageCalc(
				c,
				c.afflictions.bonedamage.strength
					+ NTC.GetMultiplier(c.character, "bonedamagegain")
						* (c.afflictions.sepsis.strength / 500 + c.afflictions.hypoxemia.strength / 1000 + math.max(
							c.afflictions.radiationsickness.strength - 25,
							0
						) / 600)
						* NT.Deltatime
			)
			if c.afflictions[i].strength < 90 then
				c.afflictions[i].strength = c.afflictions[i].strength - (c.stats.bonegrowthCount * 0.3) * NT.Deltatime
			elseif c.stats.bonegrowthCount >= 6 then
				c.afflictions[i].strength = c.afflictions[i].strength - 2 * NT.Deltatime
			end
			if c.afflictions.kidneydamage.strength > 70 then
				c.afflictions[i].strength = c.afflictions[i].strength
					+ (c.afflictions.kidneydamage.strength - 70) / 30 * 0.15 * NT.Deltatime
			end
		end,
	},
	organdamage = {
		max = 200,
		update = function(c, i)
			if c.stats.stasis then
				return
			end
			c.afflictions[i].strength =
				NT.organDamageCalc(c, c.afflictions.organdamage.strength + c.stats.neworgandamage, true)
		end,
	},
	-- Blood
	sepsis = {
		update = function(c, i)
			if c.afflictions.afantibiotics.strength > 0.1 then
				c.afflictions[i].strength = c.afflictions[i].strength - NT.Deltatime
			end
			if c.stats.stasis then
				return
			end
			if c.afflictions[i].strength > 0.1 then
				c.afflictions[i].strength = c.afflictions[i].strength + 0.05 * NT.Deltatime
			end
		end,
	},
	immunity = {
		default = -1,
		min = 5,
		update = function(c, i)
			if c.afflictions[i].strength == -1 then
				-- no immunity affliction!
				-- assume it has been wiped by "revive" or "heal all", attempt to assign new blood type
				if NT.HasBloodtype(c.character) then
					-- if blood type is already here, set immunity to the minimum
					c.afflictions[i].strength = 5
				else
					-- no bloodtype -> all afflictions have been cleared, set immunity to maximum
					c.afflictions[i].strength = 100
					NT.TryRandomizeBlood(c.character)
				end
			end
			if c.stats.stasis then
				return
			end

			-- immunity regeneration
			c.afflictions[i].strength =
				HF.Clamp(c.afflictions[i].strength + (0.5 + c.afflictions[i].strength / 100) * NT.Deltatime, 5, 100)
		end,
	},
	bloodloss = { max = 200 },
	bloodpressure = {
		min = 5,
		max = 200,
		default = 100,
		update = function(c, i)
			-- fix people not having a blood pressure
			if not HF.HasAffliction(c.character, i) then
				HF.SetAffliction(c.character, i, 100)
			end

			if c.stats.stasis then
				return
			end
			-- calculate new blood pressure
			local desiredbloodpressure = (
				c.stats.bloodamount
				- c.afflictions.tamponade.strength / 2 -- -50 if full tamponade
				- HF.Clamp(c.afflictions.afpressuredrug.strength * 5, 0, 45) -- -45 if blood pressure medication
				- HF.Clamp(c.afflictions.anesthesia.strength, 0, 15) -- -15 if propofol (fuck propofol)
				+ HF.Clamp(c.afflictions.afadrenaline.strength * 10, 0, 30) -- +30 if adrenaline
				+ HF.Clamp(c.afflictions.afsaline.strength * 5, 0, 30) -- +30 if saline
				+ HF.Clamp(c.afflictions.afringerssolution.strength * 5, 0, 30) -- +30 if ringers
			)
				* (1 + 0.5 * ((c.afflictions.liverdamage.strength / 100) ^ 2)) -- elevated if full liver damage
				* (1 + 0.5 * ((c.afflictions.kidneydamage.strength / 100) ^ 2)) -- elevated if full kidney damage
				* (1 + c.afflictions.alcoholwithdrawal.strength / 200) -- elevated if alcohol withdrawal
				* HF.Clamp((100 - c.afflictions.traumaticshock.strength * 2) / 100, 0, 1) -- none if half or more traumatic shock
				* ((100 - c.afflictions.fibrillation.strength) / 100) -- lowered if fibrillated
				* (1 - math.min(1, c.afflictions.cardiacarrest.strength)) -- none if cardiac arrest
				* NTC.GetMultiplier(c.character, "bloodpressure")

			local bloodpressurelerp = 0.2 * NTC.GetMultiplier(c.character, "bloodpressurerate")
			-- adjust three times slower to heightened blood pressure
			if desiredbloodpressure > c.afflictions.bloodpressure.strength then
				bloodpressurelerp = bloodpressurelerp / 3
			end
			c.afflictions.bloodpressure.strength = HF.Clamp(
				HF.Round(HF.Lerp(c.afflictions.bloodpressure.strength, desiredbloodpressure, bloodpressurelerp), 2),
				5,
				200
			)
		end,
	},
	hypoxemia = {
		update = function(c, i)
			if c.stats.stasis then
				return
			end
			-- completely cancel out hypoxemia regeneration if penumothorax is full
			c.stats.availableoxygen = math.min(c.stats.availableoxygen, 100 - c.afflictions.pneumothorax.strength / 2)

			local hypoxemiagain = NTC.GetMultiplier(c.character, "hypoxemiagain")
			local regularHypoxemiaChange = (-c.stats.availableoxygen + 50) / 8
			if regularHypoxemiaChange > 0 then
				-- not enough oxygen, increase hypoxemia
				regularHypoxemiaChange = regularHypoxemiaChange * hypoxemiagain
			else
				-- enough oxygen, decrease hypoxemia
				regularHypoxemiaChange =
					HF.Lerp(regularHypoxemiaChange * 2, 0, HF.Clamp((50 - c.stats.bloodamount) / 50, 0, 1))
			end
			c.afflictions.hypoxemia.strength = HF.Clamp(
				c.afflictions.hypoxemia.strength
					+ (
							-math.min(0, (c.afflictions.bloodpressure.strength - 70) / 7) * hypoxemiagain -- loss because of low blood pressure (+10 at 0 bp)
							- math.min(0, (c.stats.bloodamount - 60) / 4) * hypoxemiagain -- loss because of low blood amount (+15 at 0 blood)
							+ regularHypoxemiaChange -- change because of oxygen in lungs (+6.25 <> -12.5)
						)
						* NT.Deltatime,
				0,
				100
			)
		end,
	},
	hemotransfusionshock = {},
	tshocktimeout = {},
	-- Other
	oxygenlow = {
		max = 200,
		update = function(c, i)
			-- respiratory arrest? -> oxygen in lungs rapidly decreases
			if c.afflictions.respiratoryarrest.strength > 0 then
				c.afflictions.oxygenlow.strength = c.afflictions.oxygenlow.strength + 15 * NT.Deltatime
			end
		end,
	},
	radiationsickness = {
		max = 200,
		update = function(c, i)
			c.afflictions[i].strength = c.afflictions[i].strength - NT.Deltatime * 0.02
		end,
	},
	stasis = {},
	table = {},
	internalbleeding = {
		update = function(c, i)
			if c.stats.stasis then
				return
			end
			c.afflictions[i].strength = c.afflictions[i].strength - NT.Deltatime * 0.02 * c.stats.clottingrate
			if c.afflictions[i].strength > 0 then
				c.afflictions.bloodloss.strength = c.afflictions.bloodloss.strength
					+ c.afflictions[i].strength * (1 / 40) * NT.Deltatime
			end
		end,
	},
	acidosis = {
		update = function(c, i)
			if c.stats.stasis then
				return
			end
			c.afflictions[i].strength = c.afflictions[i].strength
				+ HF.BoolToNum(c.afflictions.hypoventilation.strength > 0 and c.afflictions.alv.strength <= 0.1) * 0.09 * NT.Deltatime
				+ HF.BoolToNum(
					(
						c.afflictions.cardiacarrest.strength
						+ c.afflictions.respiratoryarrest.strength * HF.BoolToNum(c.afflictions.alv.strength <= 0.1)
					) > 0
				) * 0.18 * NT.Deltatime
				+ math.max(0, c.afflictions.kidneydamage.strength - 80) / 20 * 0.1 * NT.Deltatime
				- NT.Deltatime * 0.03
		end,
	},
	alkalosis = {
		update = function(c, i)
			if not c.stats.stasis then
				c.afflictions[i].strength = c.afflictions[i].strength
					- NT.Deltatime * 0.03
					+ HF.Clamp(c.afflictions.hyperventilation.strength, 0, 1) * 0.09 * NT.Deltatime
					+ HF.Clamp(c.afflictions.sym_vomiting.strength, 0, 1) * 0.1 * NT.Deltatime
					+ HF.Clamp(HF.GetAfflictionStrength(c.character, "nausea", 0), 0, 1) * 0.1 * NT.Deltatime
			end
			if c.afflictions.acidosis.strength > 1 and c.afflictions.alkalosis.strength > 1 then
				local min = math.min(c.afflictions.acidosis.strength, c.afflictions.alkalosis.strength)
				c.afflictions.acidosis.strength = c.afflictions.acidosis.strength - min
				c.afflictions.alkalosis.strength = c.afflictions.alkalosis.strength - min
			end
		end,
	},
	seizure = {
		update = function(c, i)
			c.afflictions[i].strength = c.afflictions[i].strength - NT.Deltatime

			-- triggers
			if
				not NTC.GetSymptomFalse(c.character, "triggersym_seizure")
				and not c.stats.stasis
				and (
					NTC.GetSymptom(c.character, "triggersym_seizure")
					or (c.afflictions.stroke.strength > 1 and HF.Chance(0.05))
					or (c.afflictions.acidosis.strength > 60 and HF.Chance(0.05))
					or (c.afflictions.alkalosis.strength > 60 and HF.Chance(0.05))
					or HF.Chance(HF.Minimum(c.afflictions.radiationsickness.strength, 50, 0) / 200 * 0.1)
					or (c.afflictions.alcoholwithdrawal.strength > 50 and HF.Chance(
						c.afflictions.alcoholwithdrawal.strength / 1000
					))
					or (
						c.afflictions.opiateoverdose.strength > 60
						and HF.Chance(c.afflictions.opiateoverdose.strength / 500)
					)
				)
			then
				c.afflictions[i].strength = c.afflictions[i].strength + 10
			end

			-- check for spasm trigger
			if c.afflictions[i].strength > 0.1 then
				for type in limbtypes do
					if HF.Chance(0.5) then
						HF.AddAfflictionLimb(c.character, "spasm", type, 10)
					end
				end
			end
		end,
	},
	stroke = {
		update = function(c, i)
			if c.stats.stasis then
				return
			end
			c.afflictions[i].strength = c.afflictions[i].strength - (1 / 20) * c.stats.clottingrate * NT.Deltatime

			-- triggers
			if
				not NTC.GetSymptomFalse(c.character, "triggersym_stroke")
				and not c.stats.stasis
				and (
					NTC.GetSymptom(c.character, "triggersym_stroke")
					or (
						c.afflictions.bloodpressure.strength > 150
						and HF.Chance(
							NTConfig.Get("NT_strokeChance", 1)
								* (
									(c.afflictions.bloodpressure.strength - 150) / 50 * 0.02
									+ HF.Clamp(c.afflictions.afstreptokinase.strength, 0, 1) * 0.05
								)
						)
					)
				)
			then
				c.afflictions[i].strength = c.afflictions[i].strength + 5
			end
		end,
	},
	coma = {
		update = function(c, i)
			if c.stats.stasis then
				return
			end
			c.afflictions[i].strength = c.afflictions[i].strength - NT.Deltatime / 5

			-- triggers
			if
				not NTC.GetSymptomFalse(c.character, "triggersym_coma")
				and not c.stats.stasis
				and (
					NTC.GetSymptom(c.character, "triggersym_coma")
					or (c.afflictions.cardiacarrest.strength > 1 and HF.Chance(0.05))
					or (c.afflictions.stroke.strength > 1 and HF.Chance(0.05))
					or (
						c.afflictions.acidosis.strength > 60
						and HF.Chance(0.05 + (c.afflictions.acidosis.strength - 60) / 100)
					)
				)
			then
				c.afflictions[i].strength = c.afflictions[i].strength + 14
			end
		end,
	},
	stun = {
		max = 30,
		update = function(c, i)
			if
				c.afflictions.t_paralysis.strength > 0
				or c.afflictions.anesthesia.strength > 15
				or c.afflictions.sym_unconsciousness.strength > 0
			then
				c.afflictions[i].strength = math.max(5, c.afflictions[i].strength)
			end
		end,
		apply = function(c, i, newval)
			-- using the character stun property to apply instead of an affliction so that the networking doesnt shit itself (hopefully)
			c.character.Stun = newval
		end,
	},
	slowdown = {
		lateupdate = function(c, i)
			c.afflictions[i].strength = HF.Clamp(100 * (1 - c.stats.speedmultiplier), 0, 100)
		end,
	},
	givein = {
		max = 1,
		update = function(c, i)
			c.afflictions[i].strength =
				HF.BoolToNum(c.afflictions.t_paralysis.strength > 0 or c.afflictions.sym_unconsciousness.strength > 0)
		end,
	},
	lockedhands = {
		update = function(c, i)
			-- arm locking
			local leftlockitem = c.character.Inventory.FindItemByIdentifier("armlock2", false)
			local rightlockitem = c.character.Inventory.FindItemByIdentifier("armlock1", false)

			-- handcuffs
			local handcuffs = c.character.Inventory.FindItemByIdentifier("handcuffs", false)
			local handcuffed = handcuffs ~= nil and c.character.Inventory.FindIndex(handcuffs) <= 6
			if handcuffed then
				-- drop non-handcuff items
				local leftHandItem = HF.GetItemInLeftHand(c.character)
				local rightHandItem = HF.GetItemInRightHand(c.character)
				if leftHandItem ~= nil and leftHandItem ~= handcuffs and leftlockitem == nil then
					leftHandItem.Drop(c.character)
				end
				if rightHandItem ~= nil and rightHandItem ~= handcuffs and rightlockitem == nil then
					rightHandItem.Drop(c.character)
				end
			end

			local leftarmlocked = leftlockitem ~= nil and not handcuffed
			local rightarmlocked = rightlockitem ~= nil and not handcuffed

			if leftarmlocked and not c.stats.lockleftarm then
				HF.RemoveItem(leftlockitem)
			end
			if rightarmlocked and not c.stats.lockrightarm then
				HF.RemoveItem(rightlockitem)
			end

			if not leftarmlocked and c.stats.lockleftarm then
				HF.ForceArmLock(c.character, "armlock2")
			end
			if not rightarmlocked and c.stats.lockrightarm then
				HF.ForceArmLock(c.character, "armlock1")
			end

			c.afflictions[i].strength = HF.BoolToNum((c.stats.lockleftarm and c.stats.lockrightarm) or handcuffed, 100)
		end,
	},
	traumaticshock = {
		update = function(c, i)
			if c.afflictions.tshocktimeout.strength > 0 then
				c.afflictions[i].strength = 0
				return
			end
			local shouldReduce = (c.stats.sedated and c.afflictions.table.strength > 0)
				or c.afflictions.anesthesia.strength > 15
			c.afflictions[i].strength = c.afflictions[i].strength
				- (0.5 + HF.BoolToNum(shouldReduce, 1.5)) * NT.Deltatime

			if c.afflictions[i].strength > 5 and c.afflictions.sym_unconsciousness.strength < 0.1 then
				HF.AddAffliction(c.character, "shockpain", 10 * NT.Deltatime)
				HF.AddAffliction(c.character, "psychosis", c.afflictions[i].strength / 100 * NT.Deltatime)
			end
		end,
	},
	alcoholwithdrawal = {},
	opiatewithdrawal = {},
	chemwithdrawal = {},
	opiateoverdose = {},
	-- Drugs
	analgesia = { max = 200 },

	-- propofol (i hate it)
	anesthesia = {
		update = function(c, i)
			if c.afflictions[i].strength <= 0 then
				return
			end
			-- cause bloody vomiting or hallucinations sometimes (real sideeffects of propofol!)
			if HF.Chance(0.06) then
				local case = math.random()
				local casecount = 7

				if case < 1 / casecount then
					NTC.SetSymptomTrue(c.character, "sym_hematemesis", 5 + math.random() * 10)
				elseif case < 2 / casecount then
					NTC.SetSymptomTrue(c.character, "sym_blurredvision", 5 + math.random() * 10)
				elseif case < 3 / casecount then
					NTC.SetSymptomTrue(c.character, "sym_confusion", 5 + math.random() * 10)
				elseif case < 4 / casecount then
					NTC.SetSymptomTrue(c.character, "sym_fever", 5 + math.random() * 10)
				elseif case < 5 / casecount then
					NTC.SetSymptomTrue(c.character, "triggersym_seizure", 1 + math.random() * 2)
				elseif case < 6 / casecount then
					NT.Fibrillate(c.character, 5 + math.random() * 30)
				else
					HF.AddAffliction(c.character, "psychosis", 10)
				end
			end
		end,
	},
	drunk = { max = 200 },
	afadrenaline = {},
	afantibiotics = {},
	afthiamine = {},
	afsaline = {},
	afringerssolution = {},
	afstreptokinase = {},
	afmannitol = {},
	afpressuredrug = {
		update = function(c, i)
			c.afflictions[i].strength = c.afflictions[i].strength - 0.25 * NT.Deltatime
		end,
	},
	concussion = {
		update = function(c, i)
			c.afflictions[i].strength = c.afflictions[i].strength - 0.01 * NT.Deltatime
			if c.afflictions[i].strength <= 0 then
				return
			end

			-- cause headaches, blurred vision, nausea, confusion
			if HF.Chance(HF.Clamp(c.afflictions[i].strength / 10 * 0.08, 0.02, 0.08)) then
				local case = math.random()

				if case < 0.25 then
					NTC.SetSymptomTrue(c.character, "sym_nausea", 5 + math.random() * 10)
				elseif case < 0.5 then
					NTC.SetSymptomTrue(c.character, "sym_blurredvision", 5 + math.random() * 9)
				elseif case < 0.75 then
					NTC.SetSymptomTrue(c.character, "sym_headache", 6 + math.random() * 8)
				else
					NTC.SetSymptomTrue(c.character, "sym_confusion", 6 + math.random() * 8)
				end
			end
		end,
	},

	-- /// Symptoms ///
	--==============================================================================
	sym_unconsciousness = {
		update = function(c, i)
			local isUnconscious = not NTC.GetSymptomFalse(c.character, i)
				and (
					NTC.GetSymptom(c.character, i)
					or c.stats.stasis
					or c.afflictions.brainremoved.strength > 0
					or (not HF.HasAffliction(c.character, "implacable", 0.05) and (c.character.Vitality <= 0 or c.afflictions.hypoxemia.strength > 80))
					or c.afflictions.cerebralhypoxia.strength > 100
					or c.afflictions.coma.strength > 15
					or c.afflictions.t_arterialcut.strength > 0
					or c.afflictions.seizure.strength > 0.1
					or c.afflictions.opiateoverdose.strength > 60
				)
			c.afflictions[i].strength = HF.BoolToNum(isUnconscious, 2)
		end,
	},
	tachycardia = {
		update = function(c, i)
			-- harmless symptom (doesnt lead to fibrillation)
			local hasSymHarmless = not NTC.GetSymptomFalse(c.character, i)
				and c.afflictions.cardiacarrest.strength < 1
				and c.afflictions.heartremoved.strength < 1
				and (
					NTC.GetSymptom(c.character, i)
					or c.afflictions.sepsis.strength > 20
					or c.stats.bloodamount < 60
					or c.afflictions.acidosis.strength > 20
					or c.afflictions.pneumothorax.strength > 30
					or c.afflictions.afadrenaline.strength > 1
					or c.afflictions.alcoholwithdrawal.strength > 75
				)
			c.afflictions[i].strength = math.max(c.afflictions[i].strength, HF.BoolToNum(hasSymHarmless, 2))

			-- harmful symptom (leads to fibrillation and cardiac arrest)
			local fibrillationSpeed = -0.1
				+ HF.Clamp(c.afflictions.t_arterialcut.strength, 0, 2) -- aortic rupture (very fast)
				+ HF.Clamp(c.afflictions.acidosis.strength / 200, 0, 0.5) -- acidosis (slow)
				+ HF.Clamp(
						0.9
							- ( -- low blood pressure (varies)
								(
									c.afflictions.bloodpressure.strength
									+ HF.Clamp(c.afflictions.afpressuredrug.strength * 5, 0, 20) -- less fibrillation from low blood pressure if blood pressure reducing medicines active
								) / 90
							),
						0,
						1
					)
					* 2
				+ HF.Clamp(c.afflictions.hypoxemia.strength / 100, 0, 1) * 1.5 -- hypoxemia (varies)
				+ HF.Clamp((c.afflictions.traumaticshock.strength - 5) / 40, 0, 3) -- traumatic shock (fast)
				- HF.Clamp(c.afflictions.afadrenaline.strength, 0, 0.9) -- faster defib if adrenaline

			if fibrillationSpeed > 0 and c.afflictions.afadrenaline.strength > 0 then
				-- if adrenaline, fibrillate half as fast
				fibrillationSpeed = fibrillationSpeed / 2
			end

			if c.afflictions.cardiacarrest.strength > 0 or c.afflictions.heartremoved.strength > 0 then
				fibrillationSpeed = -1000
				c.afflictions.fibrillation.strength = 0
				c.afflictions[i].strength = 0
			end

			-- fibrillation multiplier
			if fibrillationSpeed > 0 then
				fibrillationSpeed = fibrillationSpeed
					* NTC.GetMultiplier(c.character, "fibrillation")
					* NTConfig.Get("NT_fibrillationSpeed", 1)
			end

			if c.afflictions.fibrillation.strength <= 0 then -- havent reached fibrillation yet
				c.afflictions[i].strength = c.afflictions[i].strength + fibrillationSpeed * 5 * NT.Deltatime
				-- we reached max tachycardia, switch over to fibrillation
				if c.afflictions[i].strength >= 100 then
					c.afflictions.fibrillation.strength = 5
					c.afflictions[i].strength = 0
				end
			else -- have reached fibrillation
				c.afflictions[i].strength = 0 -- set tachycardia to 0
				c.afflictions.fibrillation.strength = c.afflictions.fibrillation.strength
					+ fibrillationSpeed * NT.Deltatime
			end
		end,
	},
	fibrillation = {
		update = function(c, i)
			-- see above for vfib accumulation logic
			if
				NTC.GetSymptomFalse(c.character, i)
				or c.afflictions.cardiacarrest.strength >= 1
				or c.afflictions.heartremoved.strength >= 1
			then
				c.afflictions[i].strength = 0
			end
		end,
	},
	hyperventilation = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and c.afflictions.respiratoryarrest.strength < 1
					and (
						NTC.GetSymptom(c.character, i)
						or c.afflictions.hypoxemia.strength > 10
						or c.afflictions.bloodpressure.strength < 80
						or c.afflictions.afadrenaline.strength > 1
						or c.afflictions.pneumothorax.strength > 15
						or c.afflictions.sepsis.strength > 15
					),
				2
			)
		end,
	},
	hypoventilation = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and c.afflictions.respiratoryarrest.strength < 1
					and (
						NTC.GetSymptom(c.character, i)
						or c.afflictions.analgesia.strength > 20
						or c.afflictions.anesthesia.strength > 40
						or c.afflictions.opiateoverdose.strength > 30
					),
				2
			)
			if c.afflictions.hyperventilation.strength > 0 and c.afflictions.hypoventilation.strength > 0 then
				c.afflictions.hyperventilation.strength = 0
				c.afflictions.hypoventilation.strength = 0
			end
		end,
	},
	dyspnea = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and c.afflictions.respiratoryarrest.strength <= 0
					and (
						NTC.GetSymptom(c.character, i)
						or c.afflictions.heartattack.strength > 1
						or c.afflictions.heartdamage.strength > 80
						or c.afflictions.hypoxemia.strength > 20
						or c.afflictions.lungdamage.strength > 45
						or c.afflictions.pneumothorax.strength > 40
						or c.afflictions.tamponade.strength > 10
						or (
							c.afflictions.hemotransfusionshock.strength > 0
							and c.afflictions.hemotransfusionshock.strength < 70
						)
					),
				2
			)
		end,
	},
	sym_cough = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and c.afflictions.sym_unconsciousness.strength <= 0
					and c.afflictions.lungremoved.strength <= 0
					and (
						NTC.GetSymptom(c.character, i)
						or c.afflictions.lungdamage.strength > 50
						or c.afflictions.heartdamage.strength > 50
						or c.afflictions.tamponade.strength > 20
					),
				2
			)
		end,
	},
	sym_paleskin = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and (
						NTC.GetSymptom(c.character, i)
						or c.stats.bloodamount < 60
						or c.afflictions.bloodpressure.strength < 50
					),
				2
			)
		end,
	},
	sym_lightheadedness = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and c.afflictions.sym_unconsciousness.strength <= 0
					and (NTC.GetSymptom(c.character, i) or c.afflictions.bloodpressure.strength < 60),
				2
			)
		end,
	},
	sym_blurredvision = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and c.afflictions.sym_unconsciousness.strength <= 0
					and (NTC.GetSymptom(c.character, i) or c.afflictions.bloodpressure.strength < 55),
				2
			)
		end,
	},
	sym_confusion = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and c.afflictions.sym_unconsciousness.strength <= 0
					and (
						NTC.GetSymptom(c.character, i)
						or c.afflictions.acidosis.strength > 15
						or c.afflictions.bloodpressure.strength < 30
						or c.afflictions.hypoxemia.strength > 50
						or c.afflictions.sepsis.strength > 40
						or c.afflictions.alcoholwithdrawal.strength > 80
					),
				2
			)
		end,
	},
	sym_headache = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and c.afflictions.sym_unconsciousness.strength <= 0
					and not c.stats.sedated
					and (
						NTC.GetSymptom(c.character, i)
						or c.stats.bloodamount < 50
						or c.afflictions.acidosis.strength > 20
						or c.afflictions.stroke.strength > 1
						or c.afflictions.hypoxemia.strength > 40
						or c.afflictions.bloodpressure.strength < 60
						or c.afflictions.alcoholwithdrawal.strength > 50
						or c.afflictions.h_fracture.strength > 0
					),
				2
			)
		end,
	},
	sym_legswelling = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and HF.GetAfflictionStrength(c.character, "rl_cyber", 0) < 0.1
					and (
						NTC.GetSymptom(c.character, i)
						or c.afflictions.liverdamage.strength > 40
						or c.afflictions.kidneydamage.strength > 60
						or c.afflictions.heartdamage.strength > 80
					),
				2
			)
		end,
	},
	sym_weakness = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and (
						NTC.GetSymptom(c.character, i)
						or c.afflictions.tamponade.strength > 30
						or c.stats.bloodamount < 40
						or c.afflictions.acidosis.strength > 35
					),
				2
			)
		end,
	},
	sym_wheezing = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and c.afflictions.respiratoryarrest.strength <= 0
					and (
						NTC.GetSymptom(c.character, i)
						or (
							c.afflictions.hemotransfusionshock.strength > 0
							and c.afflictions.hemotransfusionshock.strength < 90
						)
					),
				2
			)
		end,
	},
	sym_vomiting = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and (
						NTC.GetSymptom(c.character, i)
						or c.afflictions.drunk.strength > 100
						or (c.afflictions.hemotransfusionshock.strength > 0 and c.afflictions.hemotransfusionshock.strength < 40)
						or c.afflictions.alcoholwithdrawal.strength > 60
					),
				2
			)
		end,
	},
	sym_nausea = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and (
						NTC.GetSymptom(c.character, i)
						or c.afflictions.kidneydamage.strength > 60
						or c.afflictions.radiationsickness.strength > 80
						or (c.afflictions.hemotransfusionshock.strength > 0 and c.afflictions.hemotransfusionshock.strength < 90)
						or c.stats.withdrawal > 40
					),
				2
			)
		end,
	},
	sym_hematemesis = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and (NTC.GetSymptom(c.character, i) or c.afflictions.internalbleeding.strength > 50),
				2
			)
		end,
	},
	fever = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and (
						NTC.GetSymptom(c.character, i)
						or c.afflictions.sepsis.strength > 5
						or c.afflictions.alcoholwithdrawal.strength > 90
					),
				2
			)
		end,
	},
	sym_abdomdiscomfort = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and c.afflictions.sym_unconsciousness.strength <= 0
					and (NTC.GetSymptom(c.character, i) or c.afflictions.liverdamage.strength > 65),
				2
			)
		end,
	},
	sym_bloating = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and (NTC.GetSymptom(c.character, i) or c.afflictions.liverdamage.strength > 50),
				2
			)
		end,
	},
	sym_jaundice = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and (NTC.GetSymptom(c.character, i) or c.afflictions.liverdamage.strength > 80),
				2
			)
		end,
	},
	sym_sweating = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and (
						NTC.GetSymptom(c.character, i)
						or c.afflictions.heartattack.strength > 1
						or c.stats.withdrawal > 30
					),
				2
			)
		end,
	},
	sym_palpitations = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and c.afflictions.cardiacarrest.strength <= 0
					and (NTC.GetSymptom(c.character, i) or c.afflictions.alkalosis.strength > 20),
				2
			)
		end,
	},
	sym_craving = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and c.afflictions.sym_unconsciousness.strength <= 0
					and (NTC.GetSymptom(c.character, i) or c.stats.withdrawal > 20),
				2
			)
		end,
	},
	pain_abdominal = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and c.afflictions.sym_unconsciousness.strength <= 0
					and not c.stats.sedated
					and (
						NTC.GetSymptom(c.character, i)
						or (c.afflictions.hemotransfusionshock.strength > 0 and c.afflictions.hemotransfusionshock.strength < 80)
						or c.afflictions.t_arterialcut.strength > 0
					),
				2
			)
		end,
	},
	pain_chest = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(
				not NTC.GetSymptomFalse(c.character, i)
					and c.afflictions.sym_unconsciousness.strength <= 0
					and (
						NTC.GetSymptom(c.character, i)
						or (c.afflictions.hemotransfusionshock.strength > 0 and c.afflictions.hemotransfusionshock.strength < 60)
						or c.afflictions.t_fracture.strength > 0
						or c.afflictions.t_arterialcut.strength > 0
					),
				2
			)
		end,
	},
	luabotomy = {
		update = function(c, i)
			c.afflictions[i].strength = 0.1
		end,
	},
	modconflict = {
		update = function(c, i)
			c.afflictions[i].strength = HF.BoolToNum(NT.modconflict, 1)
		end,
	},
	-- Heelge: this really does the same thing as vanilla burns, why does it even exists?
	--sym_scorched = {
	--	update = function(c, i)
	--		c.afflictions[i].strength = HF.BoolToNum(c.stats.burndamage > 500, 10)
	--	end,
	--},
}
-- define all the limb specific afflictions and their update functions
NT.LimbAfflictions = {
	bandaged = {
		update = function(c, limbaff, i)
			-- turning a bandage into a dirty bandage
			local wounddamage = limbaff.burn.strength
				+ limbaff.lacerations.strength
				+ limbaff.gunshotwound.strength
				+ limbaff.bitewounds.strength
				+ limbaff.explosiondamage.strength

			local bandageDirtifySpeed = 0.1 + HF.Clamp(wounddamage / 100, 0, 0.4) + limbaff.bleeding.strength / 20

			if limbaff[i].strength > 0 then
				limbaff[i].strength = limbaff[i].strength - bandageDirtifySpeed * NT.Deltatime
				if limbaff[i].strength <= 0 then
					-- transition to dirty bandage
					limbaff.dirtybandage.strength = math.max(limbaff.dirtybandage.strength, 1)
					limbaff[i].strength = 0
				end
			end
			if limbaff.dirtybandage.strength > 0 then
				limbaff.dirtybandage.strength = limbaff.dirtybandage.strength + bandageDirtifySpeed * NT.Deltatime
			end

			-- bandage slowdown
			if limbaff[i].strength > 0 or limbaff.dirtybandage.strength > 0 then
				c.stats.speedmultiplier = c.stats.speedmultiplier * 0.9
			end
		end,
	},
	dirtybandage = {}, -- for bandage dirtifaction logic see above
	iced = {
		update = function(c, limbaff, i, type)
			-- over time skin temperature goes up again
			if limbaff[i].strength > 0 then
				limbaff[i].strength = limbaff[i].strength - 1.7 * NT.Deltatime
			end
			-- iced effects
			if limbaff[i].strength > 0 then
				c.stats.speedmultiplier = c.stats.speedmultiplier * 0.95 -- 5% slow per limb
				if type == LimbType.Torso then
					c.afflictions.internalbleeding.strength = c.afflictions.internalbleeding.strength
						- 0.2 * NT.Deltatime
				end
			end
		end,
	},
	skinointmented = {
		update = function(c, limbaff, i, type)
			if limbaff[i].strength > 0 then
				limbaff[i].strength = limbaff[i].strength - 0.2 * NT.Deltatime
			end
		end,
	},
	gypsumcast = {
		update = function(c, limbaff, i, type)
			-- gypsum slowdown and fracture healing
			if limbaff[i].strength > 0 then
				if type == LimbType.LeftLeg or type == LimbType.RightLeg then
					c.stats.speedmultiplier = c.stats.speedmultiplier * 0.8
				end
				NT.BreakLimb(c.character, type, -(100 / 300) * NT.Deltatime)
			end
		end,
	},
	ointmented = {},
	bonegrowth = {
		update = function(c, limbaff, i, type)
			if limbaff[i].strength <= 0 then
				-- check for bone death fracture triggers
				if c.afflictions.bonedamage.strength > 90 and HF.Chance(0.01) then
					NT.BreakLimb(c.character, type)
				end
			end
		end,
	},
	arteriesclamp = {},
	-- damage
	bleeding = {
		update = function(c, limbaff, i)
			if limbaff[i].strength > 0 and math.abs(c.stats.clottingrate - 1) > 0.05 then
				limbaff[i].strength = limbaff[i].strength - (c.stats.clottingrate - 1) * 0.1 * NT.Deltatime
			end
		end,
	},
	burn = {
		max = 200,
		update = function(c, limbaff, i)
			if limbaff[i].strength < 50 then
				limbaff[i].strength = limbaff[i].strength
					- (
							c.afflictions.immunity.prev / 3000
							+ HF.Clamp(limbaff.bandaged.strength, 0, 1) * 0.1
							+ HF.Clamp(limbaff.skinointmented.strength, 0, 1) * 0.12
						)
						* c.stats.healingrate
						* NT.Deltatime
			end
		end,
	},
	acidburn = {
		max = 200,
		update = function(c, limbaff, i)
			-- convert acid burns to regular burns
			if limbaff[i].strength > 0 then
				limbaff.burn.strength = limbaff.burn.strength + limbaff[i].strength
				limbaff[i].strength = 0
			end
		end,
	},
	lacerations = {
		max = 200,
		update = function(c, limbaff, i)
			if limbaff[i].strength < 50 then
				limbaff[i].strength = limbaff[i].strength
					- (
							c.afflictions.immunity.prev / 3000
							+ HF.Clamp(limbaff.bandaged.strength, 0, 1) * 0.1
							+ HF.Clamp(limbaff.skinointmented.strength, 0, 1) * 0.12
						)
						* c.stats.healingrate
						* NT.Deltatime
			end
		end,
	},
	gunshotwound = {
		max = 200,
		update = function(c, limbaff, i)
			if limbaff[i].strength < 50 then
				limbaff[i].strength = limbaff[i].strength
					- (
							c.afflictions.immunity.prev / 3000
							+ HF.Clamp(limbaff.bandaged.strength, 0, 1) * 0.1
							+ HF.Clamp(limbaff.skinointmented.strength, 0, 1) * 0.12
						)
						* c.stats.healingrate
						* NT.Deltatime
			end
		end,
	},
	bitewounds = {
		max = 200,
		update = function(c, limbaff, i)
			if limbaff[i].strength < 100 then
				limbaff[i].strength = limbaff[i].strength
					- (
							c.afflictions.immunity.prev / 3000
							+ HF.Clamp(limbaff.bandaged.strength, 0, 1) * 0.1
							+ HF.Clamp(limbaff.skinointmented.strength, 0, 1) * 0.12
						)
						* c.stats.healingrate
						* NT.Deltatime
			end
		end,
	},
	explosiondamage = {
		max = 200,
		update = function(c, limbaff, i)
			if limbaff[i].strength < 50 then
				limbaff[i].strength = limbaff[i].strength
					- (
							c.afflictions.immunity.prev / 3000
							+ HF.Clamp(limbaff.bandaged.strength, 0, 1) * 0.1
							+ HF.Clamp(limbaff.skinointmented.strength, 0, 1) * 0.12
						)
						* c.stats.healingrate
						* NT.Deltatime
			end
		end,
	},
	blunttrauma = {
		max = 200,
		update = function(c, limbaff, i)
			if limbaff[i].strength < 100 then
				limbaff[i].strength = limbaff[i].strength
					- (
							c.afflictions.immunity.prev / 8000
							+ HF.Clamp(limbaff.bandaged.strength, 0, 1) * 0.1
							+ HF.Clamp(limbaff.iced.strength, 0, 1) * 0.3
							+ HF.Clamp(limbaff.skinointmented.strength, 0, 1) * 0.12
						)
						* c.stats.healingrate
						* NT.Deltatime
			end
		end,
	},
	internaldamage = {
		max = 200,
		update = function(c, limbaff, i, type)
			limbaff[i].strength = limbaff[i].strength
				+ (
						-HF.BoolToNum(limbaff[i].strength < 50, 0.05 * c.stats.healingrate)
						+ HF.BoolToNum(
							not c.stats.sedated
								and limbaff.gypsumcast.strength <= 0
								and (
									(
										NT.LimbIsBroken(c.character, type)
										and (
											HF.LimbIsExtremity(type)
											or (limbaff.bandaged.strength <= 0 and limbaff.dirtybandage.strength <= 0)
										)
									)
									or (
										NT.LimbIsDislocated(c.character, type)
										and limbaff.bandaged.strength <= 0
										and limbaff.dirtybandage.strength <= 0
									)
								),
							0.1
						)
					)
					* NT.Deltatime
		end,
	},
	-- other
	infectedwound = {
		update = function(c, limbaff, i)
			if c.stats.stasis then
				return
			end
			local infectindex = (
				-c.afflictions.immunity.prev / 200
				- HF.Clamp(limbaff.bandaged.strength, 0, 1) * 1.5
				- limbaff.ointmented.strength * 3
				+ limbaff.burn.strength / 20
				+ limbaff.lacerations.strength / 40
				+ limbaff.bitewounds.strength / 30
				+ limbaff.gunshotwound.strength / 40
				+ limbaff.explosiondamage.strength / 40
			) * NT.Deltatime

			local wounddamage = limbaff.burn.strength
				+ limbaff.lacerations.strength
				+ limbaff.gunshotwound.strength
				+ limbaff.bitewounds.strength
				+ limbaff.explosiondamage.strength

			-- open wounds and a dirty bandage? :grimacing:
			if limbaff.dirtybandage.strength > 10 and wounddamage > 5 then
				infectindex = infectindex + (wounddamage / 40 + limbaff.dirtybandage.strength / 20) * NT.Deltatime
			end

			if infectindex > 0 then
				infectindex = infectindex * NTConfig.Get("NT_infectionRate", 1) * HF.Clamp(limbaff.iced.strength, 1, 10)
			end

			limbaff[i].strength = limbaff[i].strength + infectindex / 5
			c.afflictions.immunity.strength = c.afflictions.immunity.strength - HF.Clamp(infectindex / 3, 0, 10)
		end,
	},
	foreignbody = {
		update = function(c, limbaff, i, type)
			if limbaff[i].strength < 15 then
				limbaff[i].strength = limbaff[i].strength - 0.05 * c.stats.healingrate * NT.Deltatime
			end

			-- check for arterial cut triggers and foreign body sepsis
			local foreignbodycutchance = ((HF.Minimum(limbaff[i].strength, 20) / 100) ^ 6) * 0.5
			if limbaff.bleeding.strength > 80 or HF.Chance(foreignbodycutchance) then
				NT.ArteryCutLimb(c.character, type)
			end

			-- sepsis
			local sepsischance = HF.Minimum(limbaff.gangrene.strength, 15, 0) / 400
				+ HF.Minimum(limbaff.infectedwound.strength, 50) / 1000
				+ foreignbodycutchance
			if HF.Chance(sepsischance) then
				c.afflictions.sepsis.strength = c.afflictions.sepsis.strength + NT.Deltatime
			end
		end,
	},
	gangrene = {
		update = function(c, limbaff, i, type)
			-- see foreignbody for sepsis chance
			if isExtremity(type) then
				-- surgical amputation prevents all gangrene on that stump
				if NT.LimbIsSurgicallyAmputated(c.character, type) then
					limbaff[i].strength = 0
					return
				end

				if limbaff[i].strength < 15 and limbaff[i].strength > 0 then
					limbaff[i].strength = limbaff[i].strength - 0.01 * c.stats.healingrate * NT.Deltatime
				end
				if c.afflictions.sepsis.strength > 5 then
					limbaff[i].strength = limbaff[i].strength
						+ HF.BoolToNum(HF.Chance(0.04), 0.5 + c.afflictions.sepsis.strength / 150)
							* NTConfig.Get("NT_gangrenespeed", 1)
							* NT.Deltatime
				end
				if limbaff.arteriesclamp.strength > 0 then
					limbaff[i].strength = limbaff[i].strength
						+ HF.BoolToNum(HF.Chance(0.1), 1) * 0.5 * NTConfig.Get("NT_gangrenespeed", 1) * NT.Deltatime
				end
			end
		end,
	},
	pain_extremity = {
		max = 10,
		update = function(c, limbaff, i, type)
			if c.afflictions.sym_unconsciousness.strength > 0 then
				limbaff[i].strength = 0
				return
			end
			limbaff[i].strength = limbaff[i].strength
				+ (
						-0.5
						+ HF.BoolToNum(
							type ~= LimbType.Torso
								and limbaff.gypsumcast.strength <= 0
								and (
									(
										NT.LimbIsBroken(c.character, type)
										and (
											HF.LimbIsExtremity(type)
											or (limbaff.bandaged.strength <= 0 and limbaff.dirtybandage.strength <= 0)
										)
									)
									or (
										NT.LimbIsDislocated(c.character, type)
										and limbaff.bandaged.strength <= 0
										and limbaff.dirtybandage.strength <= 0
									)
								),
							2
						)
						- HF.BoolToNum(c.stats.sedated, 100)
					)
					* NT.Deltatime
		end,
	},
	-- limb symptoms
	inflammation = {
		update = function(c, limbaff, i)
			limbaff[i].strength = limbaff[i].strength
				+ (
						-0.1
						+ HF.BoolToNum(limbaff.infectedwound.strength > 10 or limbaff.foreignbody.strength > 15, 0.15)
					)
					* NT.Deltatime
		end,
	},
	burn_deg1 = {
		update = function(c, limbaff, i)
			if limbaff.burn.strength < 1 or limbaff.burn.strength > 20 then
				limbaff[i].strength = 0
			else
				limbaff[i].strength = limbaff.burn.strength * 5
			end
		end,
	},
	burn_deg2 = {
		update = function(c, limbaff, i)
			if limbaff.burn.strength <= 20 or limbaff.burn.strength > 50 then
				limbaff[i].strength = 0
			else
				limbaff[i].strength = math.max(5, (limbaff.burn.strength - 20) / 30 * 100)
			end
		end,
	},
	burn_deg3 = {
		update = function(c, limbaff, i)
			if limbaff.burn.strength <= 50 then
				limbaff[i].strength = 0
			else
				limbaff[i].strength = HF.Clamp((limbaff.burn.strength - 50) / 50 * 100, 5, 100)
			end
		end,
	},
}
-- define the stats and multipliers
NT.CharStats = {
	healingrate = {
		getter = function(c)
			return NTC.GetMultiplier(c.character, "healingrate")
		end,
	},
	specificOrganDamageHealMultiplier = {
		getter = function(c)
			return NTC.GetMultiplier(c.character, "anyspecificorgandamage")
				+ HF.Clamp(c.afflictions.afthiamine.strength, 0, 1) * 4
		end,
	},
	neworgandamage = {
		getter = function(c)
			return (
				c.afflictions.sepsis.strength / 300
				+ c.afflictions.hypoxemia.strength / 400
				+ math.max(c.afflictions.radiationsickness.strength - 25, 0) / 400
			)
				* NTC.GetMultiplier(c.character, "anyorgandamage")
				* NTConfig.Get("NT_organDamageGain", 1)
				* NT.Deltatime
		end,
	},
	clottingrate = {
		getter = function(c)
			return HF.Clamp(1 - c.afflictions.liverdamage.strength / 100, 0, 1)
				* c.stats.healingrate
				* HF.Clamp(1 - c.afflictions.afstreptokinase.strength, 0, 1)
				* NTC.GetMultiplier(c.character, "clottingrate")
		end,
	},

	bloodamount = {
		getter = function(c)
			return HF.Clamp(100 - c.afflictions.bloodloss.strength, 0, 100)
		end,
	},
	stasis = {
		getter = function(c)
			return c.afflictions.stasis.strength > 0
		end,
	},
	sedated = {
		getter = function(c)
			return c.afflictions.analgesia.strength > 0
				or c.afflictions.anesthesia.strength > 10
				or c.afflictions.drunk.strength > 20
				or c.stats.stasis
		end,
	},
	withdrawal = {
		getter = function(c)
			return math.max(
				c.afflictions.opiatewithdrawal.strength,
				c.afflictions.chemwithdrawal.strength,
				c.afflictions.alcoholwithdrawal.strength
			)
		end,
	},
	availableoxygen = {
		getter = function(c)
			local res = HF.Clamp(c.character.Oxygen, 0, 100)
			-- heart isnt pumping blood? no new oxygen is getting into the bloodstream, no matter how oxygen rich the air in the lungs
			res = res * (1 - c.afflictions.fibrillation.strength / 100)
			-- and uuuh, maybe also dont let people without lungs use the oxygen where their lungs should be
			if c.afflictions.cardiacarrest.strength > 1 or c.afflictions.lungremoved.strength > 0.1 then
				res = 0
			end
			return res
		end,
	},
	speedmultiplier = {
		getter = function(c)
			local res = 1
			if c.afflictions.t_paralysis.strength > 0 then
				res = -9001
			end

			if c.afflictions.sym_vomiting.strength > 0 then
				res = res * 0.8
			end
			if c.afflictions.sym_nausea.strength > 0 then
				res = res * 0.9
			end
			if c.afflictions.anesthesia.strength > 0 then
				res = res * 0.5
			end
			if c.afflictions.opiateoverdose.strength > 50 then
				res = res * 0.5
			end

			if c.stats.withdrawal > 80 then
				res = res * 0.5
			elseif c.stats.withdrawal > 40 then
				res = res * 0.7
			elseif c.stats.withdrawal > 20 then
				res = res * 0.9
			end

			if c.afflictions.drunk.strength > 80 then
				res = res * 0.5
			elseif c.afflictions.drunk.strength > 40 then
				res = res * 0.7
			elseif c.afflictions.drunk.strength > 20 then
				res = res * 0.8
			end

			res = res + c.afflictions.afadrenaline.strength / 100 -- mitigate slowing effects if doped up on epinephrine

			res = res * NTC.GetSpeedMultiplier(c.character)

			return res
		end,
	},

	lockleftarm = {
		getter = function(c)
			return limbLockedInitial(c, LimbType.LeftArm, "lockleftarm")
		end,
	},
	lockrightarm = {
		getter = function(c)
			return limbLockedInitial(c, LimbType.RightArm, "lockrightarm")
		end,
	},
	lockleftleg = {
		getter = function(c)
			return limbLockedInitial(c, LimbType.LeftLeg, "lockleftleg")
		end,
	},
	lockrightleg = {
		getter = function(c)
			return limbLockedInitial(c, LimbType.RightLeg, "lockrightleg")
		end,
	},

	wheelchaired = {
		getter = function(c)
			local outerwearItem = c.character.Inventory.GetItemAt(4)
			local res = outerwearItem ~= nil and outerwearItem.Prefab.Identifier.Value == "wheelchair"
			if res then
				c.stats.lockleftleg = c.stats.lockleftarm
				c.stats.lockrightleg = c.stats.lockrightarm
			end
			-- leg and wheelchair slowdown
			if c.stats.lockleftleg or c.stats.lockrightleg or res then
				c.stats.speedmultiplier = c.stats.speedmultiplier * 0.5
			end
			local isProne = c.stats.lockleftleg and c.stats.lockrightleg
			-- okay climbing ability
			if isProne and c.character.IsClimbing then
				c.stats.speedmultiplier = c.stats.speedmultiplier * 0.5
			end
			-- moving prone with one arm or stop movement when no arms
			if (isProne or res) and c.stats.lockleftarm and c.stats.lockrightarm then
				c.stats.speedmultiplier = -9001
			elseif isProne and (c.stats.lockleftarm or c.stats.lockrightarm) then
				c.stats.speedmultiplier = c.stats.speedmultiplier * 0.8
			end
			-- if isProne then
			-- c.character.AnimController.RagdollParams.ColliderHeightFromFloor = 4.0
			-- end - Heelge: collider adjustment scrapped for now, lets wait for proper method in Workshop
			return res
		end,
	},

	bonegrowthCount = {
		getter = function(c)
			local res = 0
			for type in limbtypes do
				if HF.GetAfflictionStrengthLimb(c.character, type, "bonegrowth", 0) > 0 then
					res = res + 1
				end
			end
			return res
		end,
	},
	burndamage = {
		getter = function(c)
			local res = 0
			for type in limbtypes do
				res = res + HF.GetAfflictionStrengthLimb(c.character, type, "burn", 0)
			end
			return res
		end,
	},
}

function NT.UpdateHuman(character)
	-- Doing this additional check here enables NT updates for 'important' people like players, crew and AI opponents from the get-go
	-- instead of waiting on other interactions before updates start. - Lukako
	if character.IsHuman and character.TeamID == 1 or character.TeamID == 2 and not character.IsDead then
	else
		-- Original check
		if not HF.HasAffliction(character, "luabotomy") then
			return
		end
	end

	-- pre humanupdate hooks
	for key, val in pairs(NTC.PreHumanUpdateHooks) do
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
		for type in limbtypes do
			FetchLimbData(type)
		end
		for type in limbtypes do
			UpdateLimb(type)
		end
		for type in limbtypes do
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
	local oxygenlow = HF.GetAfflictionStrength(character, "oxygenlow", 0)
	if bloodloss > 0 then
		HF.AddAffliction(character, "organdamage", bloodloss * 2)
		HF.SetAffliction(character, "bloodloss", 0)
	elseif oxygenlow > 50 then
		HF.AddAffliction(character, "organdamage", (oxygenlow - 50) * 2)
		HF.SetAffliction(character, "oxygenlow", 50)
	end
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

-- optimization stuff
Hook.Add("character.created", "NT.cleanbotomy", function(character)
	-- Apply 5 minute traumatic shock immunity to those who happen to be in surgery after a starting the round
	if HF.HasAffliction(character, "surgeryincision") then
		HF.SetAffliction(character, "tshocktimeout", 15)
	end
	-- unfuck shit in the crewmate and add our ""update/debug flag""
	if character.TeamID == 1 or character.TeamID == 2 then
		HF.SetAffliction(character, "luabotomypurger", 2)
		Timer.Wait(function()
			HF.SetAffliction(character, "luabotomy", 0.1)
		end, 8000)
	end
end)

-- Force all Team1 and Team2 humans that do not already have Luabotomy to get it, enabling health updates. - Lukako
Hook.Add("characterCreated", "NT.forceluabotomy", function(character)
	Timer.Wait(function()
		if character.IsHuman and character.TeamID == 1 or character.TeamID == 2 and not character.IsDead then
			if not HF.HasAffliction(character, "luabotomy") then
				return
			end
		end
	end, 5000)
end)
