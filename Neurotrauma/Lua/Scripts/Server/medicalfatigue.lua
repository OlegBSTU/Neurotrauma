-- Neurotrauma Medical Fatigue System
-- Handles fatigue and stress accumulation for medical personnel during procedures
---@diagnostic disable: lowercase-global, undefined-global

NT.MedicalFatigue = {}

-- Configuration values
NT.MedicalFatigue.Config = {
    -- Fatigue gain rates
    SURGERY_FATIGUE_RATE = 2.0,           -- Per second during surgery
    BASIC_PROCEDURE_FATIGUE = 5.0,        -- Per bandage/injection
    COMPLEX_PROCEDURE_FATIGUE = 15.0,     -- Per surgery/advanced procedure
    EMERGENCY_STRESS_RATE = 1.0,          -- Per second in emergency
    
    -- Stress events
    PATIENT_DEATH_STRESS = 30.0,          -- When patient dies under care
    FAILED_PROCEDURE_STRESS = 10.0,       -- When procedure fails
    MULTIPLE_PATIENTS_STRESS = 5.0,       -- Per additional critical patient
    
    -- Natural recovery rates
    FATIGUE_NATURAL_DECAY = 0.1,          -- Per second when not working
    STRESS_NATURAL_DECAY = 0.05,          -- Per second when not stressed
    
    -- Thresholds for fatigue levels
    LIGHT_FATIGUE_THRESHOLD = 25,
    MODERATE_FATIGUE_THRESHOLD = 50,
    SEVERE_FATIGUE_THRESHOLD = 75,
    
    -- Thresholds for stress levels
    LIGHT_STRESS_THRESHOLD = 25,
    MODERATE_STRESS_THRESHOLD = 50,
    SEVERE_STRESS_THRESHOLD = 75,
    
    -- Error chances based on fatigue level
    MODERATE_ERROR_CHANCE = 0.05,         -- 5%
    SEVERE_ERROR_CHANCE = 0.15,           -- 15%
    EXTREME_ERROR_CHANCE = 0.30,          -- 30%
}

-- Track active medical procedures
NT.MedicalFatigue.ActiveProcedures = {}
NT.MedicalFatigue.LastUpdate = {}

-- Initialize fatigue tracking for a character
function NT.MedicalFatigue.InitializeCharacter(character)
    if not character or not character.IsHuman then return end
    
    local id = tostring(character.ID)
    NT.MedicalFatigue.ActiveProcedures[id] = {
        inSurgery = false,
        surgeryStartTime = 0,
        lastProcedureTime = 0,
        criticalPatients = 0,
        totalFatigue = 0,
        totalStress = 0
    }
    NT.MedicalFatigue.LastUpdate[id] = Timer.GetTime()
end

-- Get current fatigue level
function NT.MedicalFatigue.GetFatigueLevel(character)
    local totalFatigue = 0
    totalFatigue = totalFatigue + HF.GetAfflictionStrength(character, "medical_fatigue_light")
    totalFatigue = totalFatigue + HF.GetAfflictionStrength(character, "medical_fatigue_moderate")
    totalFatigue = totalFatigue + HF.GetAfflictionStrength(character, "medical_fatigue_severe")
    totalFatigue = totalFatigue + HF.GetAfflictionStrength(character, "medical_fatigue_extreme")
    return totalFatigue
end

-- Get current stress level
function NT.MedicalFatigue.GetStressLevel(character)
    local totalStress = 0
    totalStress = totalStress + HF.GetAfflictionStrength(character, "medical_stress_light")
    totalStress = totalStress + HF.GetAfflictionStrength(character, "medical_stress_moderate")
    totalStress = totalStress + HF.GetAfflictionStrength(character, "medical_stress_severe")
    totalStress = totalStress + HF.GetAfflictionStrength(character, "medical_stress_extreme")
    return totalStress
end

-- Apply fatigue based on current level
function NT.MedicalFatigue.ApplyFatigue(character, amount)
    if not character or amount <= 0 then return end
    
    local currentFatigue = NT.MedicalFatigue.GetFatigueLevel(character)
    local newFatigue = currentFatigue + amount
    
    -- Clear all current fatigue afflictions
    HF.SetAffliction(character, "medical_fatigue_light", 0)
    HF.SetAffliction(character, "medical_fatigue_moderate", 0)
    HF.SetAffliction(character, "medical_fatigue_severe", 0)
    HF.SetAffliction(character, "medical_fatigue_extreme", 0)
    
    -- Apply appropriate fatigue level
    if newFatigue >= NT.MedicalFatigue.Config.SEVERE_FATIGUE_THRESHOLD then
        HF.SetAffliction(character, "medical_fatigue_extreme", math.min(newFatigue, 100))
    elseif newFatigue >= NT.MedicalFatigue.Config.MODERATE_FATIGUE_THRESHOLD then
        HF.SetAffliction(character, "medical_fatigue_severe", math.min(newFatigue, 100))
    elseif newFatigue >= NT.MedicalFatigue.Config.LIGHT_FATIGUE_THRESHOLD then
        HF.SetAffliction(character, "medical_fatigue_moderate", math.min(newFatigue, 100))
    else
        HF.SetAffliction(character, "medical_fatigue_light", math.min(newFatigue, 100))
    end
    
    NT.MedicalFatigue.ShowFatigueWarning(character, newFatigue)
end

-- Apply stress based on current level
function NT.MedicalFatigue.ApplyStress(character, amount)
    if not character or amount <= 0 then return end
    
    local currentStress = NT.MedicalFatigue.GetStressLevel(character)
    local newStress = currentStress + amount
    
    -- Clear all current stress afflictions
    HF.SetAffliction(character, "medical_stress_light", 0)
    HF.SetAffliction(character, "medical_stress_moderate", 0)
    HF.SetAffliction(character, "medical_stress_severe", 0)
    HF.SetAffliction(character, "medical_stress_extreme", 0)
    
    -- Apply appropriate stress level
    if newStress >= NT.MedicalFatigue.Config.SEVERE_STRESS_THRESHOLD then
        HF.SetAffliction(character, "medical_stress_extreme", math.min(newStress, 100))
    elseif newStress >= NT.MedicalFatigue.Config.MODERATE_STRESS_THRESHOLD then
        HF.SetAffliction(character, "medical_stress_severe", math.min(newStress, 100))
    elseif newStress >= NT.MedicalFatigue.Config.LIGHT_STRESS_THRESHOLD then
        HF.SetAffliction(character, "medical_stress_moderate", math.min(newStress, 100))
    else
        HF.SetAffliction(character, "medical_stress_light", math.min(newStress, 100))
    end
    
    NT.MedicalFatigue.ShowStressWarning(character, newStress)
end

-- Show fatigue warning messages
function NT.MedicalFatigue.ShowFatigueWarning(character, fatigueLevel)
    if not character.IsBot then
        local message = ""
        if fatigueLevel >= 75 then
            message = "fatigue.warning.extreme"
        elseif fatigueLevel >= 50 then
            message = "fatigue.warning.severe"
        elseif fatigueLevel >= 25 then
            message = "fatigue.warning.moderate"
        elseif fatigueLevel >= 10 then
            message = "fatigue.warning.light"
        end
        
        if message ~= "" then
            HF.MessageClient(character, message)
        end
    end
end

-- Show stress warning messages
function NT.MedicalFatigue.ShowStressWarning(character, stressLevel)
    if not character.IsBot then
        local message = ""
        if stressLevel >= 75 then
            message = "stress.warning.extreme"
        elseif stressLevel >= 50 then
            message = "stress.warning.severe"
        elseif stressLevel >= 25 then
            message = "stress.warning.moderate"
        elseif stressLevel >= 10 then
            message = "stress.warning.light"
        end
        
        if message ~= "" then
            HF.MessageClient(character, message)
        end
    end
end

-- Check if character is performing medical procedures
function NT.MedicalFatigue.IsPerformingMedicalProcedure(character)
    if not character or not character.SelectedItem then return false end
    
    local item = character.SelectedItem
    local medicalTags = {"medical", "surgery", "surgerytool"}
    
    for _, tag in ipairs(medicalTags) do
        if item.HasTag(tag) then
            return true
        end
    end
    
    return false
end

-- Check if character is in surgery (has surgery incision open)
function NT.MedicalFatigue.IsInSurgery(character)
    -- Check if character is targeting someone with surgical incision
    if character.SelectedCharacter then
        return HF.HasAffliction(character.SelectedCharacter, "surgeryincision", 1)
    end
    return false
end

-- Count critical patients nearby
function NT.MedicalFatigue.CountCriticalPatients(character)
    local count = 0
    local nearbyCharacters = character.GetNearbyCharacters(500) -- 5 meter radius
    
    for char in nearbyCharacters do
        if char.IsHuman and not char.IsDead then
            -- Check for critical conditions
            if HF.HasAffliction(char, "cardiacarrest", 1) or
               HF.HasAffliction(char, "respiratoryarrest", 1) or
               HF.HasAffliction(char, "heartattack", 1) or
               HF.HasAffliction(char, "stroke", 1) or
               char.Vitality < 20 then
                count = count + 1
            end
        end
    end
    
    return count
end

-- Handle medical procedure completion
function NT.MedicalFatigue.OnMedicalProcedure(character, procedureType, success)
    if not character or not character.IsHuman then return end
    
    local fatigueAmount = 0
    local stressAmount = 0
    
    -- Determine fatigue based on procedure type
    if procedureType == "surgery" then
        fatigueAmount = NT.MedicalFatigue.Config.COMPLEX_PROCEDURE_FATIGUE
    else
        fatigueAmount = NT.MedicalFatigue.Config.BASIC_PROCEDURE_FATIGUE
    end
    
    -- Add stress if procedure failed
    if not success then
        stressAmount = NT.MedicalFatigue.Config.FAILED_PROCEDURE_STRESS
        if not character.IsBot then
            HF.MessageClient(character, "fatigue.error.surgery")
        end
    end
    
    NT.MedicalFatigue.ApplyFatigue(character, fatigueAmount)
    if stressAmount > 0 then
        NT.MedicalFatigue.ApplyStress(character, stressAmount)
    end
end

-- Handle patient death under care
function NT.MedicalFatigue.OnPatientDeath(character, patient)
    if not character or not character.IsHuman then return end
    
    -- Only apply stress if character was actively treating the patient
    if character.SelectedCharacter == patient or 
       (character.GetDistanceTo(patient) < 200 and NT.MedicalFatigue.IsPerformingMedicalProcedure(character)) then
        NT.MedicalFatigue.ApplyStress(character, NT.MedicalFatigue.Config.PATIENT_DEATH_STRESS)
    end
end

-- Check for medical errors based on fatigue
function NT.MedicalFatigue.CheckMedicalError(character)
    if not character or character.IsBot then return false end
    
    local fatigueLevel = NT.MedicalFatigue.GetFatigueLevel(character)
    local errorChance = 0
    
    if fatigueLevel >= 75 then
        errorChance = NT.MedicalFatigue.Config.EXTREME_ERROR_CHANCE
    elseif fatigueLevel >= 50 then
        errorChance = NT.MedicalFatigue.Config.SEVERE_ERROR_CHANCE
    elseif fatigueLevel >= 25 then
        errorChance = NT.MedicalFatigue.Config.MODERATE_ERROR_CHANCE
    end
    
    return math.random() < errorChance
end

-- Update fatigue system (called every second)
function NT.MedicalFatigue.Update()
    for character in Character.CharacterList do
        if character.IsHuman and not character.IsDead then
            local id = tostring(character.ID)
            
            -- Initialize if needed
            if not NT.MedicalFatigue.ActiveProcedures[id] then
                NT.MedicalFatigue.InitializeCharacter(character)
            end
            
            local data = NT.MedicalFatigue.ActiveProcedures[id]
            local currentTime = Timer.GetTime()
            local deltaTime = (currentTime - (NT.MedicalFatigue.LastUpdate[id] or currentTime)) / 1000
            
            -- Check current activity
            local isInSurgery = NT.MedicalFatigue.IsInSurgery(character)
            local isPerformingMedical = NT.MedicalFatigue.IsPerformingMedicalProcedure(character)
            local criticalPatients = NT.MedicalFatigue.CountCriticalPatients(character)
            
            -- Apply fatigue during surgery
            if isInSurgery then
                NT.MedicalFatigue.ApplyFatigue(character, NT.MedicalFatigue.Config.SURGERY_FATIGUE_RATE * deltaTime)
            end
            
            -- Apply stress from multiple critical patients
            if criticalPatients > 1 then
                local extraStress = (criticalPatients - 1) * NT.MedicalFatigue.Config.MULTIPLE_PATIENTS_STRESS * deltaTime
                NT.MedicalFatigue.ApplyStress(character, extraStress)
            end
            
            -- Natural recovery when not working
            if not isPerformingMedical and not isInSurgery then
                local currentFatigue = NT.MedicalFatigue.GetFatigueLevel(character)
                local currentStress = NT.MedicalFatigue.GetStressLevel(character)
                
                if currentFatigue > 0 then
                    NT.MedicalFatigue.ApplyFatigue(character, -NT.MedicalFatigue.Config.FATIGUE_NATURAL_DECAY * deltaTime)
                end
                
                if currentStress > 0 and criticalPatients == 0 then
                    NT.MedicalFatigue.ApplyStress(character, -NT.MedicalFatigue.Config.STRESS_NATURAL_DECAY * deltaTime)
                end
            end
            
            NT.MedicalFatigue.LastUpdate[id] = currentTime
        end
    end
end

-- Hook into medical item usage
Hook.Add("character.applyTreatment", "NT.MedicalFatigue.OnTreatment", function(character, user, limb, item)
    if user and user.IsHuman then
        local success = not NT.MedicalFatigue.CheckMedicalError(user)
        
        if item.HasTag("surgery") or item.HasTag("surgerytool") then
            NT.MedicalFatigue.OnMedicalProcedure(user, "surgery", success)
        elseif item.HasTag("medical") then
            NT.MedicalFatigue.OnMedicalProcedure(user, "basic", success)
        end
        
        -- If error occurred, reduce treatment effectiveness
        if not success then
            -- This would need to be implemented based on the specific treatment system
            HF.MessageClient(user, "fatigue.error.medication")
        end
    end
end)

-- Hook into character death
Hook.Add("character.death", "NT.MedicalFatigue.OnDeath", function(character)
    if character.IsHuman then
        -- Find nearby medical personnel and apply stress
        local nearbyCharacters = character.GetNearbyCharacters(500)
        for char in nearbyCharacters do
            if char.IsHuman and not char.IsDead then
                NT.MedicalFatigue.OnPatientDeath(char, character)
            end
        end
    end
end)

-- Start the update timer
Timer.Wait(function()
    Hook.Add("think", "NT.MedicalFatigue.Update", function()
        NT.MedicalFatigue.Update()
    end)
end, 1000)
