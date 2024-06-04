local limbTypes = {
    LimbType.LeftArm,
    LimbType.RightArm,
    LimbType.LeftLeg,
    LimbType.RightLeg,
    LimbType.Torso,
    LimbType.Head
}
gasSafePressures = {}  -- for new gas tanks and overrides
gasSafePressures["oxygentank"] = 3500
gasSafePressures["nitroxtank"] = 3000
gasSafePressures["helioxtank"] = 6000
gasSafePressures["hydroxtank"] = 90000
gasSafePressures["liquidgastank"] = 90000
gasSafePressures["default"] = 3500

local function HasLungs(c) return not HF.HasAffliction(c,"lungremoved") end
local function GetOuterWearContainedIdentifier(c)
	local item = HF.GetOuterWear(c)
	local containeditem = item.OwnInventory.GetItemAt(0)
	if containeditem ~= nil then
		return containeditem.Prefab.Identifier.Value
	else
		return "default"
	end
end
local function BreathingGasPressureGrade(c) 
	local gasTankIdentifier = GetOuterWearContainedIdentifier(c)
	return gasSafePressures[gasTankIdentifier]
end

Timer.Wait(function()


	NT.Afflictions.nthm_fatigue = {max=100}
	-- high CO2 presence in blood, cause symptoms, CO2 narcosis if severe enough, caused by fatigue underwater
    NT.Afflictions.nthm_hypercapnia = {max=100,update=function(c,i)
		if c.stats.stasis then return end
		-- liquid oxygenite treatment and prevention 
		-- (rework neurotrauma liquid oxygenite)
		-- if c.afflictions.loxygenite > 0 then c.afflictions[i].strength = 0 return end
		
		-- apply different symptoms on severity
		if c.afflictions[i].strength > 0 and c.afflictions[i].strength < 31 then
			NTC.SetSymptomTrue(c.character,"sym_headache",2)
		elseif c.afflictions[i].strength > 30 and c.afflictions[i].strength < 61 then
			NTC.SetSymptomTrue(c.character,"sym_confusion",2)
		end
		-- manage strength by current swimming fatigue (depletes immediately if in a current)
		local newStrength = HF.BoolToNum(c.affliction.fatigue.strength >= 100, 3) + HF.BoolToNum(c.affliction.fatigue.strength < 100, -1) + HF.BoolToNum(c.affliction.motionless.strength > 0.1, -1)
		c.afflictions[i].strength = HF.Clamp(c.afflictions[i].strength + NT.Deltatime * newStrength,0,100)
	end
	}
	-- klonopin drug, cures status epilepticus, panicking.
	-- worsens the liver damage by 30%, additional 15% liver damage and hypoventilation symptom
    -- NTC.AddHematologyAffliction("klonopin")
    -- NT.Afflictions.nthm_klonopin = {max=150,update=function(c,i)
		-- if c.afflictions[i].strength > 0 then
			-- NTC.SetSymptomTrue(c.character,"hypoventilation",2)
			-- NTC.SetSymptomFalse(c.character,"sym_panic",2)
			-- c.afflictions[i].strength = HF.Clamp(c.afflictions[i].strength - NT.Deltatime * 0.5,0,150) -- lose 0.5% klonopin/s
		-- end
	-- end
	-- }
	NT.Afflictions.nthm_co2narc = {update=function(c,i)
		local isUnconscious = not HF.HasAffliction(c.character,"implacable",0.05)
			and (c.afflictions.hypercapnia.strength >= 100 or c.afflictions.co2narc.strength > 0.1)
		if isUnconscious then 
			c.afflictions.stun.strength = math.max(7,c.afflictions.stun.strength)
			HF.AddAffliction(c.character,"co2narc", NT.Deltatime * 0.5)
		end
	}
	-- nitrogen gas\liquid presence in blood
	NT.Afflictions.nthm_caissondisease = {max=100,update=function(c,i)
		-- if c.stats.stasis or (c.afflictions.oxygenated and HasLungs(c.character))> 0 then return end
		if c.stats.stasis then return end
		-- hyperbaric oxygen chamber treatment
		-- if c.stats.hoc > 0 then c.afflictions[i].strength = 0 return end
		if c.afflictions[i].strength > 0 then
            c.afflictions[i].strength = HF.Clamp(
                c.afflictions[i].strength + NT.Deltatime * 0.5 -- gain 0.5 strength/s
            ,0,100)
		end
		if c.afflictions.decompressiontime == 100 and c.afflictions[i].strength < 0.1 then
			c.afflictions[i].strength = NT.Deltatime * 0.5
		end
	end
	}
	-- time until caissondisease, varies with numerous conditions, 5.5 minutes default
	NT.Afflictions.nthm_motionless = {max=10}
	NT.Afflictions.nthm_decompressiontime = {max=100,update=function(c,i)
		-- if c.stats.stasis or c.afflictions.oxygenated > 0 then return end
		if c.stats.stasis then return end
		if c.character.InPressure and c.afflictions.motionless < 0.1 and GetOuterWearContainedIdentifier(c.character) != "liquidgastank" then
			if GetOuterWearContainedIdentifier(c.character) != "nitroxtank" then
				c.afflictions[i].strength = HF.Clamp(
					c.afflictions[i].strength + NT.Deltatime * 0.3 + 
					NT.Deltatime*(c.afflictions.bloodpressure.strength-100)/100*0.1 + 
					NT.Deltatime*c.afflictions.lungdamage.strength/100*0.1 + 
					NT.Deltatime*c.afflictions.heartdamage.strength/100*0.1 + 
					NT.Deltatime*c.afflictions.drunk.strength/200*0.1 -- gain 0.3 strength/s by default then add 0.1 strength/s for every condition with severity
				,0,100)
			else
				c.afflictions[i].strength = HF.Clamp(c.afflictions[i].strength + NT.Deltatime * 0.1,0,100) -- gain 0.1 strength/s if using nitrox tank
			end
		else
			c.afflictions[i].strength = HF.Clamp(c.afflictions[i].strength - 1,0,100)
		end
	end
	}
	-- gas inside arteries
	NT.Afflictions.nthm_arterialgasembolism = {max=10,update=function(c,i)
		if c.stats.stasis then return end
		-- hyperbaric oxygen chamber treatment
		-- if c.stats.hoc > 0 then c.afflictions[i].strength = 0 return end
		if HF.Chance(0.07) and c.afflictions.caissondisease > 30 then
			c.afflictions[i].strength = 10
            if HF.Chance(0.5) then
				HF.AddAffliction(c.character,"heartattack",50)
			else
				NTC.SetSymptomTrue(c.character,"triggersym_stroke",2)
			end
		end
	end
	}
	-- oxygen intoxication, triggered by inhaling gas at unsafe pressure
	NT.Afflictions.nthm_diversrapture = {max=100,update=function(c,i)
		if c.stats.stasis then return end
		-- hyperbaric oxygen chamber treatment
		-- if c.stats.hocsuccess > 0 then c.afflictions[i].strength = 0 end
		if c.afflictions[i].strength > 70 and c.afflictions.klonopin < 0.1 then
            HF.AddAffliction(c.character,"statusepilepticus",50 * NT.Deltatime)
		end
		local charPosY = c.character.WorldPosition.Y
		if charPosY < 3500 or (c.character.InPressure and BreathingGasPressureGrade(c) < charPosY) then
            c.afflictions[i].strength = HF.Clamp(
                c.afflictions[i].strength + NT.Deltatime * 0.5 -- gain 0.5 strength/s
            ,0,100)
		else
			c.afflictions[i].strength = HF.Clamp(
                c.afflictions[i].strength + NT.Deltatime * 0.5 -- lose 0.5 strength/s
            ,0,100)
		end
	end
	}
	NT.Afflictions.nthm_statusepilepticus = {max=100,update=function(c,i)
		if (c.afflictions[i].strength > 0.1) then
			c.afflictions.stun.strength = math.max(c.afflictions.stun.strength,5)
			for type in limbtypes do
				if(HF.Chance(0.6)) then 
					HF.AddAfflictionLimb(c.character,"spasm",type,10)
				end
			end
		end
	end
	}
	NT.Afflictions.pressure = {max=100,update=function(c,i)
		-- if c.afflictions[i].strength < 0.1 then
			-- if c.character.InPressure and PressureProtection < c.character.WorldPosition.Y then 
				-- c.afflictions[i].strength = NT.Deltatime * 4 
				-- c.character.IsImmuneToPressure = true
			-- return end -- gain 4/s. Handled in a hook
		-- end
		if c.afflictions[i].strength > 0 and c.afflictions[i].strength <= 30 then -- gain 2% lung damage/s
			if HasLungs(c.character) then c.afflictions.lungdamage.strength = HF.Clamp(c.afflictions.lungdamage.strength + NT.Deltatime * 2,0,100) end
		elseif c.afflictions[i].strength > 30 then
			if HasLungs(c.character) and c.afflictions.pneumothorax.strength < 0.1 then -- develop pneumothorax
				HF.AddAffliction(c.character,"pneumothorax",5) end
		elseif c.afflictions[i].strength > 50 and c.afflictions[i].strength <= 99 then -- vomit blood
            NTC.SetSymptomTrue(c.character,"sym_hematemesis",2)
		elseif c.afflictions[i].strength == 100 then  -- implosion
			c.character.IsImmuneToPressure = false
			c.character.PressureTimer = 100.0
		end
		
		if c.afflictions[i].strength > 0 and c.character.IsProtectedFromPressure
			c.afflictions[i].strength = HF.Clamp(
				c.afflictions[i].strength - NT.Deltatime * 2 -- lose 2% barotrauma/s
			,0,100)
        elseif c.afflictions[i].strength > 0 and not c.character.IsProtectedFromPressure
			c.afflictions[i].strength = HF.Clamp(
				c.afflictions[i].strength + NT.Deltatime * 4 -- gain 4% barotrauma/s
			,0,100)
		end
	end
	}
	NT.Afflictions.nthm_tunnelvision = {max=100,update=function(c,i)
		if c.stats.stasis then return end
		if c.afflictions.diverbarotrauma.strength>30 then
			c.afflictions[i].strength = HF.Clamp(
				c.afflictions[i].strength + NT.Deltatime * 0.78 -- gain 0.78% strength/s
			,0,100)
        else
			c.afflictions[i].strength = HF.Clamp(
				c.afflictions[i].strength - NT.Deltatime * 0.78 -- lose 0.78% strength/s
			,0,100)
		end
	end
	}
	NT.Afflictions.nthm_sym_musclejerks = {update=function(c,i)
		c.afflictions[i].strength = HF.BoolToNum(
			not NTC.GetSymptomFalse(c.character,i) and (NTC.GetSymptom(c.character,i)
			or (c.afflictions.hypercapnia.strength>0 and c.afflictions.hypercapnia.strength < 31)),2)
		
		if (c.afflictions[i].strength > 0.1) then
			for type in limbtypes do
				if(HF.Chance(0.2)) then 
					HF.AddAfflictionLimb(c.character,"spasm",type,10)
				end
			end
		end
	end
	}
	NT.Afflictions.nthm_sym_panic = {update=function(c,i)
		c.afflictions[i].strength = HF.BoolToNum(
		not NTC.GetSymptomFalse(c.character,i) and 
		(NTC.GetSymptom(c.character,i) or 
		(not c.afflictions.sym_unconsciousness.strength>0 and c.afflictions.hypercapnia.strength>60 and c.afflictions.hypercapnia.strength < 100)),2)end
	}
	NT.Afflictions.nthm_sym_diverfleas={update=function(c,i)
		c.afflictions[i].strength = HF.BoolToNum(
			not NTC.GetSymptomFalse(c.character,i) and (NTC.GetSymptom(c.character,i)
			or (not c.afflictions.sym_unconsciousness.strength>0 and c.afflictions.caissondisease.strength>0 and c.afflictions.caissondisease.strength < 31)),2)
		
		if (c.afflictions[i].strength > 0.1) then
			for type in limbtypes do
				if(HF.Chance(0.1)) then 
					HF.AddAfflictionLimb(c.character,"spasm",type,10)
				end
			end
		end
	end
	}
	NT.Afflictions.nthm_sym_disoriented = {update=function(c,i)
		c.afflictions[i].strength = HF.BoolToNum(
		not NTC.GetSymptomFalse(c.character,i) and 
		(NTC.GetSymptom(c.character,i) or 
		(not c.afflictions.sym_unconsciousness.strength>0 and ((c.afflictions.caissondisease.strength>30 and c.afflictions.caissondisease.strength < 61) or
		c.afflictions.diverbarotrauma.strength>50))),2)end
	}
	NT.Afflictions.nthm_sym_hyposphagma = {update=function(c,i)
		c.afflictions[i].strength = HF.BoolToNum(
			not NTC.GetSymptomFalse(c.character,i) and (NTC.GetSymptom(c.character,i)
			or c.afflictions.diverbarotrauma.strength>30),2)
	end
	}
	NT.Afflictions.nthm_sym_euphoria = {update=function(c,i)
		c.afflictions[i].strength = HF.BoolToNum(
		not NTC.GetSymptomFalse(c.character,i) and 
		(NTC.GetSymptom(c.character,i) or 
		(not c.afflictions.sym_unconsciousness.strength>0 and c.afflictions.diversrapture.strength>0)),2)end
	}
end,1)