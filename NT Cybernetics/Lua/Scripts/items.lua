
Hook.Add("item.applyTreatment", "NTCyb.itemused", function(item, usingCharacter, targetCharacter, limb)
    local identifier = item.Prefab.Identifier.Value

    local methodtorun = NTCyb.ItemMethods[identifier] -- get the function associated with the identifer
    if(methodtorun~=nil) then 
         -- run said function
        methodtorun(item, usingCharacter, targetCharacter, limb)
        return
    end

    -- startswith functions
    for key,value in pairs(NTCyb.ItemStartsWithMethods) do 
        if HF.StartsWith(identifier,key) then
            value(item, usingCharacter, targetCharacter, limb)
            return
        end
    end

end)

local function forceSyncAfflictions(character)
    -- force sync afflictions, as normally they aren't synced for dead characters
    Networking.CreateEntityEvent(character, Character.CharacterStatusEventData.__new(true))
end

-- storing all of the item-specific functions in a table
NTCyb.ItemMethods = {} -- with the identifier as the key
NTCyb.ItemStartsWithMethods = {} -- with the start of the identifier as the key

NTCyb.ItemMethods.fpgacircuit = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = HF.NormalizeLimbType(limb.type)

    if not NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    local limbDamage = HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"ntc_damagedelectronics",0)
    if limbDamage < 0.1 then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"electrical",40)) then
        HF.AddAfflictionLimb(targetCharacter,"ntc_damagedelectronics",limbtype,-50)
        item.Condition = item.Condition - math.min(item.Condition, math.min(limbDamage, 50)*2)
    else
        HF.AddAfflictionLimb(targetCharacter,"ntc_damagedelectronics",limbtype,-20)
        item.Condition = item.Condition - math.min(item.Condition, math.min(limbDamage, 20)*4)
    end
    forceSyncAfflictions(targetCharacter)

    HF.GiveItem(targetCharacter,"ntcsfx_screwdriver")
    if item.Condition <= 0 then
        HF.RemoveItem(item)
    end
end

NTCyb.ItemMethods.steel = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = HF.NormalizeLimbType(limb.type)

    if not NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    local limbDamage = HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"ntc_materialloss",0)
    if limbDamage < 0.1 then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",60)) then
        HF.AddAfflictionLimb(targetCharacter,"ntc_materialloss",limbtype,-50)
        item.Condition = item.Condition - math.min(item.Condition, math.min(limbDamage, 50)*2)
    else
        HF.AddAfflictionLimb(targetCharacter,"ntc_materialloss",limbtype,-20)
        item.Condition = item.Condition - math.min(item.Condition, math.min(limbDamage, 20)*4)
    end
    forceSyncAfflictions(targetCharacter)

    if math.random() < 0.5 then 
        HF.GiveItem(targetCharacter,"ntcsfx_screwdriver") else 
        HF.GiveItem(targetCharacter,"ntcsfx_welding") end
    if item.Condition <= 0 then
        HF.RemoveItem(item)
    end
end

NTCyb.ItemMethods.weldingtool = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = HF.NormalizeLimbType(limb.type)

    if not NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    if HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"ntc_bentmetal",0) < 0.1 then return end

    local containedItem = item.OwnInventory.GetItemAt(0)
    if containedItem==nil then return end
    local hasFuel = containedItem.HasTag("weldingtoolfuel") and containedItem.Condition > 0
    if not hasFuel then return end

    Timer.Wait(function()
        NTCyb.ConvertDamageTypes(targetCharacter,limbtype)
        if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",50)) then
            HF.AddAfflictionLimb(targetCharacter,"ntc_bentmetal",limbtype,-20)
        else
            HF.AddAfflictionLimb(targetCharacter,"ntc_bentmetal",limbtype,-5)
        end
        forceSyncAfflictions(targetCharacter)
    end,1)
    

    HF.GiveItem(targetCharacter,"ntcsfx_welding")
    containedItem.Condition = containedItem.Condition-2
end

NTCyb.ItemMethods.cyberarm = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = HF.NormalizeLimbType(limb.type)

    if NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    if not NT.LimbIsSurgicallyAmputated(targetCharacter,limbtype) then return end
    if limbtype ~= LimbType.LeftArm and limbtype~=LimbType.RightArm then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",70)) then
        NTCyb.CyberifyLimb(targetCharacter,limbtype,false)
        HF.RemoveItem(item)
    else
        HF.AddAfflictionLimb(targetCharacter,"bleeding",LimbType.Torso,HF.RandomRange(15,50))
        HF.GiveItem(targetCharacter,"ntsfx_slash")
    end
end

NTCyb.ItemMethods.waterproofcyberarm = function(item, usingCharacter, targetCharacter, limb)
    local limbtype = HF.NormalizeLimbType(limb.type)

    if NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    if not NT.LimbIsSurgicallyAmputated(targetCharacter,limbtype) then return end
    if limbtype ~= LimbType.LeftArm and limbtype~=LimbType.RightArm then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",70)) then
        NTCyb.CyberifyLimb(targetCharacter,limbtype,true)
        HF.RemoveItem(item)
    else
        HF.AddAfflictionLimb(targetCharacter,"bleeding",LimbType.Torso,HF.RandomRange(15,50))
        HF.GiveItem(targetCharacter,"ntsfx_slash")
    end
end

NTCyb.ItemMethods.waterproofcyberleg = function(item, usingCharacter, targetCharacter, limb)
    local limbtype = HF.NormalizeLimbType(limb.type)

    if NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    if not NT.LimbIsSurgicallyAmputated(targetCharacter,limbtype) then return end
    if limbtype ~= LimbType.LeftLeg and limbtype~=LimbType.RightLeg then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",70)) then
        NTCyb.CyberifyLimb(targetCharacter,limbtype,true)
        HF.RemoveItem(item)
    else
        HF.AddAfflictionLimb(targetCharacter,"bleeding",LimbType.Torso,HF.RandomRange(15,50))
        HF.GiveItem(targetCharacter,"ntsfx_slash")
    end
end

NTCyb.ItemMethods.cyberleg = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = HF.NormalizeLimbType(limb.type)

    if NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    if not NT.LimbIsSurgicallyAmputated(targetCharacter,limbtype) then return end
    if limbtype ~= LimbType.LeftLeg and limbtype~=LimbType.RightLeg then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",70)) then
        NTCyb.CyberifyLimb(targetCharacter,limbtype,false)
        HF.RemoveItem(item)
    else
        HF.AddAfflictionLimb(targetCharacter,"bleeding",LimbType.Torso,HF.RandomRange(15,50))
        HF.GiveItem(targetCharacter,"ntsfx_slash")
    end
end

-- Crowbar: detaches a Cyberlimb (if skilled and intact)
NTCyb.ItemMethods.crowbar = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = HF.NormalizeLimbType(limb.type)

    if not NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end

    local isWaterproof = HF.HasAfflictionLimb(targetCharacter,"ntc_waterproof",limbtype,99)
    local isGoodCondition =
        not HF.HasAfflictionLimb(targetCharacter,"ntc_materialloss",limbtype,20)
        and not HF.HasAfflictionLimb(targetCharacter,"ntc_damagedelectronics",limbtype,20)
        and not HF.HasAfflictionLimb(targetCharacter,"ntc_bentmetal",limbtype,20)

    if isGoodCondition and (HF.GetSkillRequirementMet(usingCharacter, "mechanical", 50) or HF.GetSkillRequirementMet(usingCharacter, "medical", 70)) then
        NTCyb.UncyberifyLimb(targetCharacter,limbtype)
        HF.GiveItem(targetCharacter,"ntcsfx_cyberdeath")
        if not HF.GetSkillRequirementMet(usingCharacter, "medical", 50) then
            HF.AddAfflictionLimb(targetCharacter,"bleeding",LimbType.Torso,HF.RandomRange(10,40))
            HF.GiveItem(targetCharacter,"ntsfx_slash")
        else
            HF.AddAfflictionLimb(targetCharacter,"bleeding",LimbType.Torso,HF.RandomRange(5,10))
        end

        NT.SurgicallyAmputateLimb(targetCharacter,limbtype)
        local limbItem
        if limbtype == LimbType.LeftLeg or limbtype == LimbType.RightLeg then
            if isWaterproof then
                limbItem = "waterproofcyberleg"
            else
                limbItem = "cyberleg"
            end
        elseif limbtype == LimbType.LeftArm or limbtype == LimbType.RightArm then
            if isWaterproof then
                limbItem = "waterproofcyberarm"
            else
                limbItem = "cyberarm"
            end
        end
        if limbItem ~= nil then
            HF.GiveItem(usingCharacter,limbItem)
            HF.GiveSkill(usingCharacter,"mechanical",0.125)
        end
    elseif(HF.GetSkillRequirementMet(usingCharacter,"weapons",50)) then
        HF.AddAfflictionLimb(targetCharacter,"ntc_materialloss",limbtype,20)
    else
        HF.AddAfflictionLimb(targetCharacter,"ntc_materialloss",limbtype,10)
    end
    forceSyncAfflictions(targetCharacter)

    HF.GiveItem(targetCharacter,"ntcsfx_cyberblunt")
end

NTCyb.ItemStartsWithMethods.screwdriver = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    if not NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    if HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"ntc_loosescrews",0) < 0.1 then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",40)) then
        HF.AddAfflictionLimb(targetCharacter,"ntc_loosescrews",limbtype,-20)
    else
        HF.AddAfflictionLimb(targetCharacter,"ntc_loosescrews",limbtype,-5)
    end
    forceSyncAfflictions(targetCharacter)

    HF.GiveItem(targetCharacter,"ntcsfx_screwdriver")
end


-- overrides

Timer.Wait(function()

    NT.ItemMethods.surgerysaw = function(item, usingCharacter, targetCharacter, limb) 
        local limbtype = HF.NormalizeLimbType(limb.type)
    
        -- don't work on stasis
        if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

        -- don't work on cyber
        if(NTCyb.HF.LimbIsCyber(targetCharacter,limbtype)) then return end
    
        if(HF.CanPerformSurgeryOn(targetCharacter) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)
            and not HF.HasAfflictionLimb(targetCharacter,"bonecut",limbtype,1)
        ) then
            if(HF.GetSurgerySkillRequirementMet(usingCharacter,50)) then
                if limbtype~=LimbType.Torso then
                    HF.AddAfflictionLimb(targetCharacter,"bonecut",limbtype,1+HF.GetSurgerySkill(usingCharacter)/2,usingCharacter)
                end
            else
                HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,15,usingCharacter)
                HF.AddAfflictionLimb(targetCharacter,"internaldamage",limbtype,6,usingCharacter)
                HF.AddAfflictionLimb(targetCharacter,"lacerations",limbtype,4,usingCharacter)
            end
        end
    end

end,1000)