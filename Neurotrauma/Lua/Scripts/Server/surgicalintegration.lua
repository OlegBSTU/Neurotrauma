-- Neurotrauma Medical Fatigue - Surgical Integration System
-- Integrates the fatigue system directly with surgical procedures
---@diagnostic disable: lowercase-global, undefined-global

NT.SurgicalFatigue = {}

-- Fatigue costs for different surgical procedures
NT.SurgicalFatigue.ProcedureCosts = {
    -- Basic procedures
    advscalpel = 8,         -- Making incisions
    advhemostat = 5,        -- Clamping bleeding
    advretractors = 6,      -- Retracting skin
    suture = 4,             -- Suturing
    
    -- Advanced procedures
    tweezers = 12,          -- Removing foreign bodies/bullets
    surgerysaw = 20,        -- Sawing bones (very tiring)
    surgicaldrill = 15,     -- Drilling bones
    organscalpel_heart = 35,     -- Heart surgery (most complex)
    organscalpel_brain = 40,     -- Brain surgery (most complex)
    organscalpel_liver = 25,     -- Liver surgery
    organscalpel_lungs = 30,     -- Lung surgery
    organscalpel_kidneys = 20,   -- Kidney surgery
    
    -- Implants
    osteosynthesisimplants = 18, -- Bone implants
    spinalimplant = 25,          -- Spinal implants
}

-- Stress multipliers for different surgery contexts
NT.SurgicalFatigue.StressMultipliers = {
    emergency_surgery = 2.0,     -- Surgery on critical patients
    multiple_patients = 1.5,     -- Multiple patients waiting
    time_pressure = 1.3,         -- Patient losing vitality rapidly
    failed_procedure = 2.5,      -- When surgery fails
}

-- Track ongoing surgeries
NT.SurgicalFatigue.OngoingSurgeries = {}

-- Initialize surgical fatigue integration
function NT.SurgicalFatigue.Initialize()
    print("NT Surgical Fatigue Integration initialized")
end

-- Apply fatigue based on surgical procedure
function NT.SurgicalFatigue.ApplyProcedureFatigue(usingCharacter, procedureType, targetCharacter, success)
    if not usingCharacter or not usingCharacter.IsHuman then return end
    
    local baseFatigue = NT.SurgicalFatigue.ProcedureCosts[procedureType] or 5
    local baseStress = baseFatigue * 0.3  -- Base stress is 30% of fatigue
    
    -- Calculate multipliers
    local stressMultiplier = 1.0
    local fatigueMultiplier = 1.0
    
    -- Emergency surgery multiplier
    if targetCharacter and (targetCharacter.Vitality < 30 or 
        HF.HasAffliction(targetCharacter, "cardiacarrest") or
        HF.HasAffliction(targetCharacter, "respiratoryarrest")) then
        stressMultiplier = stressMultiplier * NT.SurgicalFatigue.StressMultipliers.emergency_surgery
    end
    
    -- Multiple critical patients multiplier
    local criticalPatients = NT.SurgicalFatigue.CountCriticalPatientsNearby(usingCharacter)
    if criticalPatients > 1 then
        stressMultiplier = stressMultiplier * NT.SurgicalFatigue.StressMultipliers.multiple_patients
    end
    
    -- Time pressure (patient losing vitality rapidly)
    if targetCharacter and targetCharacter.Vitality < 50 then
        local vitalityLoss = math.max(0, (50 - targetCharacter.Vitality) / 50)
        stressMultiplier = stressMultiplier * (1 + vitalityLoss * 0.5)
    end
    
    -- Failure penalty
    if not success then
        stressMultiplier = stressMultiplier * NT.SurgicalFatigue.StressMultipliers.failed_procedure
        fatigueMultiplier = fatigueMultiplier * 1.5  -- Extra fatigue from redoing procedure
    end
    
    -- Apply configuration multipliers
    if NT.FatigueConfig then
        fatigueMultiplier = fatigueMultiplier * NT.FatigueConfig.Get("SURGERY_FATIGUE_MULTIPLIER", 1.0)
        stressMultiplier = stressMultiplier * NT.FatigueConfig.Get("EMERGENCY_STRESS_MULTIPLIER", 1.0)
    end
    
    -- Calculate final amounts
    local finalFatigue = baseFatigue * fatigueMultiplier
    local finalStress = baseStress * stressMultiplier
    
    -- Apply fatigue and stress
    if NT.MedicalFatigue then
        NT.MedicalFatigue.ApplyFatigue(usingCharacter, finalFatigue)
        NT.MedicalFatigue.ApplyStress(usingCharacter, finalStress)
    end
    
    -- Show procedure-specific message
    NT.SurgicalFatigue.ShowProcedureMessage(usingCharacter, procedureType, finalFatigue, finalStress)
    
    -- Track surgery duration if applicable
    if NT.SurgicalFatigue.IsComplexProcedure(procedureType) then
        NT.SurgicalFatigue.TrackSurgeryDuration(usingCharacter, procedureType, targetCharacter)
    end
end

-- Count critical patients nearby
function NT.SurgicalFatigue.CountCriticalPatientsNearby(character)
    local count = 0
    local nearbyCharacters = character.GetNearbyCharacters(800) -- 8 meter radius
    
    for char in nearbyCharacters do
        if char.IsHuman and not char.IsDead and char ~= character then
            if char.Vitality < 30 or
               HF.HasAffliction(char, "cardiacarrest") or
               HF.HasAffliction(char, "respiratoryarrest") or
               HF.HasAffliction(char, "heartattack") or
               HF.HasAffliction(char, "stroke") then
                count = count + 1
            end
        end
    end
    
    return count
end

-- Check if procedure is complex (requires extended tracking)
function NT.SurgicalFatigue.IsComplexProcedure(procedureType)
    local complexProcedures = {
        "organscalpel_heart", "organscalpel_brain", "organscalpel_liver",
        "organscalpel_lungs", "organscalpel_kidneys", "surgerysaw",
        "osteosynthesisimplants", "spinalimplant"
    }
    
    for _, complex in ipairs(complexProcedures) do
        if procedureType == complex then
            return true
        end
    end
    return false
end

-- Track surgery duration for complex procedures
function NT.SurgicalFatigue.TrackSurgeryDuration(surgeon, procedureType, patient)
    local surgeonId = tostring(surgeon.ID)
    local currentTime = Timer.GetTime()
    
    if not NT.SurgicalFatigue.OngoingSurgeries[surgeonId] then
        NT.SurgicalFatigue.OngoingSurgeries[surgeonId] = {}
    end
    
    NT.SurgicalFatigue.OngoingSurgeries[surgeonId] = {
        procedure = procedureType,
        patient = patient,
        startTime = currentTime,
        lastFatigueTime = currentTime
    }
end

-- Update ongoing surgeries and apply continuous fatigue
function NT.SurgicalFatigue.UpdateOngoingSurgeries()
    local currentTime = Timer.GetTime()
    
    for surgeonId, surgery in pairs(NT.SurgicalFatigue.OngoingSurgeries) do
        local surgeon = Character.CharacterList[tonumber(surgeonId)]
        
        if surgeon and surgeon.IsHuman and not surgeon.IsDead then
            -- Check if surgery is still ongoing
            local stillOperating = false
            
            if surgery.patient and not surgery.patient.IsDead then
                -- Check if surgeon is still near patient and has surgery incision open
                local distance = Vector2.Distance(surgeon.WorldPosition, surgery.patient.WorldPosition)
                if distance < 200 and HF.HasAffliction(surgery.patient, "surgeryincision") then
                    stillOperating = true
                end
            end
            
            if stillOperating then
                -- Apply continuous fatigue every 10 seconds
                if currentTime - surgery.lastFatigueTime > 10000 then
                    local continuousFatigue = 3  -- Base continuous fatigue
                    local continuousStress = 1   -- Base continuous stress
                    
                    -- Increase based on surgery complexity
                    if surgery.procedure == "organscalpel_brain" or surgery.procedure == "organscalpel_heart" then
                        continuousFatigue = continuousFatigue * 2
                        continuousStress = continuousStress * 2
                    end
                    
                    -- Apply configuration multiplier
                    if NT.FatigueConfig then
                        continuousFatigue = continuousFatigue * NT.FatigueConfig.Get("SURGERY_FATIGUE_MULTIPLIER", 1.0)
                    end
                    
                    if NT.MedicalFatigue then
                        NT.MedicalFatigue.ApplyFatigue(surgeon, continuousFatigue)
                        NT.MedicalFatigue.ApplyStress(surgeon, continuousStress)
                    end
                    
                    surgery.lastFatigueTime = currentTime
                    
                    -- Show duration warning for very long surgeries
                    local surgeryDuration = (currentTime - surgery.startTime) / 60000  -- In minutes
                    if surgeryDuration > 5 and math.floor(surgeryDuration) % 2 == 0 then  -- Every 2 minutes after 5 minutes
                        if not surgeon.IsBot then
                            HF.MessageClient(surgeon, "You've been operating for " .. math.floor(surgeryDuration) .. " minutes. Consider taking a break soon.")
                        end
                    end
                end
            else
                -- Surgery ended, remove from tracking
                NT.SurgicalFatigue.OngoingSurgeries[surgeonId] = nil
            end
        else
            -- Surgeon no longer exists, clean up
            NT.SurgicalFatigue.OngoingSurgeries[surgeonId] = nil
        end
    end
end

-- Show procedure-specific fatigue message
function NT.SurgicalFatigue.ShowProcedureMessage(character, procedureType, fatigue, stress)
    if character.IsBot then return end
    
    local procedureNames = {
        advscalpel = "making the incision",
        surgerysaw = "sawing through bone",
        organscalpel_brain = "brain surgery",
        organscalpel_heart = "heart surgery",
        tweezers = "removing foreign objects",
        osteosynthesisimplants = "installing bone implants"
    }
    
    local procedureName = procedureNames[procedureType] or "the surgical procedure"
    
    if fatigue > 15 then
        HF.MessageClient(character, "The complexity of " .. procedureName .. " is quite tiring.")
    elseif stress > 10 then
        HF.MessageClient(character, "The pressure of " .. procedureName .. " is stressful.")
    end
end

-- Check if fatigue should cause surgical error
function NT.SurgicalFatigue.CheckSurgicalError(surgeon)
    if not surgeon or surgeon.IsBot then return false end
    
    -- Get fatigue level
    local fatigueLevel = 0
    if NT.MedicalFatigue then
        fatigueLevel = NT.MedicalFatigue.GetFatigueLevel(surgeon)
    end
    
    -- Calculate error chance based on fatigue
    local errorChance = 0
    if fatigueLevel >= 75 then
        errorChance = 0.25      -- 25% error chance at extreme fatigue
    elseif fatigueLevel >= 50 then
        errorChance = 0.12      -- 12% error chance at severe fatigue
    elseif fatigueLevel >= 25 then
        errorChance = 0.05      -- 5% error chance at moderate fatigue
    end
    
    -- Apply configuration multiplier
    if NT.FatigueConfig then
        errorChance = errorChance * NT.FatigueConfig.Get("ERROR_CHANCE_MULTIPLIER", 1.0)
    end
    
    return math.random() < errorChance
end

-- Apply surgical error effects
function NT.SurgicalFatigue.ApplySurgicalError(surgeon, patient, limb, procedureType)
    if not surgeon or not patient then return end
    
    -- Different error types based on procedure
    if procedureType == "advscalpel" then
        -- Scalpel error: deeper cut than intended
        HF.AddAfflictionLimb(patient, "bleeding", limb.type, 10, surgeon)
        HF.AddAfflictionLimb(patient, "lacerations", limb.type, 5, surgeon)
    elseif procedureType == "surgerysaw" then
        -- Saw error: bone fragments or nerve damage
        HF.AddAfflictionLimb(patient, "internaldamage", limb.type, 8, surgeon)
        HF.AddAfflictionLimb(patient, "bleeding", limb.type, 15, surgeon)
    elseif string.find(procedureType, "organscalpel") then
        -- Organ surgery error: organ damage
        HF.AddAffliction(patient, "organdamage", 12, surgeon)
        HF.AddAfflictionLimb(patient, "internaldamage", limb.type, 10, surgeon)
    else
        -- Generic surgical error
        HF.AddAfflictionLimb(patient, "internaldamage", limb.type, 5, surgeon)
        HF.AddAfflictionLimb(patient, "bleeding", limb.type, 8, surgeon)
    end
    
    -- Show error message
    if not surgeon.IsBot then
        HF.MessageClient(surgeon, "fatigue.error.surgery")
    end
    
    -- Apply stress from making the error
    if NT.MedicalFatigue then
        NT.MedicalFatigue.ApplyStress(surgeon, 15)
    end
end

-- Initialize the surgical integration
NT.SurgicalFatigue.Initialize()

-- Hook into surgery update loop
Hook.Add("think", "NT.SurgicalFatigue.Update", function()
    NT.SurgicalFatigue.UpdateOngoingSurgeries()
end)

print("NT Surgical Fatigue Integration loaded")
