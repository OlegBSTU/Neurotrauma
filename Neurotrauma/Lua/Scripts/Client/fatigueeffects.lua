-- Neurotrauma Medical Fatigue Visual Effects System
-- Client-side visual effects for fatigue and stress
---@diagnostic disable: lowercase-global, undefined-global

NT.FatigueEffects = {}

-- Effect Configuration
NT.FatigueEffects.Config = {
    TREMOR_INTENSITY_MULTIPLIER = 2.0,
    FATIGUE_BLUR_MAX = 0.3,
    STRESS_DISTORTION_MAX = 0.2,
    BREATHING_SOUND_INTERVAL = 3000,  -- 3 seconds
    HEARTBEAT_SOUND_INTERVAL = 1200,  -- 1.2 seconds
    SCREEN_FADE_SPEED = 0.5,
}

-- Effect State
NT.FatigueEffects.State = {
    tremorOffset = Vector2(0, 0),
    lastTremorUpdate = 0,
    lastBreathingSound = 0,
    lastHeartbeatSound = 0,
    fadeLevel = 0,
    blurLevel = 0,
    distortionLevel = 0,
}

-- Screen overlay for fatigue effects
NT.FatigueEffects.Overlay = {
    frame = nil,
    initialized = false,
}

-- Initialize visual effects system
function NT.FatigueEffects.Initialize()
    if NT.FatigueEffects.Overlay.initialized then return end
    
    -- Create fullscreen overlay for effects
    NT.FatigueEffects.Overlay.frame = GUI.Frame(
        GUI.RectTransform(Vector2(1, 1), GUI.Canvas, GUI.Anchor.Center), 
        ""
    )
    NT.FatigueEffects.Overlay.frame.CanBeFocused = false
    NT.FatigueEffects.Overlay.frame.Color = Color(0, 0, 0, 0)
    
    NT.FatigueEffects.Overlay.initialized = true
    print("NT Fatigue Visual Effects initialized")
end

-- Calculate tremor intensity based on fatigue and stress
function NT.FatigueEffects.CalculateTremorIntensity()
    local character = Character.Controlled
    if not character or not character.IsHuman then return 0 end
    
    local tremor = 0
    
    -- Get tremor from hand tremor afflictions
    tremor = tremor + HF.GetAfflictionStrength(character, "hand_tremor_light") * 0.5
    tremor = tremor + HF.GetAfflictionStrength(character, "hand_tremor_moderate") * 1.0
    tremor = tremor + HF.GetAfflictionStrength(character, "hand_tremor_severe") * 2.0
    
    -- Get additional tremor from fatigue
    tremor = tremor + HF.GetAfflictionStrength(character, "medical_fatigue_moderate") * 0.3
    tremor = tremor + HF.GetAfflictionStrength(character, "medical_fatigue_severe") * 0.6
    tremor = tremor + HF.GetAfflictionStrength(character, "medical_fatigue_extreme") * 1.0
    
    -- Get tremor from stress
    tremor = tremor + HF.GetAfflictionStrength(character, "medical_stress_moderate") * 0.2
    tremor = tremor + HF.GetAfflictionStrength(character, "medical_stress_severe") * 0.4
    tremor = tremor + HF.GetAfflictionStrength(character, "medical_stress_extreme") * 0.6
    
    return math.min(tremor / 100, 1.0)  -- Normalize to 0-1
end

-- Calculate fatigue level for visual effects
function NT.FatigueEffects.CalculateFatigueLevel()
    local character = Character.Controlled
    if not character or not character.IsHuman then return 0 end
    
    local fatigue = 0
    fatigue = fatigue + HF.GetAfflictionStrength(character, "medical_fatigue_light") * 0.25
    fatigue = fatigue + HF.GetAfflictionStrength(character, "medical_fatigue_moderate") * 0.5
    fatigue = fatigue + HF.GetAfflictionStrength(character, "medical_fatigue_severe") * 0.75
    fatigue = fatigue + HF.GetAfflictionStrength(character, "medical_fatigue_extreme") * 1.0
    
    return math.min(fatigue / 100, 1.0)
end

-- Calculate stress level for visual effects
function NT.FatigueEffects.CalculateStressLevel()
    local character = Character.Controlled
    if not character or not character.IsHuman then return 0 end
    
    local stress = 0
    stress = stress + HF.GetAfflictionStrength(character, "medical_stress_light") * 0.25
    stress = stress + HF.GetAfflictionStrength(character, "medical_stress_moderate") * 0.5
    stress = stress + HF.GetAfflictionStrength(character, "medical_stress_severe") * 0.75
    stress = stress + HF.GetAfflictionStrength(character, "medical_stress_extreme") * 1.0
    
    return math.min(stress / 100, 1.0)
end

-- Apply hand tremor effect to cursor/aim
function NT.FatigueEffects.ApplyTremor()
    local tremorIntensity = NT.FatigueEffects.CalculateTremorIntensity()
    
    if tremorIntensity <= 0 then
        NT.FatigueEffects.State.tremorOffset = Vector2(0, 0)
        return
    end
    
    local currentTime = Timer.GetTime()
    
    -- Generate tremor offset using multiple sine waves for realistic effect
    local frequency1 = 0.008 + tremorIntensity * 0.012  -- Base frequency
    local frequency2 = 0.015 + tremorIntensity * 0.02   -- Secondary frequency
    local frequency3 = 0.025 + tremorIntensity * 0.03   -- Tertiary frequency
    
    local amplitude = tremorIntensity * NT.FatigueEffects.Config.TREMOR_INTENSITY_MULTIPLIER
    
    local offsetX = math.sin(currentTime * frequency1) * amplitude +
                   math.sin(currentTime * frequency2) * amplitude * 0.5 +
                   math.sin(currentTime * frequency3) * amplitude * 0.3
                   
    local offsetY = math.cos(currentTime * frequency1 * 1.3) * amplitude +
                   math.cos(currentTime * frequency2 * 1.1) * amplitude * 0.5 +
                   math.cos(currentTime * frequency3 * 0.9) * amplitude * 0.3
    
    NT.FatigueEffects.State.tremorOffset = Vector2(offsetX, offsetY)
    
    -- Apply tremor to camera if very severe
    if tremorIntensity > 0.7 then
        local cameraOffset = NT.FatigueEffects.State.tremorOffset * 0.3
        -- Note: Camera tremor would need to be implemented via game's camera system
        -- This is a placeholder for the effect
    end
end

-- Apply fatigue screen effects
function NT.FatigueEffects.ApplyFatigueEffects()
    local fatigueLevel = NT.FatigueEffects.CalculateFatigueLevel()
    
    if fatigueLevel <= 0 then
        NT.FatigueEffects.State.fadeLevel = 0
        NT.FatigueEffects.State.blurLevel = 0
        return
    end
    
    -- Calculate screen fade (darkness around edges)
    local targetFade = fatigueLevel * 0.3  -- Max 30% fade
    NT.FatigueEffects.State.fadeLevel = NT.FatigueEffects.State.fadeLevel + 
        (targetFade - NT.FatigueEffects.State.fadeLevel) * NT.FatigueEffects.Config.SCREEN_FADE_SPEED
    
    -- Calculate blur effect
    local targetBlur = fatigueLevel * NT.FatigueEffects.Config.FATIGUE_BLUR_MAX
    NT.FatigueEffects.State.blurLevel = NT.FatigueEffects.State.blurLevel +
        (targetBlur - NT.FatigueEffects.State.blurLevel) * NT.FatigueEffects.Config.SCREEN_FADE_SPEED
    
    -- Apply effects to overlay
    if NT.FatigueEffects.Overlay.frame then
        -- Create vignette effect for fatigue
        local vignetteAlpha = NT.FatigueEffects.State.fadeLevel * 255
        NT.FatigueEffects.Overlay.frame.Color = Color(0, 0, 0, vignetteAlpha)
    end
end

-- Apply stress visual distortion
function NT.FatigueEffects.ApplyStressEffects()
    local stressLevel = NT.FatigueEffects.CalculateStressLevel()
    
    if stressLevel <= 0 then
        NT.FatigueEffects.State.distortionLevel = 0
        return
    end
    
    -- Calculate distortion intensity
    local targetDistortion = stressLevel * NT.FatigueEffects.Config.STRESS_DISTORTION_MAX
    NT.FatigueEffects.State.distortionLevel = NT.FatigueEffects.State.distortionLevel +
        (targetDistortion - NT.FatigueEffects.State.distortionLevel) * NT.FatigueEffects.Config.SCREEN_FADE_SPEED
    
    -- Apply stress color tint (slightly red/pink for high stress)
    if NT.FatigueEffects.Overlay.frame and stressLevel > 0.5 then
        local stressTint = (stressLevel - 0.5) * 2  -- Scale from 0.5-1 to 0-1
        local tintColor = Color(255, 200, 200, stressTint * 30)  -- Light red tint
        -- Note: Color blending would need custom implementation
    end
end

-- Play fatigue-related sounds
function NT.FatigueEffects.PlayFatigueSounds()
    local currentTime = Timer.GetTime()
    local character = Character.Controlled
    if not character or not character.IsHuman then return end
    
    local fatigueLevel = NT.FatigueEffects.CalculateFatigueLevel()
    local stressLevel = NT.FatigueEffects.CalculateStressLevel()
    
    -- Heavy breathing sounds for high fatigue
    if fatigueLevel > 0.5 and (currentTime - NT.FatigueEffects.State.lastBreathingSound) > NT.FatigueEffects.Config.BREATHING_SOUND_INTERVAL then
        local breathingChance = (fatigueLevel - 0.5) * 2  -- Scale from 0.5-1 to 0-1
        if math.random() < breathingChance * 0.3 then  -- 30% chance at max fatigue
            -- Use existing cough sounds as placeholder for breathing
            local sounds = {"male_cough1", "male_cough2", "male_cough3", "female_cough1", "female_cough2"}
            local randomSound = sounds[math.random(#sounds)]
            Game.PlaySound(randomSound, character.WorldPosition, 0.3)  -- Lower volume
            NT.FatigueEffects.State.lastBreathingSound = currentTime
        end
    end
    
    -- Increased heartbeat for high stress
    if stressLevel > 0.6 and (currentTime - NT.FatigueEffects.State.lastHeartbeatSound) > NT.FatigueEffects.Config.HEARTBEAT_SOUND_INTERVAL then
        local heartbeatChance = (stressLevel - 0.6) * 2.5  -- Scale from 0.6-1 to 0-1
        if math.random() < heartbeatChance * 0.4 then  -- 40% chance at max stress
            -- Use existing pill sounds as placeholder for heartbeat
            local sounds = {"pills1", "pills2"}
            local randomSound = sounds[math.random(#sounds)]
            Game.PlaySound(randomSound, character.WorldPosition, 0.2)  -- Very low volume for heartbeat effect
            NT.FatigueEffects.State.lastHeartbeatSound = currentTime
        end
    end
end

-- Apply movement effects based on fatigue
function NT.FatigueEffects.ApplyMovementEffects()
    local character = Character.Controlled
    if not character or not character.IsHuman then return end
    
    local fatigueLevel = NT.FatigueEffects.CalculateFatigueLevel()
    
    -- Slight movement slowdown for high fatigue (already handled by afflictions)
    -- Additional subtle effects could be added here
    
    -- Stumbling effect for extreme fatigue
    if fatigueLevel > 0.8 and math.random() < 0.001 then  -- Very rare stumble
        -- Apply small random force to character - placeholder
        -- character.AddForce(Vector2(math.random(-100, 100), 0))
    end
end

-- Main update function
function NT.FatigueEffects.Update()
    if not NT.FatigueEffects.Overlay.initialized then
        NT.FatigueEffects.Initialize()
        return
    end
    
    -- Apply all visual effects
    NT.FatigueEffects.ApplyTremor()
    NT.FatigueEffects.ApplyFatigueEffects()
    NT.FatigueEffects.ApplyStressEffects()
    NT.FatigueEffects.PlayFatigueSounds()
    NT.FatigueEffects.ApplyMovementEffects()
end

-- Get current tremor offset for other systems to use
function NT.FatigueEffects.GetTremorOffset()
    return NT.FatigueEffects.State.tremorOffset
end

-- Get current fatigue blur level
function NT.FatigueEffects.GetBlurLevel()
    return NT.FatigueEffects.State.blurLevel
end

-- Hook into game update loop
Hook.Add("think", "NT.FatigueEffects.Update", function()
    NT.FatigueEffects.Update()
end)

-- Initialize when character spawns
Hook.Add("character.created", "NT.FatigueEffects.OnCharacterSpawn", function(character)
    if character == Character.Controlled then
        Timer.Wait(function()
            NT.FatigueEffects.Initialize()
        end, 1000)
    end
end)

print("NT Medical Fatigue Visual Effects system loaded")
