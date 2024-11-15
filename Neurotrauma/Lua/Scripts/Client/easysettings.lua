--original code by Evil Factory, 
--adapted to NT
local easySettings = {}

easySettings.Settings = {}

local GUIComponent = LuaUserData.CreateStatic("Barotrauma.GUIComponent")

local function GetChildren(comp)
    local tbl = {}
    for value in comp.GetAllChildren() do
        table.insert(tbl, value)
    end
    return tbl
end

Hook.Patch("Barotrauma.GUI", "TogglePauseMenu", {}, function ()
    if GUI.GUI.PauseMenuOpen then
        local frame = GUI.GUI.PauseMenu

        local list = GetChildren(GetChildren(frame)[2])[1]

        for key, value in pairs(easySettings.Settings) do
            local button = GUI.Button(GUI.RectTransform(Vector2(1, 0.1), list.RectTransform), value.Name, GUI.Alignment.Center, "GUIButtonSmall")

            button.OnClicked = function ()
                value.OnOpen(frame)
            end
        end
    end
end, Hook.HookMethodType.After)

easySettings.SaveTable = function (path, tbl)
    File.Write(path, json.serialize(tbl))
end
easySettings.LoadTable = function (path)
    if not File.Exists(path) then
        return {}
    end

    return json.parse(File.Read(path))
end

easySettings.AddMenu = function (name, onOpen)
    table.insert(easySettings.Settings, {Name = name, OnOpen = onOpen})
end

easySettings.BasicList = function (parent, size)
    local menuContent = GUI.Frame(GUI.RectTransform(size or Vector2(0.3, 0.6), parent.RectTransform, GUI.Anchor.Center))
    local menuList = GUI.ListBox(GUI.RectTransform(Vector2(1, 0.95), menuContent.RectTransform, GUI.Anchor.TopCenter))

	easySettings.SaveButton(menuContent)
    easySettings.CloseButton(menuContent)
    easySettings.ResetButton(menuContent)

    return menuList
end

easySettings.TickBox = function (parent, text, onSelected, state)
    if state == nil then state = true end

    local tickBox = GUI.TickBox(GUI.RectTransform(Vector2(1, 0.2), parent.RectTransform), text)
    tickBox.Selected = state
    tickBox.OnSelected = function ()
        onSelected(tickBox.State == GUIComponent.ComponentState.Selected)
    end

    return tickBox
end

easySettings.Slider = function (parent, min, max, onSelected, value)
    local scrollBar = GUI.ScrollBar(GUI.RectTransform(Vector2(1, 0.1), parent.RectTransform), 0.1, nil, "GUISlider")
    scrollBar.Range = Vector2(min, max)
    scrollBar.BarScrollValue = value or max / 2
    scrollBar.OnMoved = function ()
        onSelected(scrollBar.BarScrollValue)
    end

    return scrollBar
end

--save and exit
easySettings.SaveButton = function (parent)
    local button = GUI.Button(GUI.RectTransform(Vector2(0.33, 0.05), parent.RectTransform, GUI.Anchor.BottomLeft), "Save and Exit", GUI.Alignment.Center, "GUIButton")

    button.OnClicked = function ()
        if Game.IsMultiplayer and Game.Client.HasPermission(ClientPermissions.ManageSettings) then
            NTConfig.SendConfig()
        elseif Game.IsSingleplayer then
            NTConfig.SaveConfig()
        end
        GUI.GUI.TogglePauseMenu()
    end

    return button
end

--discard and exit
easySettings.CloseButton = function (parent)
    local button = GUI.Button(GUI.RectTransform(Vector2(0.33, 0.05), parent.RectTransform, GUI.Anchor.BottomCenter), "Discard and Exit", GUI.Alignment.Center, "GUIButton")

    button.OnClicked = function ()
        GUI.GUI.TogglePauseMenu()
		NTConfig.LoadConfig()
    end

    return button
end

--reset and exit
easySettings.ResetButton = function (parent)
    local button = GUI.Button(GUI.RectTransform(Vector2(0.33, 0.05), parent.RectTransform, GUI.Anchor.BottomRight), "Reset Config", GUI.Alignment.Center, "GUIButton")

    button.OnClicked = function ()
        if Game.IsSingleplayer or (Game.IsMultiplayer and Game.Client.HasPermission(ClientPermissions.ManageSettings)) then
            easySettings.ResetMessage(parent)
        end
    end
    return button
end

easySettings.ResetMessage = function(parent)
    local ResetMessage = GUI.MessageBox("Reset neurotrauma settings", "Are you sure you want to reset neurotrauma settings to default values?", {"Yes", "No"})
    ResetMessage.DrawOnTop = true
    ResetMessage.Text.TextAlignment = GUI.Alignment.Center
    ResetMessage.Buttons[1].OnClicked = function()
        NTConfig.ResetConfig()
        if Game.IsMultiplayer and Game.Client.HasPermission(ClientPermissions.ManageSettings) then
            NTConfig.SendConfig()
        elseif Game.IsSingleplayer then
            NTConfig.SaveConfig()
        end
        GUI.GUI.TogglePauseMenu()
        ResetMessage.Close()
    end
    ResetMessage.Buttons[2].OnClicked = function()
        ResetMessage.Close()
    end
    return ResetMessage
end

return easySettings