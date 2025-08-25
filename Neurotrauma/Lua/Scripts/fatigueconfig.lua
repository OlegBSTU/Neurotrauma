-- Neurotrauma Medical Fatigue Configuration System
-- Allows players to customize fatigue system parameters
---@diagnostic disable: lowercase-global, undefined-global

NT.FatigueConfig = {}

-- Default configuration values
NT.FatigueConfig.Defaults = {
    -- System Enable/Disable
    FATIGUE_SYSTEM_ENABLED = true,
    VISUAL_EFFECTS_ENABLED = true,
    SOUND_EFFECTS_ENABLED = true,
    UI_DISPLAY_ENABLED = true,
    
    -- Fatigue Accumulation Rates
    SURGERY_FATIGUE_MULTIPLIER = 1.0,        -- Multiplier for surgery fatigue gain
    BASIC_PROCEDURE_MULTIPLIER = 1.0,        -- Multiplier for basic medical procedures
    EMERGENCY_STRESS_MULTIPLIER = 1.0,       -- Multiplier for emergency stress
    
    -- Recovery Rates
    NATURAL_RECOVERY_MULTIPLIER = 1.0,       -- Multiplier for natural recovery
    ITEM_EFFECTIVENESS_MULTIPLIER = 1.0,     -- Multiplier for recovery items
    
    -- Error System
    MEDICAL_ERRORS_ENABLED = true,           -- Enable/disable medical errors from fatigue
    ERROR_CHANCE_MULTIPLIER = 1.0,           -- Multiplier for error chance
    
    -- Visual Effects
    TREMOR_INTENSITY_MULTIPLIER = 1.0,       -- Hand tremor intensity
    SCREEN_EFFECTS_INTENSITY = 1.0,          -- Screen fade/blur intensity
    UI_SCALE = 1.0,                          -- UI element scaling
    
    -- Audio Effects
    BREATHING_SOUND_VOLUME = 0.7,            -- Volume for breathing sounds
    HEARTBEAT_SOUND_VOLUME = 0.5,            -- Volume for stress heartbeat
    SOUND_FREQUENCY_MULTIPLIER = 1.0,        -- How often sounds play
    
    -- Difficulty Presets
    DIFFICULTY_PRESET = "Normal",             -- Easy, Normal, Hard, Realistic, Custom
}

-- Current configuration (will be loaded from save or use defaults)
NT.FatigueConfig.Current = {}

-- Configuration categories for UI organization
NT.FatigueConfig.Categories = {
    {
        name = "General Settings",
        key = "general",
        entries = {
            {key = "FATIGUE_SYSTEM_ENABLED", name = "Enable Fatigue System", type = "bool", description = "Enable or disable the entire medical fatigue system"},
            {key = "DIFFICULTY_PRESET", name = "Difficulty Preset", type = "dropdown", options = {"Easy", "Normal", "Hard", "Realistic", "Custom"}, description = "Choose a preset difficulty or use custom settings"},
            {key = "VISUAL_EFFECTS_ENABLED", name = "Enable Visual Effects", type = "bool", description = "Enable screen effects like tremor and fatigue blur"},
            {key = "SOUND_EFFECTS_ENABLED", name = "Enable Sound Effects", type = "bool", description = "Enable fatigue-related sound effects"},
            {key = "UI_DISPLAY_ENABLED", name = "Enable UI Display", type = "bool", description = "Show fatigue and stress bars on screen"},
        }
    },
    {
        name = "Fatigue Mechanics",
        key = "fatigue",
        entries = {
            {key = "SURGERY_FATIGUE_MULTIPLIER", name = "Surgery Fatigue Rate", type = "float", min = 0.1, max = 3.0, step = 0.1, description = "How quickly fatigue accumulates during surgery"},
            {key = "BASIC_PROCEDURE_MULTIPLIER", name = "Basic Procedure Fatigue", type = "float", min = 0.1, max = 3.0, step = 0.1, description = "Fatigue from basic medical procedures"},
            {key = "EMERGENCY_STRESS_MULTIPLIER", name = "Emergency Stress Rate", type = "float", min = 0.1, max = 3.0, step = 0.1, description = "How quickly stress builds in emergencies"},
            {key = "NATURAL_RECOVERY_MULTIPLIER", name = "Recovery Rate", type = "float", min = 0.1, max = 3.0, step = 0.1, description = "How quickly fatigue naturally recovers"},
            {key = "ITEM_EFFECTIVENESS_MULTIPLIER", name = "Recovery Item Effectiveness", type = "float", min = 0.1, max = 3.0, step = 0.1, description = "Effectiveness of coffee, energy drinks, etc."},
        }
    },
    {
        name = "Error System",
        key = "errors",
        entries = {
            {key = "MEDICAL_ERRORS_ENABLED", name = "Enable Medical Errors", type = "bool", description = "Allow fatigue to cause medical errors"},
            {key = "ERROR_CHANCE_MULTIPLIER", name = "Error Chance Multiplier", type = "float", min = 0.0, max = 3.0, step = 0.1, description = "Multiplier for medical error probability"},
        }
    },
    {
        name = "Visual Effects",
        key = "visual",
        entries = {
            {key = "TREMOR_INTENSITY_MULTIPLIER", name = "Hand Tremor Intensity", type = "float", min = 0.0, max = 3.0, step = 0.1, description = "Intensity of hand tremor effects"},
            {key = "SCREEN_EFFECTS_INTENSITY", name = "Screen Effects Intensity", type = "float", min = 0.0, max = 2.0, step = 0.1, description = "Intensity of screen blur and fade effects"},
            {key = "UI_SCALE", name = "UI Scale", type = "float", min = 0.5, max = 2.0, step = 0.1, description = "Scale of fatigue UI elements"},
        }
    },
    {
        name = "Audio Effects",
        key = "audio",
        entries = {
            {key = "BREATHING_SOUND_VOLUME", name = "Breathing Sound Volume", type = "float", min = 0.0, max = 1.0, step = 0.1, description = "Volume of heavy breathing sounds"},
            {key = "HEARTBEAT_SOUND_VOLUME", name = "Heartbeat Sound Volume", type = "float", min = 0.0, max = 1.0, step = 0.1, description = "Volume of stress heartbeat sounds"},
            {key = "SOUND_FREQUENCY_MULTIPLIER", name = "Sound Frequency", type = "float", min = 0.1, max = 3.0, step = 0.1, description = "How often fatigue sounds play"},
        }
    }
}

-- Difficulty presets
NT.FatigueConfig.Presets = {
    Easy = {
        SURGERY_FATIGUE_MULTIPLIER = 0.5,
        BASIC_PROCEDURE_MULTIPLIER = 0.5,
        EMERGENCY_STRESS_MULTIPLIER = 0.5,
        NATURAL_RECOVERY_MULTIPLIER = 2.0,
        ITEM_EFFECTIVENESS_MULTIPLIER = 1.5,
        ERROR_CHANCE_MULTIPLIER = 0.3,
        TREMOR_INTENSITY_MULTIPLIER = 0.5,
        SCREEN_EFFECTS_INTENSITY = 0.5,
    },
    Normal = {
        SURGERY_FATIGUE_MULTIPLIER = 1.0,
        BASIC_PROCEDURE_MULTIPLIER = 1.0,
        EMERGENCY_STRESS_MULTIPLIER = 1.0,
        NATURAL_RECOVERY_MULTIPLIER = 1.0,
        ITEM_EFFECTIVENESS_MULTIPLIER = 1.0,
        ERROR_CHANCE_MULTIPLIER = 1.0,
        TREMOR_INTENSITY_MULTIPLIER = 1.0,
        SCREEN_EFFECTS_INTENSITY = 1.0,
    },
    Hard = {
        SURGERY_FATIGUE_MULTIPLIER = 1.5,
        BASIC_PROCEDURE_MULTIPLIER = 1.5,
        EMERGENCY_STRESS_MULTIPLIER = 1.5,
        NATURAL_RECOVERY_MULTIPLIER = 0.7,
        ITEM_EFFECTIVENESS_MULTIPLIER = 0.8,
        ERROR_CHANCE_MULTIPLIER = 1.5,
        TREMOR_INTENSITY_MULTIPLIER = 1.5,
        SCREEN_EFFECTS_INTENSITY = 1.3,
    },
    Realistic = {
        SURGERY_FATIGUE_MULTIPLIER = 2.0,
        BASIC_PROCEDURE_MULTIPLIER = 1.8,
        EMERGENCY_STRESS_MULTIPLIER = 2.5,
        NATURAL_RECOVERY_MULTIPLIER = 0.5,
        ITEM_EFFECTIVENESS_MULTIPLIER = 0.6,
        ERROR_CHANCE_MULTIPLIER = 2.0,
        TREMOR_INTENSITY_MULTIPLIER = 2.0,
        SCREEN_EFFECTS_INTENSITY = 1.5,
    }
}

-- Initialize configuration system
function NT.FatigueConfig.Initialize()
    -- Copy defaults to current
    for key, value in pairs(NT.FatigueConfig.Defaults) do
        NT.FatigueConfig.Current[key] = value
    end
    
    -- Load saved configuration
    NT.FatigueConfig.LoadFromSave()
    
    print("NT Fatigue Config initialized")
end

-- Get a configuration value
function NT.FatigueConfig.Get(key, defaultValue)
    if NT.FatigueConfig.Current[key] ~= nil then
        return NT.FatigueConfig.Current[key]
    end
    return defaultValue or NT.FatigueConfig.Defaults[key]
end

-- Set a configuration value
function NT.FatigueConfig.Set(key, value)
    NT.FatigueConfig.Current[key] = value
    NT.FatigueConfig.SaveToFile()
    
    -- Apply preset if preset was changed
    if key == "DIFFICULTY_PRESET" and value ~= "Custom" then
        NT.FatigueConfig.ApplyPreset(value)
    end
    
    -- Notify other systems of configuration change
    NT.FatigueConfig.NotifyConfigChange(key, value)
end

-- Apply a difficulty preset
function NT.FatigueConfig.ApplyPreset(presetName)
    local preset = NT.FatigueConfig.Presets[presetName]
    if not preset then return end
    
    for key, value in pairs(preset) do
        NT.FatigueConfig.Current[key] = value
    end
    
    NT.FatigueConfig.Current.DIFFICULTY_PRESET = presetName
    NT.FatigueConfig.SaveToFile()
    
    print("Applied fatigue difficulty preset: " .. presetName)
end

-- Save configuration to file
function NT.FatigueConfig.SaveToFile()
    local saveData = {}
    for key, value in pairs(NT.FatigueConfig.Current) do
        saveData[key] = value
    end
    
    -- Use Neurotrauma's existing config system if available
    if NTConfig and NTConfig.Set then
        for key, value in pairs(saveData) do
            NTConfig.Set("FatigueConfig_" .. key, value, true)
        end
    end
end

-- Load configuration from save
function NT.FatigueConfig.LoadFromSave()
    if NTConfig and NTConfig.Get then
        for key, defaultValue in pairs(NT.FatigueConfig.Defaults) do
            local savedValue = NTConfig.Get("FatigueConfig_" .. key, defaultValue)
            NT.FatigueConfig.Current[key] = savedValue
        end
    end
end

-- Notify other systems of configuration changes
function NT.FatigueConfig.NotifyConfigChange(key, value)
    -- Update fatigue system parameters
    if NT.MedicalFatigue and NT.MedicalFatigue.Config then
        if key == "SURGERY_FATIGUE_MULTIPLIER" then
            NT.MedicalFatigue.Config.SURGERY_FATIGUE_RATE = 2.0 * value
        elseif key == "BASIC_PROCEDURE_MULTIPLIER" then
            NT.MedicalFatigue.Config.BASIC_PROCEDURE_FATIGUE = 5.0 * value
        elseif key == "EMERGENCY_STRESS_MULTIPLIER" then
            NT.MedicalFatigue.Config.EMERGENCY_STRESS_RATE = 1.0 * value
        elseif key == "NATURAL_RECOVERY_MULTIPLIER" then
            NT.MedicalFatigue.Config.FATIGUE_NATURAL_DECAY = 0.1 * value
        elseif key == "ERROR_CHANCE_MULTIPLIER" then
            NT.MedicalFatigue.Config.MODERATE_ERROR_CHANCE = 0.05 * value
            NT.MedicalFatigue.Config.SEVERE_ERROR_CHANCE = 0.15 * value
            NT.MedicalFatigue.Config.EXTREME_ERROR_CHANCE = 0.30 * value
        end
    end
    
    -- Update visual effects parameters
    if NT.FatigueEffects and NT.FatigueEffects.Config then
        if key == "TREMOR_INTENSITY_MULTIPLIER" then
            NT.FatigueEffects.Config.TREMOR_INTENSITY_MULTIPLIER = 2.0 * value
        elseif key == "SCREEN_EFFECTS_INTENSITY" then
            NT.FatigueEffects.Config.FATIGUE_BLUR_MAX = 0.3 * value
            NT.FatigueEffects.Config.STRESS_DISTORTION_MAX = 0.2 * value
        end
    end
end

-- Reset to defaults
function NT.FatigueConfig.ResetToDefaults()
    for key, value in pairs(NT.FatigueConfig.Defaults) do
        NT.FatigueConfig.Current[key] = value
    end
    NT.FatigueConfig.SaveToFile()
    
    -- Notify all systems
    for key, value in pairs(NT.FatigueConfig.Current) do
        NT.FatigueConfig.NotifyConfigChange(key, value)
    end
    
    print("Fatigue configuration reset to defaults")
end

-- Get current difficulty level as text
function NT.FatigueConfig.GetDifficultyDescription()
    local preset = NT.FatigueConfig.Get("DIFFICULTY_PRESET", "Normal")
    
    if preset == "Easy" then
        return "Easy - Reduced fatigue accumulation and increased recovery"
    elseif preset == "Normal" then
        return "Normal - Balanced fatigue mechanics"
    elseif preset == "Hard" then
        return "Hard - Increased fatigue and reduced recovery"
    elseif preset == "Realistic" then
        return "Realistic - Maximum fatigue effects for immersion"
    else
        return "Custom - User-defined settings"
    end
end

-- Add configuration entries to existing Neurotrauma config system
function NT.FatigueConfig.RegisterWithNTConfig()
    if not NTConfig or not NTConfig.Add then return end
    
    -- Add entries to Neurotrauma's config system
    for _, category in ipairs(NT.FatigueConfig.Categories) do
        for _, entry in ipairs(category.entries) do
            local configEntry = {
                key = "FatigueConfig_" .. entry.key,
                name = entry.name,
                description = entry.description,
                type = entry.type,
                default = NT.FatigueConfig.Defaults[entry.key],
                category = "Medical Fatigue - " .. category.name
            }
            
            if entry.type == "float" then
                configEntry.min = entry.min
                configEntry.max = entry.max
                configEntry.step = entry.step
            elseif entry.type == "dropdown" then
                configEntry.options = entry.options
            end
            
            NTConfig.Add(configEntry)
        end
    end
end

-- Initialize the configuration system
NT.FatigueConfig.Initialize()

-- Register with NTConfig when available
Hook.Add("think", "NT.FatigueConfig.LateInit", function()
    if NTConfig and NTConfig.Add and not NT.FatigueConfig.registeredWithNTConfig then
        NT.FatigueConfig.RegisterWithNTConfig()
        NT.FatigueConfig.registeredWithNTConfig = true
        print("Fatigue config registered with NTConfig")
    end
end)

print("NT Medical Fatigue Configuration system loaded")
