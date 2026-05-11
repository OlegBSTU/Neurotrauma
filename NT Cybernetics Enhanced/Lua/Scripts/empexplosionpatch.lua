--On exploding, apply EMP affliction to character in range
local emp_limbs = { LimbType.LeftLeg, LimbType.RightLeg, LimbType.LeftArm, LimbType.RightArm }

Hook.Patch("Barotrauma.Explosion", "Explode", function(instance, ptable)
	if instance.EmpStrength > 0 then
		local explode_empstrength = instance.EmpStrength
		local explode_range = instance.Attack.Range
		local explode_range_sq = explode_range * explode_range
		local explode_worldposition = ptable["worldPosition"]
		local explode_attacker = ptable["attacker"]

		for key, character in pairs(Character.CharacterList) do
			if character.IsHuman and not character.IsDead then
				local distance_sq = Vector2.DistanceSquared(character.worldPosition, explode_worldposition)
				if distance_sq < explode_range_sq then
					local affliction_strength = 50
						* explode_empstrength
						* (1 - (math.sqrt(distance_sq) / explode_range))
					for key, limbtype in pairs(emp_limbs) do
						if NTCyb.HF.LimbIsCyber(character, limbtype) then
							HF.AddAfflictionLimb(
								character,
								"ntc_damagedelectronics",
								limbtype,
								affliction_strength,
								explode_attacker
							)
						end
					end

					for _, organConfig in pairs(NTCyb.OrganConfigDatas) do
						local isTier3Mul = HF.GetAfflictionStrength(character, organConfig.cyberAffliction, 0) / 100 -- tier 2 takes half the damage of tier 3
						if isTier3Mul > 0.01 and organConfig.damageAffliction then
							HF.AddAffliction(
								character,
								organConfig.damageAffliction,
								affliction_strength / 5 * isTier3Mul,
								explode_attacker
							)
						end
					end
				end
			end
		end
	end
end, Hook.HookMethodType.After)
