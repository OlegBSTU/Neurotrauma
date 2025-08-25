-- Neurotrauma Medical Fatigue - Surgical Hooks
-- Hooks into existing surgical procedures to add fatigue integration
---@diagnostic disable: lowercase-global, undefined-global

NT.SurgicalHooks = {}

-- Store original surgical functions
NT.SurgicalHooks.OriginalMethods = {}

-- Initialize surgical hooks
function NT.SurgicalHooks.Initialize()
    -- Wait for main NT items to load first
    Timer.Wait(function()
        NT.SurgicalHooks.HookSurgicalProcedures()
    end, 2000)
    
    print("NT Surgical Hooks initialized")
end

-- Hook into all surgical procedures
function NT.SurgicalHooks.HookSurgicalProcedures()
    if not NT.ItemMethods then
        print("NT.ItemMethods not available yet, retrying...")
        Timer.Wait(function()
            NT.SurgicalHooks.HookSurgicalProcedures()
        end, 1000)
        return
    end
    
    -- List of surgical procedures to hook
    local surgicalProcedures = {
        "advscalpel",
        "advhemostat", 
        "advretractors",
        "tweezers",
        "surgerysaw",
        "surgicaldrill",
        "suture",
        "osteosynthesisimplants",
        "spinalimplant",
        "organscalpel_liver",
        "organscalpel_kidneys",
        "organscalpel_lungs", 
        "organscalpel_heart",
        "organscalpel_brain"
    }
    
    -- Hook each procedure
    for _, procedure in ipairs(surgicalProcedures) do
        if NT.ItemMethods[procedure] then
            NT.SurgicalHooks.HookProcedure(procedure)
        end
    end
    
    print("Hooked " .. #surgicalProcedures .. " surgical procedures for fatigue integration")
end

-- Hook a specific surgical procedure
function NT.SurgicalHooks.HookProcedure(procedureName)
    -- Store original method
    NT.SurgicalHooks.OriginalMethods[procedureName] = NT.ItemMethods[procedureName]
    
    -- Create wrapped version
    NT.ItemMethods[procedureName] = function(item, usingCharacter, targetCharacter, limb)
        -- Pre-procedure checks
        local canProceed = NT.SurgicalHooks.PreProcedureCheck(usingCharacter, targetCharacter, procedureName)
        if not canProceed then
            return
        end
        
        -- Check for fatigue-induced error BEFORE the procedure
        local errorOccurred = false
        if NT.SurgicalFatigue and NT.SurgicalFatigue.CheckSurgicalError then
            errorOccurred = NT.SurgicalFatigue.CheckSurgicalError(usingCharacter)
        end
        
        local success = true
        
        if errorOccurred then
            -- Apply error effects instead of normal procedure
            if NT.SurgicalFatigue and NT.SurgicalFatigue.ApplySurgicalError then
                NT.SurgicalFatigue.ApplySurgicalError(usingCharacter, targetCharacter, limb, procedureName)
            end
            success = false
        else
            -- Call original procedure
            if NT.SurgicalHooks.OriginalMethods[procedureName] then
                NT.SurgicalHooks.OriginalMethods[procedureName](item, usingCharacter, targetCharacter, limb)
            end
        end
        
        -- Post-procedure fatigue application
        NT.SurgicalHooks.PostProcedureEffects(usingCharacter, targetCharacter, procedureName, success)
    end
end

-- Pre-procedure checks and warnings
function NT.SurgicalHooks.PreProcedureCheck(surgeon, patient, procedureName)
    if not surgeon or not surgeon.IsHuman then return true end
    
    -- Check surgeon's fatigue level
    local fatigueLevel = 0
    if NT.MedicalFatigue and NT.MedicalFatigue.GetFatigueLevel then
        fatigueLevel = NT.MedicalFatigue.GetFatigueLevel(surgeon)
    end
    
    -- Warn about high fatigue before complex procedures
    if fatigueLevel >= 60 and NT.SurgicalFatigue.IsComplexProcedure(procedureName) then
        if not surgeon.IsBot then
            HF.MessageClient(surgeon, "You're quite tired. This complex procedure carries significant risk.")
        end
    end
    
    -- Check for extreme fatigue
    if fatigueLevel >= 90 then
        if not surgeon.IsBot then
            HF.MessageClient(surgeon, "You're too exhausted to perform surgery safely!")
        end
        -- Still allow the procedure but with very high error chance
    end
    
    return true  -- Always allow procedure (errors handled in the hook)
end

-- Post-procedure effects
function NT.SurgicalHooks.PostProcedureEffects(surgeon, patient, procedureName, success)
    if not surgeon or not surgeon.IsHuman then return end
    
    -- Apply procedure-specific fatigue
    if NT.SurgicalFatigue and NT.SurgicalFatigue.ApplyProcedureFatigue then
        NT.SurgicalFatigue.ApplyProcedureFatigue(surgeon, procedureName, patient, success)
    end
    
    -- Track surgery progression for UI
    NT.SurgicalHooks.UpdateSurgeryProgression(surgeon, patient, procedureName)
end

-- Update surgery progression tracking
function NT.SurgicalHooks.UpdateSurgeryProgression(surgeon, patient, procedureName)
    if not surgeon or surgeon.IsBot then return end
    
    -- Count how many surgical steps have been performed
    local surgeonId = tostring(surgeon.ID)
    if not NT.SurgicalHooks.SurgeryProgress then
        NT.SurgicalHooks.SurgeryProgress = {}
    end
    
    if not NT.SurgicalHooks.SurgeryProgress[surgeonId] then
        NT.SurgicalHooks.SurgeryProgress[surgeonId] = {
            procedures = 0,
            lastProcedure = Timer.GetTime(),
            complexity = 0
        }
    end
    
    local progress = NT.SurgicalHooks.SurgeryProgress[surgeonId]
    progress.procedures = progress.procedures + 1
    progress.lastProcedure = Timer.GetTime()
    
    -- Add complexity score
    local complexityScores = {
        advscalpel = 1,
        advhemostat = 1,
        advretractors = 1,
        suture = 1,
        tweezers = 2,
        surgicaldrill = 3,
        surgerysaw = 4,
        organscalpel_liver = 5,
        organscalpel_kidneys = 4,
        organscalpel_lungs = 5,
        organscalpel_heart = 6,
        organscalpel_brain = 7,
        osteosynthesisimplants = 3,
        spinalimplant = 4
    }
    
    progress.complexity = progress.complexity + (complexityScores[procedureName] or 1)
    
    -- Show progression messages
    if progress.procedures % 5 == 0 then  -- Every 5 procedures
        HF.MessageClient(surgeon, "You've performed " .. progress.procedures .. " surgical steps. Consider your fatigue level.")
    end
    
    if progress.complexity > 20 then  -- High complexity reached
        HF.MessageClient(surgeon, "This has been a very complex surgery. Take a break when possible.")
    end
end

-- Clean up old surgery progress data
function NT.SurgicalHooks.CleanupSurgeryProgress()
    if not NT.SurgicalHooks.SurgeryProgress then return end
    
    local currentTime = Timer.GetTime()
    local cleanupThreshold = 300000  -- 5 minutes
    
    for surgeonId, progress in pairs(NT.SurgicalHooks.SurgeryProgress) do
        if currentTime - progress.lastProcedure > cleanupThreshold then
            NT.SurgicalHooks.SurgeryProgress[surgeonId] = nil
        end
    end
end

-- Hook into character death to apply stress
Hook.Add("character.death", "NT.SurgicalHooks.OnPatientDeath", function(character)
    if not character.IsHuman then return end
    
    -- Find nearby surgeons and apply stress
    local nearbyCharacters = character.GetNearbyCharacters(500)
    for char in nearbyCharacters do
        if char.IsHuman and not char.IsDead then
            -- Check if they were performing surgery recently
            local surgeonId = tostring(char.ID)
            if NT.SurgicalHooks.SurgeryProgress and NT.SurgicalHooks.SurgeryProgress[surgeonId] then
                local progress = NT.SurgicalHooks.SurgeryProgress[surgeonId]
                local timeSinceLastProcedure = Timer.GetTime() - progress.lastProcedure
                
                -- If they performed surgery on this patient within the last 2 minutes
                if timeSinceLastProcedure < 120000 then
                    if NT.MedicalFatigue and NT.MedicalFatigue.ApplyStress then
                        NT.MedicalFatigue.ApplyStress(char, 25)  -- Significant stress from patient death
                    end
                    
                    if not char.IsBot then
                        HF.MessageClient(char, "The loss of your patient weighs heavily on you.")
                    end
                end
            end
        end
    end
end)

-- Periodic cleanup
Hook.Add("think", "NT.SurgicalHooks.Cleanup", function()
    -- Clean up every 60 seconds
    if Timer.GetTime() % 60000 < 100 then
        NT.SurgicalHooks.CleanupSurgeryProgress()
    end
end)

-- Initialize the hooks
NT.SurgicalHooks.Initialize()

print("NT Surgical Hooks loaded")
