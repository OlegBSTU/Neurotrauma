--easysettings by Evil Factory
local easySettings = dofile(NT.Path .. "/Lua/Scripts/Client/easysettings.lua")
local GUIComponent = LuaUserData.CreateStatic("Barotrauma.GUIComponent")
local configUI

--calculate difficulty
local function DetermineDifficulty()
	local difficulty = 0
	local defaultDifficulty = 0
	local res = ""

	for key, entry in pairs(NTConfig.Entries) do
		if entry.difficultyCharacteristics then
			local entryValue = entry.value
			local entryValueDefault = entry.default
			local diffMultiplier = 1
			if entry.type == "bool" then
				entryValue = HF.BoolToNum(entry.value)
				entryValueDefault = HF.BoolToNum(entry.default)
			end
			if entry.difficultyCharacteristics.multiplier then
				diffMultiplier = entry.difficultyCharacteristics.multiplier
			end

			defaultDifficulty = defaultDifficulty + entryValueDefault * diffMultiplier
			difficulty = difficulty + math.min(entryValue * diffMultiplier, entry.difficultyCharacteristics.max or 1)
		end
	end

	-- normalize to 10
	difficulty = difficulty / defaultDifficulty * 10

	if difficulty > 23 then
		res = "Impossible"
	elseif difficulty > 16 then
		res = "Very hard"
	elseif difficulty > 11 then
		res = "Hard"
	elseif difficulty > 8 then
		res = "Normal"
	elseif difficulty > 6 then
		res = "Easy"
	elseif difficulty > 4 then
		res = "Very easy"
	elseif difficulty > 2 then
		res = "Barely different"
	else
		res = "Vanilla but sutures"
	end

	res = res .. " (" .. HF.Round(difficulty, 1) .. ")"
	return res
end

--bulk of the GUI code
local function ConstructUI(parent)
	local list = easySettings.BasicList(parent)

	--info text
	local userBlock = GUI.TextBlock(
		GUI.RectTransform(Vector2(1, 0.2), list.Content.RectTransform),
		"Server config can be changed by owner or a client with manage settings permission. If the server doesn't allow writing into the config folder, then it must be edited manually.",
		Color(200, 255, 255),
		nil,
		GUI.Alignment.Center,
		true,
		nil,
		Color(0, 0, 0)
	)
	local difficultyBlock = GUI.TextBlock(
		GUI.RectTransform(Vector2(1, 0.1), list.Content.RectTransform),
		"",
		Color(200, 255, 255),
		nil,
		GUI.Alignment.Center,
		true,
		nil,
		Color(0, 0, 0)
	)

	--set difficulty text (why does this even exist in the first place)
	local function OnChanged()
		difficultyRate = "Calculated difficulty rating: " .. DetermineDifficulty()
		difficultyBlock.Text = difficultyRate
	end
	OnChanged()

	--empty space
	--GUI.TextBlock(GUI.RectTransform(Vector2(0.2, 0.1), list.Content.RectTransform), "", Color(255,255,255), nil, GUI.Alignment.Center, true, nil, Color(0,0,0))

	-- procedurally construct config UI
	for key, entry in pairs(NTConfig.Entries) do
		if entry.type == "float" then
			-- scalar value
			--grab range
			local minrange = ""
			local maxrange = ""
			local count = 0
			for _, rangegrab in pairs(entry.range) do
				if count == 0 then
					minrange = rangegrab
				end
				if count == 1 then
					maxrange = rangegrab
				end
				count = count + 1
			end

			local rect = GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform)
			local textBlock = GUI.TextBlock(
				rect,
				entry.name .. " (" .. minrange .. "-" .. maxrange .. ")",
				Color(230, 230, 170),
				nil,
				GUI.Alignment.Center,
				true,
				nil,
				Color(0, 0, 0)
			)
			if entry.description then
				textBlock.ToolTip = entry.description
			end
			local scalar =
				GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.08), list.Content.RectTransform), NumberType.Float)
			local key2 = key
			scalar.valueStep = 0.1
			scalar.MinValueFloat = 0
			scalar.MaxValueFloat = 100
			if entry.range then
				scalar.MinValueFloat = entry.range[1]
				scalar.MaxValueFloat = entry.range[2]
			end
			scalar.FloatValue = NTConfig.Get(key2, 1)
			scalar.OnValueChanged = function()
				NTConfig.Set(key2, scalar.FloatValue)
				OnChanged()
			end 
			
		elseif entry.type == "string" then
			--user string input
			
			local style = ""
			--get custom style
			if entry.style ~= nil then
				style = " (" .. entry.style .. ")"
			end

			
			local rect = GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform)
			local textBlock = GUI.TextBlock(
				rect,
				entry.name..style,
				Color(230, 230, 170),
				nil,
				GUI.Alignment.Center,
				true,
				nil,
				Color(0, 0, 0)
			) 
			if entry.description then
				textBlock.ToolTip = entry.description
			end	
			
			local stringinput = 
				GUI.TextBox(
					GUI.RectTransform(Vector2(1, 0.08), list.Content.RectTransform), 
						nil, 
						nil, 
						nil, 
						GUI.Alignment.Center,
						true)
			local key2=key
				stringinput.ReceiveTextInput(NTConfig.Get(key2, true))
				
				stringinput.OnTextChangedDelegate = function() 
					NTConfig.Set(key2, stringinput.Text)
				end
				
		elseif entry.type == "bool" then
			-- toggle
			local rect = GUI.RectTransform(Vector2(1, 0.2), list.Content.RectTransform)
			local toggle = GUI.TickBox(rect, entry.name)
			if entry.description then
				toggle.ToolTip = entry.description
			end
			local key2 = key
			toggle.Selected = NTConfig.Get(key2, false)
			toggle.OnSelected = function()
				NTConfig.Set(key2, toggle.State == GUIComponent.ComponentState.Selected)
				OnChanged()
			end
		elseif entry.type == "category" then
			-- visual separation
			GUI.TextBlock(
				GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform),
				entry.name,
				Color(255, 255, 255),
				nil,
				GUI.Alignment.Center,
				true,
				nil,
				Color(0, 0, 0)
			)
		end
	end

	--empty space as last tickbox was getting cutoff
	GUI.TextBlock(
		GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform),
		"",
		Color(255, 255, 255),
		nil,
		GUI.Alignment.Center,
		true,
		nil,
		Color(0, 0, 0)
	)

	if Game.IsMultiplayer and not Game.Client.HasPermission(ClientPermissions.ManageSettings) then
		for guicomponent in list.GetAllChildren() do
			guicomponent.enabled = false
		end
	end

	return list
end

Networking.Receive("NT.ConfigUpdate", function(msg)
	NTConfig.ReceiveConfig(msg)
	local parent = configUI.Parent.Parent
	configUI.RectTransform.Parent = nil
	configUI = nil
	configUI = ConstructUI(parent)
end)

easySettings.AddMenu("Neurotrauma", function(parent)
	if Game.IsMultiplayer then
		local msg = Networking.Start("NT.ConfigRequest")
		Networking.Send(msg)
	end
	configUI = ConstructUI(parent)
end)
