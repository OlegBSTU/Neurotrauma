-- Neurotrauma Medical Fatigue UI System
-- Client-side UI for displaying fatigue and stress levels
---@diagnostic disable: lowercase-global, undefined-global

NT.FatigueUI = {}

-- UI Configuration
NT.FatigueUI.Config = {
    UI_UPDATE_INTERVAL = 500,  -- Update every 500ms
    BAR_WIDTH = 200,
    BAR_HEIGHT = 20,
    ICON_SIZE = 32,
    MARGIN = 10,
    ALPHA_FADE_SPEED = 2.0,
}

-- UI State
NT.FatigueUI.State = {
    initialized = false,
    visible = true,
    alpha = 1.0,
    lastUpdate = 0,
    currentFatigue = 0,
    currentStress = 0,
    tremor = 0,
}

-- UI Elements
NT.FatigueUI.Elements = {
    frame = nil,
    fatigueBar = nil,
    stressBar = nil,
    fatigueIcon = nil,
    stressIcon = nil,
    fatigueText = nil,
    stressText = nil,
    warningText = nil,
}

-- Color schemes for different levels
NT.FatigueUI.Colors = {
    fatigue = {
        low = Color(100, 255, 100, 255),      -- Green
        medium = Color(255, 255, 100, 255),   -- Yellow  
        high = Color(255, 150, 100, 255),     -- Orange
        extreme = Color(255, 100, 100, 255),  -- Red
    },
    stress = {
        low = Color(100, 200, 255, 255),      -- Light Blue
        medium = Color(150, 150, 255, 255),   -- Blue
        high = Color(200, 100, 255, 255),     -- Purple
        extreme = Color(255, 100, 200, 255),  -- Pink
    },
    background = Color(0, 0, 0, 180),
    text = Color(255, 255, 255, 255),
}

-- Initialize the UI
function NT.FatigueUI.Initialize()
    if NT.FatigueUI.State.initialized then return end
    
    -- Create main frame
    NT.FatigueUI.Elements.frame = GUI.Frame(GUI.RectTransform(Vector2(300, 120), GUI.Canvas, GUI.Anchor.TopRight), "")
    NT.FatigueUI.Elements.frame.CanBeFocused = false
    NT.FatigueUI.Elements.frame.Color = NT.FatigueUI.Colors.background
    
    local frameRect = NT.FatigueUI.Elements.frame.RectTransform
    frameRect.AbsoluteOffset = Vector2(-20, 100)  -- Position from top-right
    
    -- Create fatigue section
    NT.FatigueUI.CreateFatigueSection()
    
    -- Create stress section  
    NT.FatigueUI.CreateStressSection()
    
    -- Create warning text
    NT.FatigueUI.CreateWarningSection()
    
    NT.FatigueUI.State.initialized = true
    print("NT Medical Fatigue UI initialized")
end

-- Create fatigue display section
function NT.FatigueUI.CreateFatigueSection()
    local yOffset = 10
    
    -- Fatigue icon
    NT.FatigueUI.Elements.fatigueIcon = GUI.GUIImage(
        GUI.RectTransform(Vector2(24, 24), NT.FatigueUI.Elements.frame.RectTransform, GUI.Anchor.TopLeft),
        "Content/UI/MainIconsAtlas.png",  -- Using existing game icon
        ""
    )
    NT.FatigueUI.Elements.fatigueIcon.RectTransform.AbsoluteOffset = Vector2(10, yOffset)
    
    -- Fatigue text
    NT.FatigueUI.Elements.fatigueText = GUI.GUITextBlock(
        GUI.RectTransform(Vector2(80, 20), NT.FatigueUI.Elements.frame.RectTransform, GUI.Anchor.TopLeft),
        "Fatigue: 0%",
        Color.White,
        GUI.Alignment.CenterLeft,
        ""
    )
    NT.FatigueUI.Elements.fatigueText.RectTransform.AbsoluteOffset = Vector2(40, yOffset)
    NT.FatigueUI.Elements.fatigueText.Font = GUI.SmallFont
    
    -- Fatigue bar background
    local fatigueBarBg = GUI.GUIFrame(
        GUI.RectTransform(Vector2(NT.FatigueUI.Config.BAR_WIDTH, NT.FatigueUI.Config.BAR_HEIGHT), 
                         NT.FatigueUI.Elements.frame.RectTransform, GUI.Anchor.TopLeft),
        ""
    )
    fatigueBarBg.RectTransform.AbsoluteOffset = Vector2(40, yOffset + 25)
    fatigueBarBg.Color = Color(50, 50, 50, 255)
    
    -- Fatigue bar
    NT.FatigueUI.Elements.fatigueBar = GUI.GUIFrame(
        GUI.RectTransform(Vector2(0, NT.FatigueUI.Config.BAR_HEIGHT), fatigueBarBg.RectTransform, GUI.Anchor.TopLeft),
        ""
    )
    NT.FatigueUI.Elements.fatigueBar.Color = NT.FatigueUI.Colors.fatigue.low
end

-- Create stress display section
function NT.FatigueUI.CreateStressSection()
    local yOffset = 60
    
    -- Stress icon
    NT.FatigueUI.Elements.stressIcon = GUI.GUIImage(
        GUI.RectTransform(Vector2(24, 24), NT.FatigueUI.Elements.frame.RectTransform, GUI.Anchor.TopLeft),
        "Content/UI/MainIconsAtlas.png",  -- Using existing game icon
        ""
    )
    NT.FatigueUI.Elements.stressIcon.RectTransform.AbsoluteOffset = Vector2(10, yOffset)
    
    -- Stress text
    NT.FatigueUI.Elements.stressText = GUI.GUITextBlock(
        GUI.RectTransform(Vector2(80, 20), NT.FatigueUI.Elements.frame.RectTransform, GUI.Anchor.TopLeft),
        "Stress: 0%",
        Color.White,
        GUI.Alignment.CenterLeft,
        ""
    )
    NT.FatigueUI.Elements.stressText.RectTransform.AbsoluteOffset = Vector2(40, yOffset)
    NT.FatigueUI.Elements.stressText.Font = GUI.SmallFont
    
    -- Stress bar background
    local stressBarBg = GUI.GUIFrame(
        GUI.RectTransform(Vector2(NT.FatigueUI.Config.BAR_WIDTH, NT.FatigueUI.Config.BAR_HEIGHT), 
                         NT.FatigueUI.Elements.frame.RectTransform, GUI.Anchor.TopLeft),
        ""
    )
    stressBarBg.RectTransform.AbsoluteOffset = Vector2(40, yOffset + 25)
    stressBarBg.Color = Color(50, 50, 50, 255)
    
    -- Stress bar
    NT.FatigueUI.Elements.stressBar = GUI.GUIFrame(
        GUI.RectTransform(Vector2(0, NT.FatigueUI.Config.BAR_HEIGHT), stressBarBg.RectTransform, GUI.Anchor.TopLeft),
        ""
    )
    NT.FatigueUI.Elements.stressBar.Color = NT.FatigueUI.Colors.stress.low
end

-- Create warning section
function NT.FatigueUI.CreateWarningSection()
    NT.FatigueUI.Elements.warningText = GUI.GUITextBlock(
        GUI.RectTransform(Vector2(280, 30), NT.FatigueUI.Elements.frame.RectTransform, GUI.Anchor.BottomCenter),
        "",
        Color.Red,
        GUI.Alignment.Center,
        ""
    )
    NT.FatigueUI.Elements.warningText.RectTransform.AbsoluteOffset = Vector2(0, -5)
    NT.FatigueUI.Elements.warningText.Font = GUI.SmallFont
    NT.FatigueUI.Elements.warningText.Visible = false
end

-- Get color based on level
function NT.FatigueUI.GetLevelColor(level, colorSet)
    if level >= 75 then
        return colorSet.extreme
    elseif level >= 50 then
        return colorSet.high
    elseif level >= 25 then
        return colorSet.medium
    else
        return colorSet.low
    end
end

-- Get status text based on level
function NT.FatigueUI.GetStatusText(level, isStress)
    local status = ""
    if level >= 75 then
        status = isStress and "BURNOUT" or "EXHAUSTED"
    elseif level >= 50 then
        status = isStress and "HIGH STRESS" or "VERY TIRED"
    elseif level >= 25 then
        status = isStress and "STRESSED" or "TIRED"
    else
        status = isStress and "CALM" or "ALERT"
    end
    return status
end

-- Calculate fatigue level from afflictions
function NT.FatigueUI.CalculateFatigueLevel()
    local character = Character.Controlled
    if not character or not character.IsHuman then return 0 end
    
    local total = 0
    local afflictions = {"medical_fatigue_light", "medical_fatigue_moderate", "medical_fatigue_severe", "medical_fatigue_extreme"}
    
    for _, affliction in ipairs(afflictions) do
        local strength = HF.GetAfflictionStrength(character, affliction)
        if strength > 0 then
            total = total + strength
        end
    end
    
    return math.min(total, 100)
end

-- Calculate stress level from afflictions
function NT.FatigueUI.CalculateStressLevel()
    local character = Character.Controlled
    if not character or not character.IsHuman then return 0 end
    
    local total = 0
    local afflictions = {"medical_stress_light", "medical_stress_moderate", "medical_stress_severe", "medical_stress_extreme"}
    
    for _, affliction in ipairs(afflictions) do
        local strength = HF.GetAfflictionStrength(character, affliction)
        if strength > 0 then
            total = total + strength
        end
    end
    
    return math.min(total, 100)
end

-- Update the UI display
function NT.FatigueUI.Update()
    if not NT.FatigueUI.State.initialized then
        NT.FatigueUI.Initialize()
        return
    end
    
    local currentTime = Timer.GetTime()
    if currentTime - NT.FatigueUI.State.lastUpdate < NT.FatigueUI.Config.UI_UPDATE_INTERVAL then
        return
    end
    
    NT.FatigueUI.State.lastUpdate = currentTime
    
    -- Get current levels
    local fatigueLevel = NT.FatigueUI.CalculateFatigueLevel()
    local stressLevel = NT.FatigueUI.CalculateStressLevel()
    
    -- Smooth transitions
    NT.FatigueUI.State.currentFatigue = NT.FatigueUI.State.currentFatigue + (fatigueLevel - NT.FatigueUI.State.currentFatigue) * 0.1
    NT.FatigueUI.State.currentStress = NT.FatigueUI.State.currentStress + (stressLevel - NT.FatigueUI.State.currentStress) * 0.1
    
    -- Update fatigue display
    NT.FatigueUI.UpdateFatigueDisplay(NT.FatigueUI.State.currentFatigue)
    
    -- Update stress display
    NT.FatigueUI.UpdateStressDisplay(NT.FatigueUI.State.currentStress)
    
    -- Update warnings
    NT.FatigueUI.UpdateWarnings(NT.FatigueUI.State.currentFatigue, NT.FatigueUI.State.currentStress)
    
    -- Update visibility
    NT.FatigueUI.UpdateVisibility(NT.FatigueUI.State.currentFatigue, NT.FatigueUI.State.currentStress)
end

-- Update fatigue display
function NT.FatigueUI.UpdateFatigueDisplay(level)
    if not NT.FatigueUI.Elements.fatigueBar or not NT.FatigueUI.Elements.fatigueText then return end
    
    -- Update bar width
    local barWidth = (level / 100) * NT.FatigueUI.Config.BAR_WIDTH
    NT.FatigueUI.Elements.fatigueBar.RectTransform.RelativeSize = Vector2(level / 100, 1)
    
    -- Update bar color
    NT.FatigueUI.Elements.fatigueBar.Color = NT.FatigueUI.GetLevelColor(level, NT.FatigueUI.Colors.fatigue)
    
    -- Update text
    local statusText = NT.FatigueUI.GetStatusText(level, false)
    NT.FatigueUI.Elements.fatigueText.Text = string.format("Fatigue: %d%% (%s)", math.floor(level), statusText)
end

-- Update stress display
function NT.FatigueUI.UpdateStressDisplay(level)
    if not NT.FatigueUI.Elements.stressBar or not NT.FatigueUI.Elements.stressText then return end
    
    -- Update bar width
    NT.FatigueUI.Elements.stressBar.RectTransform.RelativeSize = Vector2(level / 100, 1)
    
    -- Update bar color
    NT.FatigueUI.Elements.stressBar.Color = NT.FatigueUI.GetLevelColor(level, NT.FatigueUI.Colors.stress)
    
    -- Update text
    local statusText = NT.FatigueUI.GetStatusText(level, true)
    NT.FatigueUI.Elements.stressText.Text = string.format("Stress: %d%% (%s)", math.floor(level), statusText)
end

-- Update warning messages
function NT.FatigueUI.UpdateWarnings(fatigueLevel, stressLevel)
    if not NT.FatigueUI.Elements.warningText then return end
    
    local warning = ""
    local showWarning = false
    
    if fatigueLevel >= 75 then
        warning = "⚠ EXHAUSTION RISK ⚠"
        showWarning = true
    elseif stressLevel >= 75 then
        warning = "⚠ BURNOUT RISK ⚠"
        showWarning = true
    elseif fatigueLevel >= 50 or stressLevel >= 50 then
        warning = "⚠ PERFORMANCE DEGRADED ⚠"
        showWarning = true
    end
    
    NT.FatigueUI.Elements.warningText.Text = warning
    NT.FatigueUI.Elements.warningText.Visible = showWarning
    
    -- Pulse effect for warnings
    if showWarning then
        local pulseAlpha = (math.sin(Timer.GetTime() * 0.005) + 1) * 0.5  -- Pulse between 0 and 1
        NT.FatigueUI.Elements.warningText.Color = Color(255, 100, 100, 255 * (0.5 + pulseAlpha * 0.5))
    end
end

-- Update UI visibility based on levels
function NT.FatigueUI.UpdateVisibility(fatigueLevel, stressLevel)
    if not NT.FatigueUI.Elements.frame then return end
    
    -- Show UI if player has any fatigue/stress or is medical personnel
    local shouldShow = fatigueLevel > 5 or stressLevel > 5
    
    local character = Character.Controlled
    if character and character.IsHuman then
        -- Always show if holding medical items
        if character.SelectedItem and character.SelectedItem.HasTag("medical") then
            shouldShow = true
        end
        
        -- Always show if in medical job
        if character.JobIdentifier and (character.JobIdentifier == "medicaldoctor" or character.JobIdentifier == "assistant") then
            shouldShow = true
        end
    end
    
    -- Smooth fade in/out
    local targetAlpha = shouldShow and 1.0 or 0.0
    NT.FatigueUI.State.alpha = NT.FatigueUI.State.alpha + (targetAlpha - NT.FatigueUI.State.alpha) * 0.1
    
    NT.FatigueUI.Elements.frame.Color = Color(0, 0, 0, 180 * NT.FatigueUI.State.alpha)
    NT.FatigueUI.Elements.frame.Visible = NT.FatigueUI.State.alpha > 0.1
end

-- Toggle UI visibility
function NT.FatigueUI.ToggleVisibility()
    NT.FatigueUI.State.visible = not NT.FatigueUI.State.visible
    if NT.FatigueUI.Elements.frame then
        NT.FatigueUI.Elements.frame.Visible = NT.FatigueUI.State.visible
    end
end

-- Hook into game update loop
Hook.Add("think", "NT.FatigueUI.Update", function()
    NT.FatigueUI.Update()
end)

-- Initialize when character spawns
Hook.Add("character.created", "NT.FatigueUI.OnCharacterSpawn", function(character)
    if character == Character.Controlled then
        Timer.Wait(function()
            NT.FatigueUI.Initialize()
        end, 1000)
    end
end)

print("NT Medical Fatigue UI system loaded")
