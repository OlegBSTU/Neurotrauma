-- Hooks Lua event "changeFallDamage" to cause more damage and NT afflictions like fractures and artery cuts on extremities depending on severity

local function getCalculatedReductionForArmor(armor, strength, afflictionType)
    if armor == nil then return 0 end

    local reduction = 0
    local modifiers = armor.GetComponentString("Wearable").DamageModifiers

    for modifier in modifiers do
        if string.find(modifier.AfflictionIdentifiers, afflictionType) then
            reduction = strength - strength * modifier.DamageMultiplier
            break
        end
    end

    return reduction
end

local function getCalculatedReductionSuit(armor, strength, limbtype)
    if armor == nil then return 0 end

    if armor.HasTag("deepdivinglarge") or armor.HasTag("deepdiving") then
        return getCalculatedReductionForArmor(armor, strength, "blunttrauma")
    elseif armor.HasTag("clothing") and armor.HasTag("smallitem") and limbtype == LimbType.Torso then
        return getCalculatedReductionForArmor(armor, strength, "blunttrauma")
    end

    return 0
end

local function getCalculatedReductionClothes(armor, strength)
    if armor == nil then return 0 end

    if armor.HasTag("deepdiving") or armor.HasTag("diving") then
        return getCalculatedReductionForArmor(armor, strength, "blunttrauma")
    elseif armor.HasTag("clothing") and armor.HasTag("smallitem") then
        return getCalculatedReductionForArmor(armor, strength, "blunttrauma")
    end

    return 0
end

local function getCalculatedReductionHelmet(armor, strength)
    if armor == nil then return 0 end

    if armor.HasTag("smallitem") then
        return getCalculatedReductionForArmor(armor, strength, "blunttrauma")
    end

    return 0
end

local function getCalculatedConcussionReduction(armor, strength)
    if armor == nil then return 0 end

    if armor.HasTag("deepdiving") or armor.HasTag("deepdivinglarge") then
        return getCalculatedReductionForArmor(armor, strength, "concussion")
    elseif armor.HasTag("smallitem") then
        return getCalculatedReductionForArmor(armor, strength, "concussion")
    end

    return 0
end


local function doLimbDabage(character, limbtype, strength, injuryChanceMultiplier)
    local baseChance = math.max(0, (strength - 15) / 100)
    if HF.Chance(baseChance
            * NTC.GetMultiplier(character, "anyfracturechance")
            * NTConfig.Get("NT_fractureChance", 1)
            * injuryChanceMultiplier
        )
    then
        NT.BreakLimb(character, limbtype)
        if HF.Chance((strength - 2) / 60) then
            NT.ArteryCutLimb(character, limbtype) -- this is here to simulate open fractures
        end
    end

    if not NT.LimbIsAmputated(character, limbtype) then
        if HF.Chance(HF.Clamp((strength - 5) / 120, 0, 0.5)
                * NTC.GetMultiplier(character, "dislocationchance")
                * NTConfig.Get("NT_dislocationChance", 1)
                * injuryChanceMultiplier
            )
        then
            NT.DislocateLimb(character, limbtype)
        end
    end
end

local function doHeadDamage(character, limbtype, strength, injuryChanceMultiplier, armor1, armor2)
    if strength < 5 then return end

    local baseConcussionChance = math.min(strength / 100, 0.7)
    local baseFractureChance = math.min((strength - 15) / 100, 0.7)
    local baseSevereFractureChance = math.min((strength - 55) / 100, 0.7)

    local multiplier = NTC.GetMultiplier(character, "anyfracturechance")
        * NTConfig.Get("NT_fractureChance", 1)
        * injuryChanceMultiplier

    if HF.Chance(0.7) then
        HF.AddAffliction(character, "cerebralhypoxia", strength * HF.RandomRange(0.1, 0.4))
    end

    if strength >= 15 then
        if HF.Chance(baseConcussionChance) then
            HF.AddAfflictionResisted(character, "concussion",
                math.max(
                    10 - getCalculatedConcussionReduction(armor1, 10)
                    - getCalculatedConcussionReduction(armor2, 10),
                    0
                )
            )
        end

        if HF.Chance(baseFractureChance * multiplier) then
            NT.BreakLimb(character, limbtype)
        end

        if strength >= 55 and HF.Chance(baseSevereFractureChance * multiplier) then
            HF.AddAffliction(character, "n_fracture", 5)
        end
    end
end

local function doTorsoDamage(character, limbtype, strength, injuryChanceMultiplier)
    local baseChance = math.max(0, (strength - 15) / 100)
    local multiplier = NTC.GetMultiplier(character, "anyfracturechance") * NTConfig.Get("NT_fractureChance", 1)
    local finalChance = baseChance * multiplier * injuryChanceMultiplier

    if HF.Chance(finalChance) then
        NT.BreakLimb(character, limbtype)

        if not HF.HasAffliction(character, "lungremoved") then
            local pneumothoraxChance = (strength / 70) * NTC.GetMultiplier(character, "pneumothoraxchance")
            pneumothoraxChance = pneumothoraxChance * NTConfig.Get("NT_pneumothoraxChance", 1)

            if strength >= 5 and HF.Chance(pneumothoraxChance) then
                HF.AddAffliction(character, "pneumothorax", 5)
            end
        end
    end
end

--- Function for calculating fall damage depending on limb type and impact force.
--- Takes into account armor, clothing and helmet protection.
---
--- @param character Character - The character receiving damage.
--- @param limbtype LimbType - The type of limb that was hit (e.g. head, torso, limbs).
--- @param strength number - The impact force that will be reduced depending on protection.
NT.CauseFallDamage = function(character, limbtype, strength)
    local armor1 = character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
    local armor2 = character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
    if limbtype ~= LimbType.Head then
        strength = math.max(
            strength - getCalculatedReductionSuit(armor1, strength, limbtype)
            - getCalculatedReductionClothes(armor2, strength),
            0
        )
    else
        armor2 = character.Inventory.GetItemInLimbSlot(InvSlotType.Head)
        strength = math.max(
            strength - getCalculatedReductionSuit(armor1, strength, limbtype)
            - getCalculatedReductionHelmet(armor2, strength),
            0
        )
    end

    HF.AddAfflictionLimb(character, "blunttrauma", limbtype, strength)
    if strength < 1 then return end

    local injuryChanceMultiplier = NTConfig.Get("NT_falldamageSeriousInjuryChance", 1)

    if limbtype == LimbType.Torso then
        doTorsoDamage(character, limbtype, strength, injuryChanceMultiplier)
    end

    if limbtype == LimbType.Head then
        doHeadDamage(character, limbtype, strength, injuryChanceMultiplier, armor1, armor2)
    end

    if HF.LimbIsExtremity(limbtype) then
        doLimbDabage(character, limbtype, strength, injuryChanceMultiplier)
    end
end


Hook.Add("changeFallDamage", "NT.falldamage", function(impactDamage, character, impactPos, velocity)
    -- dont bother with creatures
    if not character.IsHuman then return end

    -- dont apply fall damage in water
    if character.InWater then return 0 end

    -- dont apply fall damage when dragged by someone
    if character.SelectedBy ~= nil then return 0 end

    local velocityMagnitude = HF.Magnitude(velocity)
    velocityMagnitude = velocityMagnitude ^ 1.5

    -- apply fall damage to all limbs based on fall direction
    local mainlimbPos = character.AnimController.MainLimb.WorldPosition

    local limbDotResults = {}
    local minDotRes = 1000

    for limb in character.AnimController.Limbs do
        for type, _ in pairs(NTTypes.LimbTypes) do
            if limb.type == type then
                -- fetch the direction of each limb relative to the torso
                local limbPosition = limb.WorldPosition
                local posDif = limbPosition - mainlimbPos
                posDif.X = posDif.X / 100
                posDif.Y = posDif.Y / 100
                local posDifMagnitude = HF.Magnitude(posDif)
                if posDifMagnitude > 1 then
                    posDif.Normalize()
                end

                local normalizedVelocity = Vector2(velocity.X, velocity.Y)
                normalizedVelocity.Normalize()

                -- compare those directions to the direction we're moving
                -- this will later be used to hurt the limbs facing impact more than the others
                local limbDot = Vector2.Dot(posDif, normalizedVelocity)
                limbDotResults[type] = limbDot
                if minDotRes > limbDot then minDotRes = limbDot end
                break
            end
        end
    end

    -- shift all weights out of the negatives
    -- increase the weight of all limbs if speed is high
    -- the effect of this is that, at higher speeds, all limbs take damage instead of mainly the ones facing the impact site
    for type, dotResult in pairs(limbDotResults) do
        limbDotResults[type] = dotResult - minDotRes + math.max(0, (velocityMagnitude - 30) / 10)
    end

    -- count weight so we're able to distribute the damage fractionally
    local weightsum = 0
    for dotResult in limbDotResults do
        weightsum = weightsum + dotResult
    end

    for type, dotResult in pairs(limbDotResults) do
        local relativeWeight = dotResult / weightsum

        local damageInflictedToThisLimb =
            relativeWeight * math.max(0, velocityMagnitude - 10) ^ 1.5
            * NTConfig.Get("NT_falldamage", 1)
            * 0.5
        NT.CauseFallDamage(character, type, damageInflictedToThisLimb)
    end

    -- make the normal damage not run
    return 0
end)
