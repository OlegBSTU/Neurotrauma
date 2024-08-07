
Timer.Wait(function()


	local tempOstImplantFunction = NT.ItemMethods.osteosynthesisimplants
	NT.ItemMethods.osteosynthesisimplants = function(item, usingCharacter, targetCharacter, limb)
		tempOstImplantFunction(item,usingCharacter,targetCharacter,limb)
		if(HF.CanPerformSurgeryOn(targetCharacter) and HF.HasAfflictionLimb(targetCharacter,"drilledbones",limbtype,99)) then
			if(HF.GetSurgerySkillRequirementMet(usingCharacter,45))
				local ostenecrosisafflictions = {
					ll_osteonecrosis={xpgain=200},
					ll_osteonecrosis={xpgain=200},
					la_osteonecrosis={xpgain=200},
					ra_osteonecrosis={xpgain=200},
				}

				for key, value in pairs(ostenecrosisafflictions) do
					local prefab = AfflictionPrefab.Prefabs[key]
					if prefab ~= nil and (value.case == nil or HF.HasAfflictionLimb(targetCharacter,value.case,limbtype)) then
						local skillgain = value.xpgain or 0
						if prefab.LimbSpecific then
							removeAfflictionPlusGainSkill(key,skillgain)
						elseif prefab.IndicatorLimb == limbtype then
							removeAfflictionNonLimbSpecificPlusGainSkill(key,skillgain)
						end
					end
				end
			end
		end
	end

    -- make it so ending surgery gets rid of stuff
    NT.SutureAfflictions.surgery_huskhealth = {}
    NT.SutureAfflictions.bonecuttorso = {}

    -- add stabbing parasites to the scalpels functionality
    local tempScalpelFunction = NT.ItemMethods.advscalpel
    NT.ItemMethods.advscalpel = function(item, usingCharacter, targetCharacter, limb)
        tempScalpelFunction(item,usingCharacter,targetCharacter,limb)

        local limbtype = HF.NormalizeLimbType(limb.type)

        -- only the torso is interesting for the husk stuff
        if limbtype ~= LimbType.Torso then return end

        -- don't work on stasis
        if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

        local huskHealth = HF.GetAfflictionStrength(targetCharacter,"surgery_huskhealth")
        local calyx = HF.GetAfflictionStrength(targetCharacter,"af_calyxanide")

        -- don't work if we're not in the "stabbing the shit out of the parasite" phase of treatment
        if huskHealth < 0.1 then return end

        if(HF.CanPerformSurgeryOn(targetCharacter)) then
            -- skill check is 30 with and 100 without calyxanide
            if(HF.GetSurgerySkillRequirementMet(usingCharacter,30 + 70 * HF.BoolToNum(calyx < 0.1))) then
                -- "treat" some husk health
                local newHuskHealth = HF.Clamp(huskHealth-10,5,100)
                HF.SetAffliction(targetCharacter,"surgery_huskhealth",newHuskHealth)
                HF.GiveItem(targetCharacter,"ntsfx_huskhurt")
            else
                if calyx < 0.1 and huskHealth > 20 then
                    -- no calyx and husk active, uh oh.

                    -- determine what limb is being retaliated against
                    local hitLimb = LimbType.RightArm
                    if
                        NT.LimbIsDislocated(usingCharacter,hitLimb) or
                        NT.LimbIsBroken(usingCharacter,hitLimb) or
                        NT.LimbIsAmputated(usingCharacter,hitLimb)
                    then hitLimb = LimbType.LeftArm end

                    HF.AddAfflictionLimb(usingCharacter,"bleeding",hitLimb,5)
                    HF.AddAfflictionLimb(usingCharacter,"bitewounds",hitLimb,10)
                    HF.AddAffliction(usingCharacter,"stun",0.2)
                    -- 20% chance of getting the unfortunate soul holding the scalpel infected
                    if HF.Chance(0.2) then
                        HF.AddAffliction(usingCharacter,"huskinfection",1)
                    end
                    HF.GiveItem(targetCharacter,"ntsfx_huskhurt")
                else
                    -- stop stabbing the patient, stupid
                    HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,10,usingCharacter)
                    HF.AddAfflictionLimb(targetCharacter,"lacerations",limbtype,10,usingCharacter)
                end
            end
        end
    end

    -- add ripping parasites out of the patients chest cavity to the hemostats functionality
    local tempHemostatFunction = NT.ItemMethods.advhemostat
    NT.ItemMethods.advhemostat = function(item, usingCharacter, targetCharacter, limb)
        tempHemostatFunction(item,usingCharacter,targetCharacter,limb)

        local limbtype = HF.NormalizeLimbType(limb.type)

        -- only the torso is interesting for the husk stuff
        if limbtype ~= LimbType.Torso then return end

        -- don't work on stasis
        if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

        local huskHealth = HF.GetAfflictionStrength(targetCharacter,"surgery_huskhealth")

        -- don't work if we're not in the "grabbing the parasite by the balls" phase of treatment
        if (huskHealth > 20) or (huskHealth < 0.1) then return end

        if(HF.CanPerformSurgeryOn(targetCharacter)) then
            if(HF.GetSurgerySkillRequirementMet(usingCharacter,30)) then
                -- rip that sucker out for good
                -- ...but first, give the patient lung damage equivalent to the remaining husk health
                HF.AddAffliction(targetCharacter,"lungdamage",huskHealth*2 + HF.Clamp(50-HF.GetSurgerySkill(usingCharacter),0,30))
                HF.SetAffliction(targetCharacter,"surgery_huskhealth",0)
                HF.SetAffliction(targetCharacter,"huskinfection",0)
                --HF.SetAffliction(targetCharacter,"husksymbiosis",0)
                HF.GiveItem(targetCharacter,"ntsfx_huskdeath")
                HF.GiveSkill(usingCharacter,"medical",3)
            else
                -- stop stabbing the patient, stupid
                HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,10,usingCharacter)
                HF.AddAfflictionLimb(targetCharacter,"lacerations",limbtype,10,usingCharacter)
            end
        end
    end

    -- add sawing torso bones to the bonesaw
    local tempSawFunction = NT.ItemMethods.surgerysaw
    NT.ItemMethods.surgerysaw = function(item, usingCharacter, targetCharacter, limb)
        tempSawFunction(item,usingCharacter,targetCharacter,limb)

        local limbtype = HF.NormalizeLimbType(limb.type)

        -- only the torso is interesting for the husk stuff
        if limbtype ~= LimbType.Torso then return end

        -- don't work on stasis
        if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

        local huskHealth = HF.GetAfflictionStrength(targetCharacter,"surgery_huskhealth")

        -- don't work if we've already cut the torso open
        if HF.HasAffliction(targetCharacter,"bonecuttorso",1) then return end

        if(HF.CanPerformSurgeryOn(targetCharacter) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)
        ) then
            if(HF.GetSurgerySkillRequirementMet(usingCharacter,50)) then
                HF.AddAffliction(targetCharacter,"bonecuttorso",1+HF.GetSurgerySkill(usingCharacter)/2,usingCharacter)
            else
                HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,15,usingCharacter)
                HF.AddAfflictionLimb(targetCharacter,"internaldamage",limbtype,6,usingCharacter)
                HF.AddAfflictionLimb(targetCharacter,"lacerations",limbtype,4,usingCharacter)
            end
        end
    end

end,2000)
