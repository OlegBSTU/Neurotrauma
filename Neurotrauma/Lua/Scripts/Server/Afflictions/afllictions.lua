-- define all the afflictions and their update functions
NT.Afflictions = {}
NT.Afflictions.insert = function(affliction)
	NT.Afflictions[affliction.id] = affliction
end

-- Help functions start
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
-- Help functions end

-- Arterial cuts
NT.Afflictions.insert(NTTypes.Affliction.new("t_arterialcut"))

-- Fractures and amputations
NT.Afflictions.insert(NTTypes.Affliction.new("t_fracture", nil, nil, nil, function(c, i)
	if c.afflictions[i].strength > 0 then
		c.afflictions[i].strength = c.afflictions[i].strength
			+ 2 * HF.BoolToNum(not HF.HasAfflictionLimb(c.character, "gypsumcast", LimbType.Torso)) * NT.Deltatime
	end
end))

NT.Afflictions.insert(NTTypes.Affliction.new("h_fracture", nil, nil, nil, function(c, i)
	if c.afflictions[i].strength > 0 then
		c.afflictions[i].strength = c.afflictions[i].strength
			+ 2 * HF.BoolToNum(not HF.HasAfflictionLimb(c.character, "gypsumcast", LimbType.Head)) * NT.Deltatime
	end
end))

NT.Afflictions.insert(NTTypes.Affliction.new("la_fracture", nil, nil, nil, function(c, i)
	if c.afflictions[i].strength > 0 then
		c.afflictions[i].strength = c.afflictions[i].strength
			+ 2 * HF.BoolToNum(not HF.HasAfflictionLimb(c.character, "gypsumcast", LimbType.LeftArm)) * NT.Deltatime
	end
end))

NT.Afflictions.insert(NTTypes.Affliction.new("ra_fracture", nil, nil, nil, function(c, i)
	if c.afflictions[i].strength > 0 then
		c.afflictions[i].strength = c.afflictions[i].strength
			+ 2
				* HF.BoolToNum(not HF.HasAfflictionLimb(c.character, "gypsumcast", LimbType.RightArm))
				* NT.Deltatime
	end
end))

NT.Afflictions.insert(NTTypes.Affliction.new("ll_fracture", nil, nil, nil, function(c, i)
	if c.afflictions[i].strength > 0 then
		c.afflictions[i].strength = c.afflictions[i].strength
			+ 2 * HF.BoolToNum(not HF.HasAfflictionLimb(c.character, "gypsumcast", LimbType.LeftLeg)) * NT.Deltatime
	end
end))

NT.Afflictions.insert(NTTypes.Affliction.new("rl_fracture", nil, nil, nil, function(c, i)
	if c.afflictions[i].strength > 0 then
		c.afflictions[i].strength = c.afflictions[i].strength
			+ 2
				* HF.BoolToNum(not HF.HasAfflictionLimb(c.character, "gypsumcast", LimbType.RightLeg))
				* NT.Deltatime
	end
end))

NT.Afflictions.insert(NTTypes.Affliction.new("n_fracture", nil, nil, nil, function(c, i)
	if c.afflictions[i].strength > 0 then
		c.afflictions[i].strength = c.afflictions[i].strength
			+ 2 * HF.BoolToNum(not HF.HasAfflictionLimb(c.character, "gypsumcast", LimbType.Head)) * NT.Deltatime
	end
end))

NT.Afflictions.insert(NTTypes.Affliction.new("tla_amputation"))

NT.Afflictions.insert(NTTypes.Affliction.new("tra_amputation"))

NT.Afflictions.insert(NTTypes.Affliction.new("tll_amputation"))

NT.Afflictions.insert(NTTypes.Affliction.new("trl_amputation"))

NT.Afflictions.insert(NTTypes.Affliction.new("sla_amputation"))

NT.Afflictions.insert(NTTypes.Affliction.new("sra_amputation"))

NT.Afflictions.insert(NTTypes.Affliction.new("sll_amputation"))

NT.Afflictions.insert(NTTypes.Affliction.new("srl_amputation"))

NT.Afflictions.insert(NTTypes.Affliction.new("t_paralysis"))

-- artificial ventilation
NT.Afflictions.insert(NTTypes.Affliction.new("alv"))

NT.AllAflictions.insert(NTTypes.Affliction.new("needlec", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = c.afflictions[i].strength - 0.15 * NT.Deltatime
end))

-- Organ conditions
NT.AllAflictions.insert(NTTypes.Affliction.new("cardiacarrest", nil, nil, nil, function(c, i)
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
			or (c.afflictions.fibrillation.strength > 20 and HF.Chance((c.afflictions.fibrillation.strength / 100) ^ 4))
		)
	then
		c.afflictions[i].strength = c.afflictions[i].strength + 10
	end
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("respiratoryarrest", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("pneumothorax", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("tamponade", nil, nil, nil, function(c, i)
	if c.afflictions[i].strength > 0 then
		c.afflictions[i].strength = c.afflictions[i].strength + NT.Deltatime * 0.5
	end

	if c.afflictions.heartremoved.strength > 0 then
		c.afflictions[i].strength = 0
	end
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("heartattack", nil, nil, nil, function(c, i)
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
					NTConfig.Get("NT_heartattackChance", 1) * ((c.afflictions.bloodpressure.strength - 150) / 50 * 0.02)
				)
			)
		)
	then
		c.afflictions[i].strength = c.afflictions[i].strength + 50
	end

	if c.afflictions.heartremoved.strength > 0 then
		c.afflictions[i].strength = 0
	end
end))

-- Organs removed
NT.AllAflictions.insert(NTTypes.Affliction.new("brainremoved", nil, nil, nil, function(c, i)
	if c.afflictions[i].strength > 0 then
		c.afflictions[i].strength = 1
			+ HF.BoolToNum(HF.HasAfflictionLimb(c.character, "retractedskin", LimbType.Head, 99), 99)
	end
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("heartremoved", nil, nil, nil, function(c, i)
	if c.afflictions[i].strength > 0 then
		c.afflictions[i].strength = 1
			+ HF.BoolToNum(HF.HasAfflictionLimb(c.character, "retractedskin", LimbType.Torso, 99), 99)
	end
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("lungremoved", nil, nil, nil, function(c, i)
	if c.afflictions[i].strength > 0 then
		c.afflictions[i].strength = 1
			+ HF.BoolToNum(HF.HasAfflictionLimb(c.character, "retractedskin", LimbType.Torso, 99), 99)
	end
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("liverremoved", nil, nil, nil, function(c, i)
	if c.afflictions[i].strength > 0 then
		c.afflictions[i].strength = 1
			+ HF.BoolToNum(HF.HasAfflictionLimb(c.character, "retractedskin", LimbType.Torso, 99), 99)
	end
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("kidneyremoved", nil, nil, nil, function(c, i)
	if c.afflictions[i].strength > 0 then
		c.afflictions[i].strength = 1
			+ HF.BoolToNum(HF.HasAfflictionLimb(c.character, "retractedskin", LimbType.Torso, 99), 99)
	end
end))

-- Organ damage
NT.AllAflictions.insert(NTTypes.Affliction.new("cerebralhypoxia", 200, nil, nil, function(c, i)
	if c.stats.stasis then
		return
	end
	-- calculate new neurotrauma
	local gain = (
		-0.1 * c.stats.healingrate -- passive regen
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("heartdamage", nil, nil, nil, function(c, i)
	if c.stats.stasis then
		return
	end
	c.afflictions[i].strength = NT.organDamageCalc(
		c,
		c.afflictions[i].strength
			+ NTC.GetMultiplier(c.character, "heartdamagegain")
				* (c.stats.neworgandamage + HF.Clamp(c.afflictions.heartattack.strength, 0, 0.5) * NT.Deltatime)
	)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("lungdamage", nil, nil, nil, function(c, i)
	if c.stats.stasis then
		return
	end
	c.afflictions[i].strength = NT.organDamageCalc(
		c,
		c.afflictions.lungdamage.strength
			+ NTC.GetMultiplier(c.character, "lungdamagegain")
				* (c.stats.neworgandamage + math.max(c.afflictions.radiationsickness.strength - 25, 0) / 800 * NT.Deltatime)
	)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("liverdamage", nil, nil, nil, function(c, i)
	if c.stats.stasis then
		return
	end
	c.afflictions[i].strength = NT.organDamageCalc(
		c,
		c.afflictions.liverdamage.strength + NTC.GetMultiplier(c.character, "liverdamagegain") * c.stats.neworgandamage
	)
	if c.afflictions[i].strength >= 99 and not NTC.GetSymptom(c.character, "sym_hematemesis") and HF.Chance(0.05) then
		-- if liver failed: 5% chance for 6-20 seconds of blood vomiting and internal bleeding
		NTC.SetSymptomTrue(c.character, "sym_hematemesis", math.random(3, 10))
		c.afflictions.internalbleeding.strength = c.afflictions.internalbleeding.strength + 2
	end
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("kidneydamage", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("bonedamage", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("organdamage", 200, nil, nil, function(c, i)
	if c.stats.stasis then
		return
	end
	c.afflictions[i].strength = c.afflictions[i].strength
		+ c.stats.neworgandamage
		- 0.03 * c.stats.healingrate * NT.Deltatime
end))

-- Blood
NT.AllAflictions.insert(NTTypes.Affliction.new("sepsis", nil, nil, nil, function(c, i)
	if c.afflictions.afantibiotics.strength > 0.1 then
		c.afflictions[i].strength = c.afflictions[i].strength - NT.Deltatime
	end
	if c.stats.stasis then
		return
	end
	if c.afflictions[i].strength > 0.1 then
		c.afflictions[i].strength = c.afflictions[i].strength + 0.05 * NT.Deltatime
	end
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("immunity", nil, 5, -1, function(c, i)
	if c.afflictions[i].strength == -1 then
		-- no immunity affliction!
		-- assume it has been wiped by "revive" or "heal all", attempt to assign new blood type
		if NT.HasBloodtype(c.character) then
			-- if blood type is already here, set immunity to the minimum
			c.afflictions[i].strength = 5
		else
			-- no bloodtype -> all afflictions have been cleared, set immunity to maximum
			c.afflictions[i].strength = 100
			NT.GetBloodtype(c.character)
		end
	end
	if c.stats.stasis then
		return
	end

	-- immunity regeneration
	c.afflictions[i].strength =
		HF.Clamp(c.afflictions[i].strength + (0.5 + c.afflictions[i].strength / 100) * NT.Deltatime, 5, 100)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("bloodloss", 200))

NT.AllAflictions.insert(NTTypes.Affliction.new("bloodpressure", 200, 5, 100, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("hypoxemia", nil, nil, nil, function(c, i)
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
		regularHypoxemiaChange = HF.Lerp(regularHypoxemiaChange * 2, 0, HF.Clamp((50 - c.stats.bloodamount) / 50, 0, 1))
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("hemotransfusionshock"))

-- Other
NT.AllAflictions.insert(NTTypes.Affliction.new("oxygenlow", 200, nil, nil, function(c, i)
	-- respiratory arrest? -> oxygen in lungs rapidly decreases
	if c.afflictions.respiratoryarrest.strength > 0 then
		c.afflictions.oxygenlow.strength = c.afflictions.oxygenlow.strength + 15 * NT.Deltatime
	end
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("radiationsickness", 200, nil, nil, function(c, i)
	c.afflictions[i].strength = c.afflictions[i].strength - NT.Deltatime * 0.02
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("stasis"))

NT.AllAflictions.insert(NTTypes.Affliction.new("table"))

NT.AllAflictions.insert(NTTypes.Affliction.new("internalbleeding", nil, nil, nil, function(c, i)
	if c.stats.stasis then
		return
	end
	c.afflictions[i].strength = c.afflictions[i].strength - NT.Deltatime * 0.02 * c.stats.clottingrate
	if c.afflictions[i].strength > 0 then
		c.afflictions.bloodloss.strength = c.afflictions.bloodloss.strength
			+ c.afflictions[i].strength * (1 / 40) * NT.Deltatime
	end
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("acidosis", nil, nil, nil, function(c, i)
	if c.stats.stasis then
		return
	end
	c.afflictions[i].strength = c.afflictions[i].strength
		- NT.Deltatime * 0.03
		+ (
				HF.Clamp(c.afflictions.hypoventilation.strength, 0, 1) * 0.09
				+ HF.Clamp(
					(
						c.afflictions.respiratoryarrest.strength
						* HF.BoolToNum(
							c.afflictions.alv.strength <= 0.1 and not HF.HasAffliction(c.character, "cpr_buff")
						)
					) + c.afflictions.cardiacarrest.strength,
					0,
					1
				) * 0.18
				+ math.max(0, c.afflictions.kidneydamage.strength - 80) / 20 * 0.1
			)
			* NT.Deltatime
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("alkalosis", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("seizure", nil, nil, nil, function(c, i)
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
			or (c.afflictions.opiateoverdose.strength > 60 and HF.Chance(c.afflictions.opiateoverdose.strength / 500))
		)
	then
		c.afflictions[i].strength = c.afflictions[i].strength + 10
	end

	-- check for spasm trigger
	if c.afflictions[i].strength > 0.1 then
		for _, type in ipairs(NTTypes.LimbTypes) do
			if HF.Chance(0.5) then
				HF.AddAfflictionLimb(c.character, "spasm", type, 10)
			end
		end
	end
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("stroke", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("coma", nil, nil, nil, function(c, i)
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
			or (c.afflictions.acidosis.strength > 60 and HF.Chance(0.05 + (c.afflictions.acidosis.strength - 60) / 100))
		)
	then
		c.afflictions[i].strength = c.afflictions[i].strength + 14
	end
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("stun", 30, nil, nil, function(c, i)
	if c.afflictions.t_paralysis.strength > 0 or c.afflictions.anesthesia.strength > 15 then
		c.afflictions[i].strength = math.max(5, c.afflictions[i].strength)
	end
end, function(c, i, newval)
	-- using the character stun property to apply instead of an affliction so that the networking doesnt shit itself (hopefully)
	c.character.Stun = newval
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("slowdown", nil, nil, nil, nil, nil, function(c, i)
	c.afflictions[i].strength = HF.Clamp(100 * (1 - c.stats.speedmultiplier), 0, 100)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("givein", 1, nil, nil, function(c, i)
	c.afflictions[i].strength =
		HF.BoolToNum(c.afflictions.t_paralysis.strength > 0 or c.afflictions.sym_unconsciousness.strength > 0)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("lockedhands", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("traumaticshock", nil, nil, nil, function(c, i)
	local shouldReduce = (c.stats.sedated and c.afflictions.table.strength > 0)
		or c.afflictions.anesthesia.strength > 15
	c.afflictions[i].strength = c.afflictions[i].strength - (0.5 + HF.BoolToNum(shouldReduce, 1.5)) * NT.Deltatime

	if c.afflictions[i].strength > 5 and c.afflictions.sym_unconsciousness.strength < 0.1 then
		HF.AddAffliction(c.character, "shockpain", 10 * NT.Deltatime)
		HF.AddAffliction(c.character, "psychosis", c.afflictions[i].strength / 100 * NT.Deltatime)
	end
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("alcoholwithdrawal"))

NT.AllAflictions.insert(NTTypes.Affliction.new("opiatewithdrawal"))

NT.AllAflictions.insert(NTTypes.Affliction.new("chemwithdrawal"))

NT.AllAflictions.insert(NTTypes.Affliction.new("opiateoverdose"))

-- Drugs
NT.AllAflictions.insert(NTTypes.Affliction.new("analgesia", 200))

-- propofol (i hate it)
NT.AllAflictions.insert(NTTypes.Affliction.new("anesthesia", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("drunk", 200))

NT.AllAflictions.insert(NTTypes.Affliction.new("afadrenaline"))

NT.AllAflictions.insert(NTTypes.Affliction.new("afantibiotics"))

NT.AllAflictions.insert(NTTypes.Affliction.new("afthiamine"))

NT.AllAflictions.insert(NTTypes.Affliction.new("afsaline"))

NT.AllAflictions.insert(NTTypes.Affliction.new("afringerssolution"))

NT.AllAflictions.insert(NTTypes.Affliction.new("afstreptokinase"))

NT.AllAflictions.insert(NTTypes.Affliction.new("afmannitol"))

NT.AllAflictions.insert(NTTypes.Affliction.new("afpressuredrug", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = c.afflictions[i].strength - 0.25 * NT.Deltatime
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("concussion", nil, nil, nil, function(c, i)
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
end))

-- /// Symptoms ///
--==============================================================================
NT.AllAflictions.insert(NTTypes.Affliction.new("sym_unconsciousness", nil, nil, nil, function(c, i)
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
	if isUnconscious then
		c.afflictions.stun.strength = math.max(7, c.afflictions.stun.strength)
	end
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("tachycardia", nil, nil, nil, function(c, i)
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
		c.afflictions.fibrillation.strength = c.afflictions.fibrillation.strength + fibrillationSpeed * NT.Deltatime
	end
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("fibrillation", nil, nil, nil, function(c, i)
	-- see above for vfib accumulation logic
	if
		NTC.GetSymptomFalse(c.character, i)
		or c.afflictions.cardiacarrest.strength >= 1
		or c.afflictions.heartremoved.strength >= 1
	then
		c.afflictions[i].strength = 0
	end
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("hyperventilation", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("hypoventilation", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("dyspnea", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_cough", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_paleskin", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = HF.BoolToNum(
		not NTC.GetSymptomFalse(c.character, i)
			and (
				NTC.GetSymptom(c.character, i)
				or c.stats.bloodamount < 60
				or c.afflictions.bloodpressure.strength < 50
			),
		2
	)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_lightheadedness", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = HF.BoolToNum(
		not NTC.GetSymptomFalse(c.character, i)
			and c.afflictions.sym_unconsciousness.strength <= 0
			and (NTC.GetSymptom(c.character, i) or c.afflictions.bloodpressure.strength < 60),
		2
	)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_blurredvision", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = HF.BoolToNum(
		not NTC.GetSymptomFalse(c.character, i)
			and c.afflictions.sym_unconsciousness.strength <= 0
			and (NTC.GetSymptom(c.character, i) or c.afflictions.bloodpressure.strength < 55),
		2
	)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_confusion", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_headache", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_legswelling", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_weakness", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_wheezing", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_vomiting", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_nausea", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_hematemesis", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = HF.BoolToNum(
		not NTC.GetSymptomFalse(c.character, i)
			and (NTC.GetSymptom(c.character, i) or c.afflictions.internalbleeding.strength > 50),
		2
	)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("fever", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = HF.BoolToNum(
		not NTC.GetSymptomFalse(c.character, i)
			and (
				NTC.GetSymptom(c.character, i)
				or c.afflictions.sepsis.strength > 5
				or c.afflictions.alcoholwithdrawal.strength > 90
			),
		2
	)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_abdomdiscomfort", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = HF.BoolToNum(
		not NTC.GetSymptomFalse(c.character, i)
			and c.afflictions.sym_unconsciousness.strength <= 0
			and (NTC.GetSymptom(c.character, i) or c.afflictions.liverdamage.strength > 65),
		2
	)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_bloating", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = HF.BoolToNum(
		not NTC.GetSymptomFalse(c.character, i)
			and (NTC.GetSymptom(c.character, i) or c.afflictions.liverdamage.strength > 50),
		2
	)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_jaundice", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = HF.BoolToNum(
		not NTC.GetSymptomFalse(c.character, i)
			and (NTC.GetSymptom(c.character, i) or c.afflictions.liverdamage.strength > 80),
		2
	)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_sweating", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = HF.BoolToNum(
		not NTC.GetSymptomFalse(c.character, i)
			and (NTC.GetSymptom(c.character, i) or c.afflictions.heartattack.strength > 1 or c.stats.withdrawal > 30),
		2
	)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_palpitations", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = HF.BoolToNum(
		not NTC.GetSymptomFalse(c.character, i)
			and c.afflictions.cardiacarrest.strength <= 0
			and (NTC.GetSymptom(c.character, i) or c.afflictions.alkalosis.strength > 20),
		2
	)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_craving", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = HF.BoolToNum(
		not NTC.GetSymptomFalse(c.character, i)
			and c.afflictions.sym_unconsciousness.strength <= 0
			and (NTC.GetSymptom(c.character, i) or c.stats.withdrawal > 20),
		2
	)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("forceprone", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("onwheelchair", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = HF.BoolToNum(
		not NTC.GetSymptomFalse(c.character, i)
			and c.afflictions.sym_unconsciousness.strength <= 0
			and (NTC.GetSymptom(c.character, i) or c.stats.wheelchaired),
		2
	)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("pain_abdominal", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("pain_chest", nil, nil, nil, function(c, i)
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
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("luabotomy", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = 0
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("modconflict", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = HF.BoolToNum(NT.modconflict, 1)
end))

NT.AllAflictions.insert(NTTypes.Affliction.new("sym_scorched", nil, nil, nil, function(c, i)
	c.afflictions[i].strength = HF.BoolToNum(c.stats.burndamage > 500, 10)
end))
