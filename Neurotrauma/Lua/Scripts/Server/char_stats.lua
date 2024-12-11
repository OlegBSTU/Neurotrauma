-- some local functions to avoid code duplicates
local function limbLockedInitial(c, limbtype, key)
	return not NTC.GetSymptomFalse(c.character, key)
		and (
			NTC.GetSymptom(c.character, key)
			or c.afflictions.t_paralysis.strength > 0
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
				or c.afflictions.drunk.strength > 30
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
			-- moving prone with one arm or 95% slowdown when no arms
			if (isProne or res) and c.stats.lockleftarm and c.stats.lockrightarm then
				c.stats.speedmultiplier = 0.05
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
			for _, type in ipairs(NTTypes.LimbTypes) do
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
			for _, type in ipairs(NTTypes.LimbTypes) do
				res = res + HF.GetAfflictionStrengthLimb(c.character, type, "burn", 0)
			end
			return res
		end,
	},
}
