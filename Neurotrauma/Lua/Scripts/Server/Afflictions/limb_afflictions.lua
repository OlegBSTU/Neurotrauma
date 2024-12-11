-- define all the limb specific afflictions and their update functions
NT.LimbAfflictions = {}
NT.LimbAfflictions.insert = function(affliction)
	NT.Afflictions[affliction.id] = affliction
end

-- Help functions start
local function isExtremity(type)
	return type ~= LimbType.Torso and type ~= LimbType.Head
end
-- Help functions end

NT.LimbAfflictions.insert(NTTypes.Affliction.new("bandaged", nil, nil, nil, function(c, limbaff, i)
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
end))

-- for bandage dirtifaction logic see above
NT.LimbAfflictions.insert(NTTypes.Affliction.new("dirtybandage"))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("iced", nil, nil, nil, function(c, limbaff, i, type)
	-- over time skin temperature goes up again
	if limbaff[i].strength > 0 then
		limbaff[i].strength = limbaff[i].strength - 1.7 * NT.Deltatime
	end
	-- iced slowdown
	if limbaff[i].strength > 0 then
		c.stats.speedmultiplier = c.stats.speedmultiplier * 0.95
	end
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("gypsumcast", nil, nil, nil, function(c, limbaff, i, type)
	-- gypsum slowdown and fracture healing
	if limbaff[i].strength > 0 then
		c.stats.speedmultiplier = c.stats.speedmultiplier * 0.8
		NT.BreakLimb(c.character, type, -(100 / 300) * NT.Deltatime)
	end
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("ointmented"))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("bonegrowth", nil, nil, nil, function(c, limbaff, i, type)
	if limbaff[i].strength <= 0 then
		-- check for bone death fracture triggers
		if c.afflictions.bonedamage.strength > 90 and HF.Chance(0.01) then
			NT.BreakLimb(c.character, type)
		end
	end
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("arteriesclamp"))

-- damage
NT.LimbAfflictions.insert(NTTypes.Affliction.new("bleeding", nil, nil, nil, function(c, limbaff, i)
	if limbaff[i].strength > 0 and math.abs(c.stats.clottingrate - 1) > 0.05 then
		limbaff[i].strength = limbaff[i].strength - (c.stats.clottingrate - 1) * 0.1 * NT.Deltatime
	end
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("burn", 200, nil, nil, function(c, limbaff, i)
	if limbaff[i].strength < 50 then
		limbaff[i].strength = limbaff[i].strength
			- (c.afflictions.immunity.prev / 3000 + HF.Clamp(limbaff.bandaged.strength, 0, 1) * 0.1)
				* c.stats.healingrate
				* NT.Deltatime
	end
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("acidburn", 200, nil, nil, function(c, limbaff, i)
	-- convert acid burns to regular burns
	if limbaff[i].strength > 0 then
		limbaff.burn.strength = limbaff.burn.strength + limbaff[i].strength
		limbaff[i].strength = 0
	end
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("lacerations", 200, nil, nil, function(c, limbaff, i)
	limbaff[i].strength = limbaff[i].strength
		- (c.afflictions.immunity.prev / 3000 + HF.Clamp(limbaff.bandaged.strength, 0, 1) * 0.1)
			* c.stats.healingrate
			* NT.Deltatime
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("gunshotwound", 200, nil, nil, function(c, limbaff, i)
	limbaff[i].strength = limbaff[i].strength
		- (c.afflictions.immunity.prev / 3000 + HF.Clamp(limbaff.bandaged.strength, 0, 1) * 0.1)
			* c.stats.healingrate
			* NT.Deltatime
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("bitewounds", 200, nil, nil, function(c, limbaff, i)
	limbaff[i].strength = limbaff[i].strength
		- (c.afflictions.immunity.prev / 3000 + HF.Clamp(limbaff.bandaged.strength, 0, 1) * 0.1)
			* c.stats.healingrate
			* NT.Deltatime
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("explosiondamage", 200, nil, nil, function(c, limbaff, i)
	limbaff[i].strength = limbaff[i].strength
		- (c.afflictions.immunity.prev / 3000 + HF.Clamp(limbaff.bandaged.strength, 0, 1) * 0.1)
			* c.stats.healingrate
			* NT.Deltatime
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("blunttrauma", 200, nil, nil, function(c, limbaff, i)
	limbaff[i].strength = limbaff[i].strength
		- (
				c.afflictions.immunity.prev / 8000
				+ HF.Clamp(limbaff.bandaged.strength, 0, 1) * 0.1
				+ HF.Clamp(limbaff.iced.strength, 0, 1) * 0.33
			)
			* c.stats.healingrate
			* NT.Deltatime
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("internaldamage", 200, nil, nil, function(c, limbaff, i, type)
	limbaff[i].strength = limbaff[i].strength
		+ (
				-0.05 * c.stats.healingrate
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
end))

-- other
NT.LimbAfflictions.insert(NTTypes.Affliction.new("infectedwound", nil, nil, nil, function(c, limbaff, i)
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
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("foreignbody", nil, nil, nil, function(c, limbaff, i, type)
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
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("gangrene", nil, nil, nil, function(c, limbaff, i, type)
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
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("pain_extremity", 10, nil, nil, function(c, limbaff, i, type)
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
end))

-- limb symptoms
NT.LimbAfflictions.insert(NTTypes.Affliction.new("inflammation", nil, nil, nil, function(c, limbaff, i)
	limbaff[i].strength = limbaff[i].strength
		+ (-0.1 + HF.BoolToNum(limbaff.infectedwound.strength > 10 or limbaff.foreignbody.strength > 15, 0.15))
			* NT.Deltatime
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("burn_deg1", nil, nil, nil, function(c, limbaff, i)
	if limbaff.burn.strength < 1 or limbaff.burn.strength > 20 then
		limbaff[i].strength = 0
	else
		limbaff[i].strength = limbaff.burn.strength * 5
	end
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("burn_deg2", nil, nil, nil, function(c, limbaff, i)
	if limbaff.burn.strength <= 20 or limbaff.burn.strength > 50 then
		limbaff[i].strength = 0
	else
		limbaff[i].strength = math.max(5, (limbaff.burn.strength - 20) / 30 * 100)
	end
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("burn_deg3", nil, nil, nil, function(c, limbaff, i)
	if limbaff.burn.strength <= 50 then
		limbaff[i].strength = 0
	else
		limbaff[i].strength = HF.Clamp((limbaff.burn.strength - 50) / 50 * 100, 5, 100)
	end
end))

NT.LimbAfflictions.insert(NTTypes.Affliction.new("infection", nil, nil, nil, function(c, limbaff, i, type)
	if limbaff[i].strength ~= nil then
		limbaff.infectedwound.strength = limbaff.infectedwound.strength + limbaff[i].strength / 2
		limbaff[i].strength = 0
	end
end))
