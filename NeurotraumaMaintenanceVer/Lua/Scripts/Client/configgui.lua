-- I'm sorry for the eyes of anyone looking at the GUI code.

local MultiLineTextBox = dofile(NT.Path .. "/Lua/Scripts/Client/MultiLineTextBox.lua")
local GUIComponent = LuaUserData.CreateStatic("Barotrauma.GUIComponent")

Game.AddCommand("neuro", "opens neurotrauma config", function ()
    NT.ToggleGUI()
end)

local function CommaStringToTable(str)
    local tbl = {}

    for word in string.gmatch(str, '([^,]+)') do
        table.insert(tbl, word)
    end

    return tbl
end
local function ClearElements(guicomponent, removeItself)
    local toRemove = {}

    for value in guicomponent.GetAllChildren() do
        table.insert(toRemove, value)
    end

    for index, value in pairs(toRemove) do
        value.RemoveChild(value)
    end

    if guicomponent.Parent and removeItself then
        guicomponent.Parent.RemoveChild(guicomponent)
    end
end
local function GetAmountOfPrefab(prefabs)
    local amount = 0
    for key, value in prefabs do
        amount = amount + 1
    end

    return amount
end
local function DetermineDifficulty()
    local difficulty = 0
    local defaultDifficulty = 0
    local res = ""

    for key,entry in pairs(NTConfig.Entries) do
        if entry.difficultyCharacteristics then
            local entryValue = entry.value
            local entryValueDefault = entry.default
            local diffMultiplier = 1
            if entry.type=="bool" then
                entryValue = HF.BoolToNum(entry.value)
                entryValueDefault = HF.BoolToNum(entry.default)
            end
            if entry.difficultyCharacteristics.multiplier then
                diffMultiplier = entry.difficultyCharacteristics.multiplier
            end

            defaultDifficulty = defaultDifficulty + entryValueDefault * diffMultiplier
            difficulty = difficulty + math.min(entryValue * diffMultiplier,entry.difficultyCharacteristics.max or 1)
        end
    end

    -- normalize to 10
    difficulty = difficulty / defaultDifficulty * 10

    if difficulty > 23 then res="Impossible"
    elseif difficulty > 16 then res="Very hard"
    elseif difficulty > 11 then res="Hard"
    elseif difficulty > 8 then res="Normal"
    elseif difficulty > 6 then res="Easy"
    elseif difficulty > 4 then res="Very easy"
    elseif difficulty > 2 then res="Barely different"
    else res="Vanilla but sutures"
    end

    res = res.." ("..HF.Round(difficulty,1)..")"
    return res
end


Hook.Add("stop", "NT.CleanupGUI", function ()
    if selectedGUIText then
        selectedGUIText.Parent.RemoveChild(selectedGUIText)
    end

    if NT.GUIFrame then
        ClearElements(NT.GUIFrame, true)
    end
end)

NT.ShowGUI = function ()
    local frame = GUI.Frame(GUI.RectTransform(Vector2(0.3, 0.6), GUI.Screen.Selected.Frame.RectTransform, GUI.Anchor.Center))
    NT.GUIFrame = frame
    frame.CanBeFocused = true
    local config = GUI.ListBox(GUI.RectTransform(Vector2(1, 1), frame.RectTransform, GUI.Anchor.BottomCenter))
    local closebtn = GUI.Button(GUI.RectTransform(Vector2(0.1, 0.3), frame.RectTransform, GUI.Anchor.TopRight), "X", GUI.Alignment.Center, "GUIButtonSmall")
    closebtn.OnClicked = function ()
        NT.ToggleGUI()
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), "Neurotrauma Config", nil, nil, GUI.Alignment.Center)
    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Note: Only the host can edit the servers config. Enter \"reloadlua\" in console to apply changes. For dedicated servers you need to edit the file config.json, this GUI wont work.", nil, nil, GUI.Alignment.Center, true)
    local difficultyText = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), "Calculated difficulty rating: "..DetermineDifficulty(), nil, nil, GUI.Alignment.Center)

    local function OnChanged()
        difficultyText.Text = "Calculated difficulty rating: "..DetermineDifficulty()
    end
    OnChanged()

    local savebtn = GUI.Button(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Save Config", GUI.Alignment.Center, "GUIButtonSmall")
    savebtn.OnClicked = NTConfig.SaveConfig

    -- procedurally construct config UI
    for key,entry in pairs(NTConfig.Entries) do
        if entry.type=="float" then

            -- scalar value
            local rect = GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform)
            local textBlock = GUI.TextBlock(rect, entry.name, nil, nil, GUI.Alignment.Center, true)
            if entry.description then textBlock.ToolTip = entry.description end
            local scalar = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
            local key2 = key
            scalar.valueStep = 0.1
            scalar.MinValueFloat = 0
            scalar.MaxValueFloat = 100
            if entry.range then
                scalar.MinValueFloat = entry.range[1]
                scalar.MaxValueFloat = entry.range[2]
            end
            scalar.FloatValue = NTConfig.Get(key2,1)
            scalar.OnValueChanged = function ()
                NTConfig.Set(key2,scalar.FloatValue)
                OnChanged()
            end

        elseif entry.type=="bool" then

            -- toggle
            local rect=GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform)
            local toggle = GUI.TickBox(rect, entry.name)
            if entry.description then toggle.ToolTip = entry.description end
            local key2 = key
            toggle.Selected = NTConfig.Get(key2,false)
            toggle.OnSelected = function ()
                NTConfig.Set(key2,toggle.State == GUIComponent.ComponentState.Selected)
                OnChanged()
            end

        elseif entry.type=="category" then

            -- visual separation
            GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), entry.name, nil, nil, GUI.Alignment.Center, true)
        
        end
    end

end
    
--[[

-- Multilines

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Client High Priority Items", nil, nil, GUI.Alignment.Center, true)

    local clientHighPriorityItems = MultiLineTextBox(config.Content.RectTransform, "", 0.2)

    clientHighPriorityItems.Text = table.concat(NT.Config.clientItemHighPriority, ",")

    clientHighPriorityItems.OnTextChangedDelegate = function (textBox)
        NT.Config.clientItemHighPriority = CommaStringToTable(textBox.Text)
    end

    ]]

NT.HideGUI = function()
    if NT.GUIFrame then
        ClearElements(NT.GUIFrame, true)
    end
end

NT.GUIOpen = false
NT.ToggleGUI = function ()
    NT.GUIOpen = not NT.GUIOpen

    if NT.GUIOpen then
        NT.ShowGUI()
    else
        NT.HideGUI()
    end
end