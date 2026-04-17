-- Original code by Evil Factory,
-- Adapted for Neurotrauma
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

easySettings.SaveTable = function(path, tbl)
	File.Write(path, json.serialize(tbl))
end

easySettings.LoadTable = function(path)
	if not File.Exists(path) then
		return {}
	end

	return json.parse(File.Read(path))
end

easySettings.AddMenu = function(name, onOpen)
	table.insert(easySettings.Settings, { Name = name, OnOpen = onOpen })
end

-- Overhauled Config GUI
easySettings.BasicList = function(parent, size)
	-- Menu Frame
	local menuContent =
		GUI.Frame(GUI.RectTransform(size or Vector2(0.5, 0.8), parent.RectTransform, GUI.Anchor.Center), "GUIFrame")

	-- Main Layout
	local mainLayout = GUI.LayoutGroup(
		GUI.RectTransform(Vector2(0.95, 0.95), menuContent.RectTransform, GUI.Anchor.Center, GUI.Pivot.Center),
		false
	)

	-- Background
	local configBackground = GUI.Frame(GUI.RectTransform(Vector2(1, 0.95), mainLayout.RectTransform), "InnerFrame")

	-- Shrink Inner layout
	local innerLayout = GUI.LayoutGroup(
		GUI.RectTransform(Vector2(0.95, 0.95), configBackground.RectTransform, GUI.Anchor.TopCenter),
		false
	)

	-- Title block
	local title = GUI.TextBlock(
		GUI.RectTransform(Vector2(1, 0.07), innerLayout.RectTransform),
		"Neurotrauma Config Settings",
		nil,
		GUI.GUIStyle.LargeFont
	)
	title.TextAlignment = GUI.Alignment.TopCenter

	-- Setting list
	local menuList = GUI.ListBox(GUI.RectTransform(Vector2(1, 0.97), innerLayout.RectTransform))
	menuList.Padding = Vector4(10, 15, 10, 10)
	menuList.UpdateDimensions()

	-- Button row
	local buttonRow = GUI.LayoutGroup(GUI.RectTransform(Vector2(1, 0.1), mainLayout.RectTransform), true)
	buttonRow.RelativeSpacing = 0.02
	easySettings.SaveButton(buttonRow)
	easySettings.CloseButton(buttonRow)
	easySettings.ResetButton(buttonRow)

	return menuList
end

-- Function for a Tickbox
easySettings.TickBox = function(parent, text, onSelected, state)
	if state == nil then
		state = true
	end

	local tickBox = GUI.TickBox(GUI.RectTransform(Vector2(1, 0.2), parent.RectTransform), text)
	tickBox.Selected = state
	tickBox.OnSelected = function()
		onSelected(tickBox.State == GUIComponent.ComponentState.Selected)
	end

	return tickBox
end

-- Function for a Slider
easySettings.Slider = function(parent, min, max, onSelected, value)
	local scrollBar = GUI.ScrollBar(GUI.RectTransform(Vector2(1, 0.1), parent.RectTransform), 0.1, nil, "GUISlider")
	scrollBar.Range = Vector2(min, max)
	scrollBar.BarScrollValue = value or max / 2
	scrollBar.OnMoved = function()
		onSelected(scrollBar.BarScrollValue)
	end

	return scrollBar
end

-- Function for the Save and Exit button
easySettings.SaveButton = function(parent)
	local button = GUI.Button(
		GUI.RectTransform(Vector2(0.32, 0.05), parent.RectTransform, GUI.Anchor.BottomLeft),
		"Save and Exit",
		GUI.Alignment.Center,
		"GUIButton"
	)

	button.OnClicked = function()
		if Game.IsMultiplayer and Game.Client.HasPermission(ClientPermissions.ManageSettings) then
			NTConfig.SendConfig()
		elseif Game.IsSingleplayer then
			NTConfig.SaveConfig()
		end
		GUI.GUI.TogglePauseMenu()
	end

	return button
end

-- Function for the Discard and Exit button
easySettings.CloseButton = function(parent)
	local button = GUI.Button(
		GUI.RectTransform(Vector2(0.32, 0.05), parent.RectTransform, GUI.Anchor.BottomCenter),
		"Discard and Exit",
		GUI.Alignment.Center,
		"GUIButton"
	)

	button.OnClicked = function()
		GUI.GUI.TogglePauseMenu()
		NTConfig.LoadConfig()
	end

	return button
end

-- Function for the Reset and Exit button
easySettings.ResetButton = function(parent)
	local button = GUI.Button(
		GUI.RectTransform(Vector2(0.32, 0.05), parent.RectTransform, GUI.Anchor.BottomRight),
		"Reset Config",
		GUI.Alignment.Center,
		"GUIButton"
	)

	button.OnClicked = function()
		if
			Game.IsSingleplayer or (Game.IsMultiplayer and Game.Client.HasPermission(ClientPermissions.ManageSettings))
		then
			easySettings.ResetMessage(parent)
		end
	end

	return button
end

-- Confirmation popup for config reset
easySettings.ResetMessage = function(parent)
	local ResetMessage = GUI.MessageBox(
		"Reset neurotrauma settings",
		"Are you sure you want to reset neurotrauma settings to default values?",
		{ "Yes", "No" }
	)
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

-- Add button on pause menu for NT Settings
Hook.Patch("Barotrauma.GUI", "TogglePauseMenu", {}, function()
	if GUI.GUI.PauseMenuOpen then
		local frame = GUI.GUI.PauseMenu

		local list = GetChildren(GetChildren(frame)[2])[1]

		for key, value in pairs(easySettings.Settings) do
			local PauseMenuButton = GUI.Button(
				GUI.RectTransform(Vector2(1, 0.1), list.RectTransform),
				value.Name,
				GUI.Alignment.Center,
				"GUIButtonSmall"
			)

			PauseMenuButton.OnClicked = function()
				value.OnOpen(frame)
			end
		end
	end
end, Hook.HookMethodType.After)

return easySettings
