
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
    if Game.IsSingleplayer then return end
    -- force sync afflictions, as normally they aren't synced for dead characters
    Networking.CreateEntityEvent(character, Character.CharacterStatusEventData.__new(true))
end

-- Cyberorgans: replace your meat with more expensive but durable/beneficial tier 2 ("augmentedkidney") or tier 3 ("cyberkidney") organs
-- Augmented organs use a meat organ as an ingredient, while Cyber organs (and both Brain implants) are fully synthetic
-- Brain implants are chips inserted during surgery into the meat, not a replacement
NTCyb.OrganConfigDatas = {
    kidney = {
        limb = LimbType.Torso,
        damageAffliction = "kidneydamage",
        removedAffliction = "kidneyremoved",
        cyberAffliction = "ntc_cyberkidney",
        secondarySkillName = "mechanical",
        surgerySkillRemoval = 30,
        curedAfflictions = {},
        tier2Item = "augmentedkidney",
        tier3Item = "cyberkidney",
        baseMethod = NT.ItemMethods.organscalpel_kidneys
    },
    liver = {
        limb = LimbType.Torso,
        damageAffliction = "liverdamage",
        removedAffliction = "liverremoved",
        cyberAffliction = "ntc_cyberliver",
        secondarySkillName = "mechanical",
        surgerySkillRemoval = 40,
        curedAfflictions = {},
        tier2Item = "augmentedliver",
        tier3Item = "cyberliver",
        baseMethod = NT.ItemMethods.organscalpel_liver
    },
    lung = {
        limb = LimbType.Torso,
        damageAffliction = "lungdamage",
        removedAffliction = "lungremoved",
        cyberAffliction = "ntc_cyberlung",
        secondarySkillName = "mechanical",
        surgerySkillRemoval = 50,
        curedAfflictions = {"pneumothorax", "needlec", "respiratoryarrest", "hyperventilation", "hypoventilation"},
        tier2Item = "augmentedlung",
        tier3Item = "cyberlung",
        baseMethod = NT.ItemMethods.organscalpel_lungs
    },
    heart = {
        limb = LimbType.Torso,
        damageAffliction = "heartdamage",
        removedAffliction = "heartremoved",
        cyberAffliction = "ntc_cyberheart",
        secondarySkillName = "mechanical",
        surgerySkillRemoval = 60,
        curedAfflictions = {"tamponade", "heartattack", "cardiacarrest", "fibrillation", "tachycardia", "t_arterialcut"},
        tier2Item = "augmentedheart",
        tier3Item = "cyberheart",
        baseMethod = NT.ItemMethods.organscalpel_heart
    },
    brain = {
        limb = LimbType.Head,
        damageAffliction = nil,
        removedAffliction = nil,
        cyberAffliction = "ntc_cyberbrain",
        secondarySkillName = "electrical",
        surgerySkillRemoval = 70,
        curedAfflictions = {},
        tier2Item = "augmentedbrain",
        tier3Item = "cyberbrain",
        baseMethod = NT.ItemMethods.organscalpel_brain
    }
}

local function damageOrgan(targetCharacter, organName, damage, usingCharacter)
    if organName == "brain" then
        HF.AddAffliction(targetCharacter, "cerebralhypoxia", damage, usingCharacter)
    else
        HF.AddAffliction(targetCharacter, organName .. "damage", damage, usingCharacter) -- eg. "liverdamage"
    end
end

-- storing all of the item-specific functions in a table
NTCyb.ItemMethods = {} -- with the identifier as the key
NTCyb.ItemStartsWithMethods = {} -- with the start of the identifier as the key


NTCyb.RepairDamagedElectronics = function(item, usingCharacter, targetCharacter, limb, maxHeal, maxMaterialLoss)
    local limbtype = HF.NormalizeLimbType(limb.type)

    if not NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    local limbDamage = HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"ntc_damagedelectronics",0)
    if limbDamage < 0.1 then return end

    local amountHealed = math.min(limbDamage, maxHeal, (item.Condition / maxMaterialLoss) * maxHeal)
    item.Condition = item.Condition - math.min(item.Condition, 100 * (amountHealed/maxHeal) * (maxMaterialLoss/100))

    if(not HF.GetSkillRequirementMet(usingCharacter,"electrical",40)) then
        amountHealed = amountHealed / 2
    end
    HF.AddAfflictionLimb(targetCharacter,"ntc_damagedelectronics",limbtype,-amountHealed)
    forceSyncAfflictions(targetCharacter)
    HF.GiveSkillScaled(usingCharacter,"electrical", amountHealed*2)
    HF.GiveSkillScaled(usingCharacter,"medical", amountHealed)

    HF.GiveItem(targetCharacter,"ntcsfx_screwdriver")
    if item.Condition <= 0 then
        HF.RemoveItem(item)
    end
end

NTCyb.ItemMethods.fpgacircuit = function(item, usingCharacter, targetCharacter, limb)
    NTCyb.RepairDamagedElectronics(item, usingCharacter, targetCharacter, limb, 50, 100)
    if item.Condition <= 0 then
        HF.RemoveItem(item)
    end
end


NTCyb.RepairMaterialLoss = function(item, usingCharacter, targetCharacter, limb, maxHeal, maxMaterialLoss)
    local limbtype = HF.NormalizeLimbType(limb.type)

    if not NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    local limbDamage = HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"ntc_materialloss",0)
    if limbDamage < 0.1 then return end

    local amountHealed = math.min(limbDamage, maxHeal, (item.Condition / maxMaterialLoss) * maxHeal)
    item.Condition = item.Condition - math.min(item.Condition, 100 * (amountHealed/maxHeal) * (maxMaterialLoss/100))

    if(not HF.GetSkillRequirementMet(usingCharacter,"mechanical",60)) then
        amountHealed = amountHealed / 2
    end
    HF.AddAfflictionLimb(targetCharacter,"ntc_materialloss",limbtype,-amountHealed)
    forceSyncAfflictions(targetCharacter)
    HF.GiveSkillScaled(usingCharacter,"mechanical", amountHealed*2)
    HF.GiveSkillScaled(usingCharacter,"medical", amountHealed)

    if math.random() < 0.5 then 
        HF.GiveItem(targetCharacter,"ntcsfx_screwdriver") else 
        HF.GiveItem(targetCharacter,"ntcsfx_welding") end
end

NTCyb.ItemMethods.steel = function(item, usingCharacter, targetCharacter, limb)
    NTCyb.RepairMaterialLoss(item, usingCharacter, targetCharacter, limb, 50, 100)
    if item.Condition <= 0 then
        HF.RemoveItem(item)
    end
end
-- EK Mods compatibility
NTCyb.ItemMethods.ekutility_hullrepairkit = function(item, usingCharacter, targetCharacter, limb)
    local containedItem = item.OwnInventory.GetItemAt(0)
    if containedItem==nil then return end
	local identifier = containedItem.Prefab.Identifier.Value
    local hasFuel = identifier == "steel" and containedItem.Condition > 0
    if not hasFuel then return end

    NTCyb.RepairMaterialLoss(containedItem, usingCharacter, targetCharacter, limb, 25, 50)
    if containedItem.Condition <= 0 then
        HF.RemoveItem(containedItem)
    end
end
NTCyb.ItemMethods.ekutility_metalfoam_gun = function(item, usingCharacter, targetCharacter, limb)
    local containedItem = item.OwnInventory.GetItemAt(0)
    if containedItem==nil then return end
	local identifier = containedItem.Prefab.Identifier.Value
    local hasFuel = identifier == "ekutility_metalfoam_tank" and containedItem.Condition > 0
    if not hasFuel then return end

    NTCyb.RepairMaterialLoss(containedItem, usingCharacter, targetCharacter, limb, 50, 10)
end

NTCyb.RepairBentMetal = function(item, usingCharacter, targetCharacter, limb, maxHeal, maxMaterialLoss)
    local limbtype = HF.NormalizeLimbType(limb.type)

    if not NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    local limbDamage = HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,"ntc_bentmetal",0)
    if limbDamage < 0.1 then return end

    local amountHealed = math.min(limbDamage, maxHeal, (item.Condition / maxMaterialLoss) * maxHeal)
    item.Condition = item.Condition - math.min(item.Condition, 100 * (amountHealed/maxHeal) * (maxMaterialLoss/100))

    if(not HF.GetSkillRequirementMet(usingCharacter,"mechanical",50)) then
        amountHealed = amountHealed / 2
    end
    local oldCyberDamages = NTCyb.HF.GetAllCyberDamages(targetCharacter, limbtype) -- some mods (eg. EK) make welding torch hurt limbs, so lets record and undo any damage done this frame
    Timer.Wait(function()
        NTCyb.ConvertDamageTypes(targetCharacter,limbtype)
        NTCyb.HF.SetAllCyberDamages(targetCharacter, limbtype, oldCyberDamages)
        HF.AddAfflictionLimb(targetCharacter,"ntc_bentmetal",limbtype,-amountHealed)
        forceSyncAfflictions(targetCharacter)
    end,1)
    HF.GiveSkillScaled(usingCharacter,"mechanical", amountHealed*2)
    HF.GiveSkillScaled(usingCharacter,"medical", amountHealed)

    HF.GiveItem(targetCharacter,"ntcsfx_welding")
end

NTCyb.ItemMethods.weldingtool = function(item, usingCharacter, targetCharacter, limb)
    local containedItem = item.OwnInventory.GetItemAt(0)
    if containedItem==nil then return end
    -- weldingfuel is for Immersive Repairs WeldingTorch, mobilebattery is for EK Mods's ArcWelder
    local hasFuel = (containedItem.HasTag("weldingtoolfuel") or containedItem.HasTag("weldingfuel") or containedItem.HasTag("mobilebattery")) and containedItem.Condition > 0
    if not hasFuel then return end

    local fuelUsed = 2
	local identifier = containedItem.Prefab.Identifier.Value
	if identifier == "fulguriumbatterycell" then
		fuelUsed = 1
    end

    NTCyb.RepairBentMetal(containedItem, usingCharacter, targetCharacter, limb, 20, fuelUsed)
end
-- EK Mods compatibility
NTCyb.ItemMethods.ekutility_arcwelder = NTCyb.ItemMethods.weldingtool
NTCyb.ItemMethods.tadementoniteweldingtool = NTCyb.ItemMethods.weldingtool


NTCyb.ItemMethods.cyberarm = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = HF.NormalizeLimbType(limb.type)

    if NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    if not (NT.LimbIsSurgicallyAmputated(targetCharacter,limbtype) or HF.HasAfflictionLimb(targetCharacter,"bonecut",limbtype,99)) then return end
    if limbtype ~= LimbType.LeftArm and limbtype~=LimbType.RightArm then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",70)) then
        if not NT.LimbIsAmputated(targetCharacter,limbtype) then
            NT.SurgicallyAmputateLimbAndGenerateItem(usingCharacter, targetCharacter, limbtype)
        end
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
    if not (NT.LimbIsSurgicallyAmputated(targetCharacter,limbtype) or HF.HasAfflictionLimb(targetCharacter,"bonecut",limbtype,99)) then return end
    if limbtype ~= LimbType.LeftArm and limbtype~=LimbType.RightArm then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",70)) then
        if not NT.LimbIsAmputated(targetCharacter,limbtype) then
            NT.SurgicallyAmputateLimbAndGenerateItem(usingCharacter, targetCharacter, limbtype)
        end
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
    if not (NT.LimbIsSurgicallyAmputated(targetCharacter,limbtype) or HF.HasAfflictionLimb(targetCharacter,"bonecut",limbtype,99)) then return end
    if limbtype ~= LimbType.LeftLeg and limbtype~=LimbType.RightLeg then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",70)) then
        if not NT.LimbIsAmputated(targetCharacter,limbtype) then
            NT.SurgicallyAmputateLimbAndGenerateItem(usingCharacter, targetCharacter, limbtype)
        end
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
    if not (NT.LimbIsSurgicallyAmputated(targetCharacter,limbtype) or HF.HasAfflictionLimb(targetCharacter,"bonecut",limbtype,99)) then return end
    if limbtype ~= LimbType.LeftLeg and limbtype~=LimbType.RightLeg then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",70)) then
        if not NT.LimbIsAmputated(targetCharacter,limbtype) then
            NT.SurgicallyAmputateLimbAndGenerateItem(usingCharacter, targetCharacter, limbtype)
        end
        NTCyb.CyberifyLimb(targetCharacter,limbtype,false)
        HF.RemoveItem(item)
    else
        HF.AddAfflictionLimb(targetCharacter,"bleeding",LimbType.Torso,HF.RandomRange(15,50))
        HF.GiveItem(targetCharacter,"ntsfx_slash")
    end
end

-- Crowbar: detaches a Cyberlimb (if skilled and intact)
NTCyb.ItemStartsWithMethods.crowbar = function(item, usingCharacter, targetCharacter, limb)
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
            HF.GiveSkillScaled(usingCharacter,"mechanical",200)
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

    -- fix up minor cyber-organ damage
    for organ, organConfig in pairs(NTCyb.OrganConfigDatas) do
        -- todo: allow full repairing organs in fab, and then limit the screwdriver to only minor repairs
        if limbtype == organConfig.limb
            and HF.HasAffliction(targetCharacter, "ntc_cyber" .. organ, 1)
            and HF.HasAffliction(targetCharacter,organConfig.damageAffliction,1)
            and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)
        then
            if HF.GetSkillRequirementMet(usingCharacter,organConfig.secondarySkillName,50) then
                damageOrgan(targetCharacter, organ, -20, usingCharacter) -- heal "liverdamage"
                HF.GiveSkill(usingCharacter,organConfig.secondarySkillName,0.125)
            else
                damageOrgan(targetCharacter, organ, -5, usingCharacter)
            end
            HF.GiveItem(targetCharacter,"ntcsfx_screwdriver")

            -- possibly damage surroundings if not medically skilled
            if HF.GetSurgerySkillRequirementMet(usingCharacter,50) then
                HF.GiveSurgerySkill(usingCharacter,0.25)
            else
                HF.AddAfflictionLimb(targetCharacter,"internalbleeding",limbtype,HF.RandomRange(0,10))
                HF.GiveItem(targetCharacter,"ntsfx_slash")
            end
            return -- one organ at a time
        end
    end

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

NTCyb.ItemStartsWithMethods.repairpack = function(item, usingCharacter, targetCharacter, limb)
    NTCyb.ItemStartsWithMethods.screwdriver(item, usingCharacter, targetCharacter, limb)
    NT.ItemStartsWithMethods.wrench(item, usingCharacter, targetCharacter, limb)
end

local function possiblyRejectOrgan(targetCharacter, usingCharacter, organName)
    local rejectionchance = HF.Clamp((HF.GetAfflictionStrength(targetCharacter,"immunity",0)-10)/150*NTC.GetMultiplier(usingCharacter,"organrejectionchance"),0,1)
    if HF.Chance(rejectionchance) and NTConfig.Get("NT_organRejection",false) and not HF.HasAfflictionLimb(targetCharacter,"ntc_cyberkidney",LimbType.Torso,0.1) then
        damageOrgan(targetCharacter, organName, 100, usingCharacter)
    end
end

local function implantOrgan(item, usingCharacter, targetCharacter, limb)
    local organName
    for organ, _ in pairs(NTCyb.OrganConfigDatas) do
        if string.find(item.Prefab.Identifier.Value, organ) then
            organName = organ
            break
        end
    end
    if organName == nil then
        print("NT Cybernetics: Unknown organ " .. tostring(item.Prefab.Identifier.Value))
        return
    end
    local limbtype = limb.type
    local conditionmodifier = 0
    if (not HF.GetSkillRequirementMet(usingCharacter,NTCyb.OrganConfigDatas[organName].secondarySkillName,60)) then conditionmodifier = conditionmodifier - 20 end

    local workcondition = HF.Clamp(item.Condition+conditionmodifier,0,100)
    if(HF.HasAffliction(targetCharacter, organName .. "removed",1) and limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        -- possibly damage surroundings if not medically skilled
        if HF.GetSurgerySkillRequirementMet(usingCharacter,70) then
            HF.GiveSurgerySkill(usingCharacter,0.4)
        else
            HF.AddAfflictionLimb(targetCharacter,"internalbleeding",limbtype,HF.RandomRange(0,10))
            HF.GiveItem(targetCharacter,"ntsfx_slash")
        end
        damageOrgan(targetCharacter, organName, -(workcondition), usingCharacter) -- heal "liverdamage"
        HF.AddAffliction(targetCharacter,"organdamage",-(workcondition)/5,usingCharacter) -- heal a bit of vanilla organ damage
        HF.SetAffliction(targetCharacter, organName .. "removed",0,usingCharacter) -- clear "liverremoved"
        HF.SetAfflictionLimb(targetCharacter,"ntc_cyber" .. organName,limbtype, string.find(item.Prefab.Identifier.Value, "augmented") and 50 or 100) -- add "ntc_cyberliver", at 50% strength if its Augmented (tier 2), 100% if Cyber (tier 3)
        for _, affliction in ipairs(NTCyb.OrganConfigDatas[organName].curedAfflictions) do
            HF.SetAffliction(targetCharacter,affliction,0,usingCharacter)
        end
        HF.RemoveItem(item)

        possiblyRejectOrgan(targetCharacter, usingCharacter, organName)
    end
end
NTCyb.ItemMethods.augmentedliver = implantOrgan
NTCyb.ItemMethods.cyberliver = implantOrgan
NTCyb.ItemMethods.augmentedkidney = implantOrgan
NTCyb.ItemMethods.cyberkidney = implantOrgan
NTCyb.ItemMethods.augmentedheart = implantOrgan
NTCyb.ItemMethods.cyberheart = implantOrgan
NTCyb.ItemMethods.augmentedlung = implantOrgan
NTCyb.ItemMethods.cyberlung = implantOrgan

local function implantBrain(item, usingCharacter, targetCharacter, limb)
    local organName = "brain"
    local limbtype = limb.type
    local conditionmodifier = 0
    if (not HF.GetSkillRequirementMet(usingCharacter,NTCyb.OrganConfigDatas[organName].secondarySkillName,60)) then conditionmodifier = conditionmodifier - 20 end

    local workcondition = HF.Clamp(item.Condition+conditionmodifier,0,100)
    -- brain implants are chips inserted during surgery into the meat, so the brain must still be there
    if(not HF.HasAffliction(targetCharacter, organName .. "removed",1) and limbtype == LimbType.Head and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        -- possibly damage surroundings if not medically skilled
        if HF.GetSurgerySkillRequirementMet(usingCharacter,80) then
            HF.GiveSurgerySkill(usingCharacter,0.4)
        else
            HF.AddAfflictionLimb(targetCharacter,"internalbleeding",limbtype,HF.RandomRange(0,15))
            HF.GiveItem(targetCharacter,"ntsfx_slash")
        end
        damageOrgan(targetCharacter, organName, -(workcondition), usingCharacter) -- heal neurotrauma
        HF.AddAffliction(targetCharacter,"organdamage",-(workcondition)/5,usingCharacter) -- heal a bit of vanilla organ damage
        HF.SetAfflictionLimb(targetCharacter,"ntc_cyber" .. organName,limbtype, string.find(item.Prefab.Identifier.Value, "augmented") and 50 or 100) -- add "ntc_cyberliver", at 50% strength if its Augmented (tier 2), 100% if Cyber (tier 3)
        HF.RemoveItem(item)

        possiblyRejectOrgan(targetCharacter, usingCharacter, organName)
    end
end
NTCyb.ItemMethods.augmentedbrain = implantBrain
NTCyb.ItemMethods.cyberbrain = implantBrain

NT.ItemMethods.immunosuppressantinhaler = function(item, usingCharacter, targetCharacter, limb)
    if(HF.GetSkillRequirementMet(usingCharacter,"medical",15)) then
        HF.AddAffliction(targetCharacter,"immunosuppressantinhaler",100,usingCharacter)
    else
        HF.AddAffliction(targetCharacter,"immunosuppressantinhaler",50,usingCharacter)
    end
    item.Condition = item.Condition - 25
    if item.Condition <= 0 then
        HF.RemoveItem(item)
    end
    HF.GiveItem(targetCharacter,"ntsfx_syringe")
end


-- overrides

-- Immersive Handcuffs: allow retrieving handcuffs from dead characters (whats that have to do with this mod? nothing! but I have the power to fix it muwahaha)
NT.ItemMethods.handcuffkey = function(item, usingCharacter, targetCharacter, limb)
    if not targetCharacter.IsDead then return end -- if they're alive, the XML works fine
    if HF.HasAffliction(targetCharacter, "handcuffed") then
        HF.AddAffliction(usingCharacter, "retrievehandcuffs", 1, usingCharacter)
        HF.AddAffliction(targetCharacter, "retrievehandcuffs", 1, usingCharacter)
        targetCharacter.CharacterHealth.Update(1)
        forceSyncAfflictions(targetCharacter)
    end
end

-- Immersive Repairs compatibility
NTCyb.ItemMethods.weldingstinger = NTCyb.ItemMethods.weldingtool
NTCyb.ItemMethods.halligantool = NTCyb.ItemStartsWithMethods.crowbar

Timer.Wait(function()
    NTC.AddHematologyAffliction("immunosuppressantinhaler")

    if not HF.GiveSurgerySkill then
        -- BC compatibility with Neurotrauma until this gets merged into main
        function HF.GiveSurgerySkill(character, amount)
            if NTSP ~= nil and NTConfig.Get("NTSP_enableSurgerySkill",true) then
                HF.GiveSkill(character,"surgery",amount)
            else
                HF.GiveSkill(character,"medical",amount/4)
            end
        end
    end

    local baseSurgerySaw = NT.ItemMethods.surgerysaw
    NT.ItemMethods.surgerysaw = function(item, usingCharacter, targetCharacter, limb)
        local limbtype = HF.NormalizeLimbType(limb.type)
        -- don't work on cyber
        if(NTCyb.HF.LimbIsCyber(targetCharacter,limbtype)) then return end

        baseSurgerySaw(item, usingCharacter, targetCharacter, limb)
    end

    -- override surgery tools to work on dead characters, to allow removing cyberorgans postmortem
    local baseAdvScalpel = NT.ItemMethods.advscalpel
    NT.ItemMethods.advscalpel = function(item, usingCharacter, targetCharacter, limb)
        if targetCharacter.IsDead then
            local limbtype = limb.type
            print("scalpel limbtype: " .. tostring(limbtype) .. "vs head " .. tostring(LimbType.Head) .. " and " .. tostring(targetCharacter.AnimController.GetLimb(limbtype)))
            if targetCharacter.AnimController.GetLimb(limbtype) == nil then return end -- can't scalpel a missing head
            HF.AddAfflictionLimb(targetCharacter,"surgeryincision",limbtype,100,usingCharacter)
            HF.GiveItem(targetCharacter,"ntsfx_slash")
            forceSyncAfflictions(targetCharacter)
        else
            baseAdvScalpel(item, usingCharacter, targetCharacter, limb)
        end
    end

    local baseAdvHemostat = NT.ItemMethods.advhemostat
    NT.ItemMethods.advhemostat = function(item, usingCharacter, targetCharacter, limb)
        baseAdvHemostat(item, usingCharacter, targetCharacter, limb)
        if targetCharacter.IsDead then
            forceSyncAfflictions(targetCharacter)
        end
    end
    local baseAdvRetractors = NT.ItemMethods.advretractors
    NT.ItemMethods.advretractors = function(item, usingCharacter, targetCharacter, limb)
        if targetCharacter.IsDead then
            local limbtype = limb.type
            -- can skip clamping bleeders on corpses
            if((HF.HasAfflictionLimb(targetCharacter,"surgeryincision",limbtype,99) or HF.HasAfflictionLimb(targetCharacter,"clampedbleeders",limbtype,99)) and not HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1)) then
                HF.AddAfflictionLimb(targetCharacter,"retractedskin",limbtype,100,usingCharacter)
                forceSyncAfflictions(targetCharacter)
            end
        else
            baseAdvRetractors(item, usingCharacter, targetCharacter, limb)
        end
    end

    local function removeCyberOrgan(item, usingCharacter, targetCharacter, limb, organConfig)
        if organConfig == nil then
            print("NT Cybernetics: Unknown organscalpel: " .. tostring(item.Prefab.Identifier.Value))
            organConfig.baseMethod(item, usingCharacter, targetCharacter, limb)
            return
        end

        local limbtype = limb.type
        if limbtype ~= organConfig.limb or not HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1) then
            return
        end
        if HF.HasAfflictionLimb(targetCharacter, organConfig.cyberAffliction, limbtype) then
            local damage = HF.GetAfflictionStrength(targetCharacter,organConfig.damageAffliction,0)
            local removed = HF.GetAfflictionStrength(targetCharacter,organConfig.removedAffliction,0)
            if removed > 0 then return end

            if(HF.GetSurgerySkillRequirementMet(usingCharacter,organConfig.surgerySkillRemoval)) then
                if organConfig.removedAffliction ~= nil then
                    HF.SetAffliction(targetCharacter,organConfig.removedAffliction,100,usingCharacter)
                end
                if organConfig.damageAffliction ~= nil then
                    HF.SetAffliction(targetCharacter,organConfig.damageAffliction,100,usingCharacter)
                end

                for _, affliction in ipairs(organConfig.curedAfflictions) do
                    if HF.HasAffliction(targetCharacter,affliction) then
                        HF.SetAffliction(targetCharacter,affliction,0,usingCharacter)
                    end
                end

                HF.AddAffliction(targetCharacter,"organdamage",(100-damage)/5,usingCharacter)
                if organConfig.cyberAffliction == "ntc_cyberbrain" then
                    -- tier 2 and 3 brains are both synthetic implants
                    if HF.HasAfflictionLimb(targetCharacter,organConfig.cyberAffliction,limbtype,99) then
                        HF.GiveItemAtCondition(usingCharacter, organConfig.tier3Item, 100)
                    else
                        HF.GiveItemAtCondition(usingCharacter, organConfig.tier2Item, 100)
                    end
                elseif HF.HasAfflictionLimb(targetCharacter,organConfig.cyberAffliction,limbtype,99) then
                    -- cybernetic
                    HF.GiveItemAtCondition(usingCharacter, organConfig.tier3Item, HF.Clamp(100-damage, 1, 100))
                else
                    -- augmented
                    -- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
                    local function postSpawnFunc(args)
                        local tags = {}

                        if args.acidosis > 0 then table.insert(tags,"acid:"..tostring(HF.Round(args.acidosis)))
                        elseif args.alkalosis > 0 then table.insert(tags,"alkal:"..tostring(HF.Round(args.alkalosis))) end
                        if args.sepsis > 10 then table.insert(tags,"sepsis") end

                        local tagstring = ""
                        for index, value in ipairs(tags) do
                            tagstring = tagstring..value
                            if index < #tags then tagstring=tagstring.."," end
                        end

                        args.item.Tags = tagstring
                        args.item.Condition = args.condition
                    end
                    local params = {
                        acidosis=HF.GetAfflictionStrength(targetCharacter,"acidosis"),
                        alkalosis=HF.GetAfflictionStrength(targetCharacter,"alkalosis"),
                        sepsis=HF.GetAfflictionStrength(targetCharacter,"sepsis"),
                        condition=HF.Clamp(100-damage, 1, 100)
                    }
                    HF.GiveItemPlusFunction(organConfig.tier2Item,postSpawnFunc,params,usingCharacter)
                end
                HF.SetAfflictionLimb(targetCharacter,organConfig.cyberAffliction,limbtype,0,usingCharacter)
            else
                HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,15,usingCharacter)
                HF.AddAfflictionLimb(targetCharacter,"organdamage",limbtype,5,usingCharacter)
                HF.AddAffliction(targetCharacter,organConfig.damageAffliction,20,usingCharacter)
            end
            if targetCharacter.IsDead then
                forceSyncAfflictions(targetCharacter)
            end

            HF.GiveItem(targetCharacter,"ntsfx_slash")
        elseif not targetCharacter.IsDead then
            organConfig.baseMethod(item, usingCharacter, targetCharacter, limb)
        end
    end
    NT.ItemMethods.organscalpel_kidneys = function(p1, p2, p3, p4) removeCyberOrgan(p1, p2, p3, p4, NTCyb.OrganConfigDatas["kidney"]) end
    NT.ItemMethods.organscalpel_liver = function(p1, p2, p3, p4) removeCyberOrgan(p1, p2, p3, p4, NTCyb.OrganConfigDatas["liver"]) end
    NT.ItemMethods.organscalpel_lungs = function(p1, p2, p3, p4) removeCyberOrgan(p1, p2, p3, p4, NTCyb.OrganConfigDatas["lung"]) end
    NT.ItemMethods.organscalpel_heart = function(p1, p2, p3, p4) removeCyberOrgan(p1, p2, p3, p4, NTCyb.OrganConfigDatas["heart"]) end
    NT.ItemMethods.organscalpel_brain = function(p1, p2, p3, p4) removeCyberOrgan(p1, p2, p3, p4, NTCyb.OrganConfigDatas["brain"]) end

    table.insert(NT.BLOODTYPE, {"abcplus", 0}) -- cybernetic blood
    if NTP ~= nil and NTP.PillData ~= nil then
        NTP.PillData.items.bloodpackabcplus=NTP.PillData.items["antibloodloss2"]
    end
end, 500)
