--easysettings by Evil Factory
local easySettings = dofile(NT.Path .. "/Lua/Scripts/Client/easysettings.lua")
local MultiLineTextBox = dofile(NT.Path .. "/Lua/Scripts/Client/MultiLineTextBox.lua")
local GUIComponent = LuaUserData.CreateStatic("Barotrauma.GUIComponent")
local configUI

-- Did you know the default background colour is not true black?
local Transparent = Color(2, 2, 2)
-- Barotrauma beige
local DefaultTextColour = Color(210, 200, 154)
local ExpansionNameForUI = {}

local function CommaStringToTable(str)
	local tbl = {}

	for word in string.gmatch(str, "([^,]+)") do
		table.insert(tbl, word)
	end

	return tbl
end

-- Function that autofills the addon dropdown
-- We also automatically make the UI display the names as "NT [mod]" to match their Content Package / Steam Workhop name to minimise confusion.
local function PopulateDropdown(dropdown)
	ExpansionNameForUI = {}

	for _, expansion in ipairs(NTConfig.Expansions) do
		local name = tostring(expansion.Name)
		-- First, we make the UI Name the same as their expansion name
		local uiName = name
		-- Excluding Neurotrauma itself, add NT at the front if it does not already have that
		if expansion.Name ~= "Neurotrauma" then
			if not string.find(uiName, "^NT%s") then
				uiName = "NT " .. uiName
			end
		end
		-- Add them to a lookup table for later
		table.insert(ExpansionNameForUI, { uiName, name })
		-- Finally, add it to the dropdown menu
		dropdown.AddItem(uiName)
	end
end

-- TODO: Readd the difficulty calculation I kinda dont care about it right now so it can fuck off

-- Function to determine how the layout should be structured
local function PrebuildConfigLayout(entries, selectedExpansion)
	-- This table will contain subtables that determine how the ConstructUI function actually 'constructs' the UI.
	-- These chunks can be gone over using Ipairs to ensure the order is correct (a previous test made unrelated settings render together)
	local LayoutChunks = {}
	local CurrentGroup = nil
	local lastType = nil

	for key, entry in pairs(entries) do
		-- Grab actual expansion name based on their UIName
		for _, entry in ipairs(ExpansionNameForUI) do
			if entry[1] == selectedExpansion then
				selectedExpansion = entry[2]
			end
		end

		-- Only determine layout for entries from the expansion we've selected
		if entry.expansion ~= selectedExpansion then
			goto continue
		end

		-- Automatically add some white space between unique item types to prevent bleeding
		if entry.type ~= lastType and lastType ~= nil then
			table.insert(LayoutChunks, { type = "spacer" })
		end

		lastType = entry.type

		-- Categories are always standalone and should be put above the settings they govern
		-- Interrupt a group if it exists
		if entry.type == "category" then
			CurrentGroup = nil
			table.insert(LayoutChunks, { type = "category", entry = entry })

		-- Floats / Strings until now were just using up way too much screen space. We want to put these into a LayoutGroup together to maximise screen usage.
		-- If entries have 'group=true', then all entries of the same type that follow one another will be grouped together. If there are other entry types (like categories) in-between, they will not.
		-- This prevents unrelated settings from merging together + adds reverse-compat
		elseif entry.type == "float" and entry.group then
			-- Make a group and keep adding config entries that come after this as long as the criteria stands
			if not CurrentGroup or CurrentGroup.type ~= "float_group" then
				CurrentGroup = { type = "float_group", items = {} }
				table.insert(LayoutChunks, CurrentGroup)
			end

			table.insert(CurrentGroup.items, { key = key, entry = entry })
		elseif entry.type == "string" and entry.group then
			if not CurrentGroup or CurrentGroup.type ~= "string_group" then
				CurrentGroup = { type = "string_group", items = {} }
				table.insert(LayoutChunks, CurrentGroup)
			end

			table.insert(CurrentGroup.items, { key = key, entry = entry })

		-- Anything else is anything that shouldn't be grouped. Interrupt a group if it exists and add the setting as standalone.
		else
			CurrentGroup = nil
			table.insert(LayoutChunks, { type = "standalone", key = key, entry = entry })
		end

		::continue::
	end

	return LayoutChunks
end

local function PopulateSettingsIntoUI(list, selectedExpansion)
	list.Content:ClearChildren()

	-- Infotext (should always be shown)
	local tb_BasicConfigInfo = GUI.TextBlock(
		GUI.RectTransform(Vector2(1, 0.1), list.Content.RectTransform),
		"Server config can be changed by owner or a client with manage settings permission. If the server doesn't allow writing into the config folder, then it must be edited manually.",
		DefaultTextColour,
		nil,
		GUI.Alignment.Center,
		true,
		nil,
		Transparent
	)

	-- Prevent textblocks from lighting up the background when clicked / changing the cursor on hover.
	tb_BasicConfigInfo.CanBeFocused = false

	local LayoutChunks = PrebuildConfigLayout(NTConfig.Entries, selectedExpansion)
	-- Go over the pre-generated Layout table and construct settings procedurally
	for _, chunk in ipairs(LayoutChunks) do
		-- Categories
		if chunk.type == "category" then
			local tb_ProceduralCategoryHeader = GUI.TextBlock(
				GUI.RectTransform(Vector2(1, 0.09), list.Content.RectTransform),
				chunk.entry.name,
				DefaultTextColour,
				GUI.GUIStyle.LargeFont,
				GUI.Alignment.BottomCenter,
				true,
				nil,
				Transparent
			)

			tb_ProceduralCategoryHeader.CanBeFocused = false

		-- Standalone items
		elseif chunk.type == "standalone" then
			local key = chunk.key
			local entry = chunk.entry

			-- Ungrouped float
			if entry.type == "float" then
				local minrange = (entry.range and entry.range[1]) or ""
				local maxrange = (entry.range and entry.range[2]) or ""

				local rect = GUI.RectTransform(Vector2(1, 0.04), list.Content.RectTransform)

				local tb_EntryInformation = GUI.TextBlock(
					rect,
					entry.name .. " (" .. minrange .. "-" .. maxrange .. ")",
					DefaultTextColour,
					nil,
					GUI.Alignment.Center,
					true,
					nil,
					Transparent
				)

				tb_EntryInformation.CanBeFocused = false

				if entry.description then
					tb_EntryInformation.ToolTip = entry.description
				end

				local scalar =
					GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.08), list.Content.RectTransform), NumberType.Float)

				scalar.valueStep = 0.1
				scalar.MinValueFloat = entry.range and entry.range[1] or 0
				scalar.MaxValueFloat = entry.range and entry.range[2] or 100
				scalar.FloatValue = NTConfig.Get(key, 1)

				scalar.OnValueChanged = function()
					NTConfig.Set(key, scalar.FloatValue)
				end

			-- Bool
			elseif entry.type == "bool" then
				local rect = GUI.RectTransform(Vector2(0.5, 1), list.Content.RectTransform)
				local toggle = GUI.TickBox(rect, entry.name)

				if entry.description then
					toggle.ToolTip = entry.description
				end

				toggle.Selected = NTConfig.Get(key, false)

				toggle.OnSelected = function()
					NTConfig.Set(key, toggle.State == GUIComponent.ComponentState.Selected)
				end

			-- String (a textblock to input)
			elseif entry.type == "string" then
				local style = ""
				if entry.style ~= nil then
					style = " (" .. entry.style .. ")"
				end

				local rect = GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform)

				local tb_StringInformation = GUI.TextBlock(
					rect,
					entry.name .. style,
					DefaultTextColour,
					nil,
					GUI.Alignment.Center,
					true,
					nil,
					Transparent
				)

				-- By default, don't change cursor on hovering
				tb_StringInformation.CanBeFocused = false

				-- If there's a tooltip, set it and re-enable hovering
				if entry.description then
					tb_StringInformation.ToolTip = entry.description
					tb_StringInformation.CanBeFocused = true
				end

				local stringinput

				-- Make MultiLineTextBox the default, but now allow normal ones too. A single line entry does not need a multi-line textblock.
				if entry.noMLTB == true then
					stringinput = GUI.TextBox(
						GUI.RectTransform(Vector2(1, entry.boxsize), list.Content.RectTransform),
						"",
						nil,
						nil,
						nil,
						true
					)
				else
					stringinput = MultiLineTextBox(list.Content.RectTransform, "", entry.boxsize)
				end

				stringinput.Text = table.concat(entry.value, ",")

				stringinput.OnTextChangedDelegate = function(textBox)
					entry.value = CommaStringToTable(textBox.Text)
				end
			end

		-- Auto-added empty space
		elseif chunk.type == "spacer" then
			GUI.LayoutGroup(GUI.RectTransform(Vector2(1, 0.02), list.Content.RectTransform), false)

		-- Grouped Floats
		elseif chunk.type == "float_group" then
			local MaxPerRow = 2
			local row = nil
			local count = 0

			for _, item in ipairs(chunk.items) do
				-- Make a new LayoutGroup to add entries into everytime the MaxPerRow is hit (default of 2)
				if not row or (count % MaxPerRow == 0) then
					row = GUI.LayoutGroup(GUI.RectTransform(Vector2(1, 0.09), list.Content.RectTransform), true)
				end

				-- Safety check!
				if not row then
					return
				end

				-- This determines how the space in the UI is used, tied together to make fucking around a bit easier
				row.RelativeSpacing = 0.01

				local Text_space = 0.53
				local Scalar_space = 0.30
				local Reset_space = 0.07

				local baseWidth = 1 / MaxPerRow

				local textcellwidth = baseWidth * Text_space
				local scalarcellwidth = baseWidth * Scalar_space
				local resetcellwidth = baseWidth * Reset_space

				local key = item.key
				local entry = item.entry
				local resetButton

				-- Make each subdivided part of the group their own
				-- Part of the group that holds text
				local textcell = GUI.LayoutGroup(GUI.RectTransform(Vector2(textcellwidth, 1), row.RectTransform), false)
				-- Part of the group that holds the numberinput box
				local scalarcell =
					GUI.LayoutGroup(GUI.RectTransform(Vector2(scalarcellwidth, 1), row.RectTransform), false)
				-- In case a reset button is set
				local resetbuttoncell =
					GUI.LayoutGroup(GUI.RectTransform(Vector2(resetcellwidth, 0.59), row.RectTransform), false)
				-- Relativespacing but larger space for the center instead of everywhere
				local additionalspacecell =
					GUI.LayoutGroup(GUI.RectTransform(Vector2(resetcellwidth, 0.59), row.RectTransform), false)

				local minrange = entry.range and entry.range[1] or ""
				local maxrange = entry.range and entry.range[2] or ""

				local tb_EntryInformation = GUI.TextBlock(
					GUI.RectTransform(Vector2(1, 0.7), textcell.RectTransform),
					entry.name .. " (" .. minrange .. "-" .. maxrange .. ")",
					DefaultTextColour,
					nil,
					GUI.Alignment.Center,
					true,
					nil,
					Transparent
				)

				tb_EntryInformation.CanBeFocused = false

				local scalar =
					GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.6), scalarcell.RectTransform), NumberType.Float)
				scalar.PlusButton.RectTransform.RelativeSize = Vector2(1, 0.5)
				scalar.MinusButton.RectTransform.RelativeSize = Vector2(1, 0.5)

				scalar.valueStep = 0.1
				scalar.MinValueFloat = entry.range and entry.range[1] or 0
				scalar.MaxValueFloat = entry.range and entry.range[2] or 100
				scalar.FloatValue = NTConfig.Get(key, 1)

				scalar.OnValueChanged = function()
					NTConfig.Set(key, scalar.FloatValue)
				end

				-- Leftover space in the Row goes to the reset button if enabled
				if entry.resettable then
					resetButton = GUI.Button(
						GUI.RectTransform(Vector2(1, 1), resetbuttoncell.RectTransform, GUI.Anchor.BottomLeft),
						GUI.Alignment.BottomLeft,
						nil,
						Transparent
					)
					-- Give the reset button a sprite that matches its function (yoinked from basegame)
					local resetButtonStyle =
						GUI.Image(GUI.RectTransform(Vector2(1, 1), resetButton.RectTransform), "GUIButtonRefresh")
					resetButtonStyle.ToolTip = "Reset to default"

					-- On button press, fetch default value.
					resetButton.OnClicked = function()
						local defaultValue = entry.default
						scalar.FloatValue = defaultValue
						NTConfig.Set(key, defaultValue)
					end
				end

				count = count + 1
			end

		-- Grouped Strings
		elseif chunk.type == "string_group" then
			local MaxPerRow = 2
			local row = nil
			local count = 0

			for _, item in ipairs(chunk.items) do
				-- Make a new LayoutGroup to add entries into everytime the MaxPerRow is hit (default of 2)
				if not row or (count % MaxPerRow == 0) then
					row = GUI.LayoutGroup(GUI.RectTransform(Vector2(1, 0.09), list.Content.RectTransform), true)
				end

				-- Safety check!
				if not row then
					return
				end

				row.RelativeSpacing = 0.01

				local Text_space = 0.50
				-- Any less than 0.33 per string and the max value (255,255,255) or 3 digits per value will bleed (at 1920 * 1080 default)
				local String_space = 0.33
				local Reset_space = 0.07

				local baseWidth = 1 / MaxPerRow

				local textcellwidth = baseWidth * Text_space
				local scalarcellwidth = baseWidth * String_space
				local resetcellwidth = baseWidth * Reset_space

				local key = item.key
				local entry = item.entry
				local resetButton

				-- Make each subdivided part of the group their own
				-- Part of the group that holds text
				local textcell = GUI.LayoutGroup(GUI.RectTransform(Vector2(textcellwidth, 1), row.RectTransform), false)
				-- Part of the group that holds the input box
				local stringinputcell =
					GUI.LayoutGroup(GUI.RectTransform(Vector2(scalarcellwidth, 1), row.RectTransform), false)
				-- In case a reset button is set
				local resetbuttoncell =
					GUI.LayoutGroup(GUI.RectTransform(Vector2(resetcellwidth, 0.45), row.RectTransform), false)
				-- Relativespacing but larger space for the center instead of everywhere
				local additionalspacecell =
					GUI.LayoutGroup(GUI.RectTransform(Vector2(resetcellwidth, 0.59), row.RectTransform), false)

				local style = ""
				if entry.style ~= nil then
					style = " (" .. entry.style .. ")"
				end

				local tb_StringInformation = GUI.TextBlock(
					GUI.RectTransform(Vector2(1, 0.4), textcell.RectTransform),
					entry.name .. style,
					DefaultTextColour,
					nil,
					GUI.Alignment.Center,
					true,
					nil,
					Transparent
				)

				tb_StringInformation.CanBeFocused = false

				if entry.description then
					tb_StringInformation.ToolTip = entry.description
					tb_StringInformation.CanBeFocused = true
				end

				local stringinput

				-- Not all strings need a MultiLineTextBox, especially since they can just yoink the mouse cursor while scrolling.
				-- Make MLTB's a toggleable option
				if entry.noMLTB == true then
					stringinput = GUI.TextBox(
						GUI.RectTransform(
							Vector2(1, entry.boxsize),
							stringinputcell.RectTransform,
							GUI.Anchor.CenterLeft
						),
						"",
						nil,
						nil,
						nil,
						true
					)
				else
					stringinput = MultiLineTextBox(stringinputcell.RectTransform, "", entry.boxsize)
				end

				stringinput.Text = table.concat(entry.value, ",")

				stringinput.OnTextChangedDelegate = function(textBox)
					entry.value = CommaStringToTable(textBox.Text)
				end

				-- Leftover space in the Row goes to the reset button if enabled
				if entry.resettable then
					resetButton = GUI.Button(
						GUI.RectTransform(Vector2(1, 1), resetbuttoncell.RectTransform),
						GUI.Alignment.CenterRight,
						nil,
						Transparent
					)
					-- Give the reset button a sprite that matches its function (yoinked from basegame)
					local resetButtonStyle =
						GUI.Image(GUI.RectTransform(Vector2(1, 1), resetButton.RectTransform), "GUIButtonRefresh")
					resetButtonStyle.ToolTip = "Reset to default"

					-- On button press, fetch default value.
					resetButton.OnClicked = function()
						entry.value = entry.default
						stringinput.Text = table.concat(entry.value, ",")
					end
				end

				count = count + 1
			end
		end
	end

	if Game.IsMultiplayer and not Game.Client.HasPermission(ClientPermissions.ManageSettings) then
		for guicomponent in list.GetAllChildren() do
			guicomponent.enabled = false
		end
	end

	return list
end

-- Base UI construction
local function ConstructUI(parent)
	-- Set the default to display (Neurotrauma, duh)
	local selectedExpansion = "Neurotrauma"
	local list = easySettings.BasicList(parent)

	-- Get the Title block to put the drop down menu into (could be moved tbh)
	local innerLayout = list.Parent
	local children = innerLayout.RectTransform.Children
	local title = children[1].GUIComponent

	-- Get the amount of loaded expansions
	local dropdownheight = #NTConfig.Expansions

	-- Don't show the dropdown if we only have Neurotrauma or no other addons that have settings to show
	if dropdownheight > 1 then
		local dropdown_AddonSelection = GUI.DropDown(
			GUI.RectTransform(Vector2(0.18, 1), title.RectTransform),
			"",
			dropdownheight - 2,
			nil,
			false,
			false,
			GUI.Alignment.CenterLeft
		)
		dropdown_AddonSelection.ListBox.RectTransform.RelativeOffset = (Vector2(0, 0.5))
		PopulateDropdown(dropdown_AddonSelection)
		dropdown_AddonSelection.Select(0)
		dropdown_AddonSelection.ToolTip = "Choose which mod's settings to display."

		-- Using the dropdown changes a variable so we can change the page accordingly; only do so if we're not already on that page
		dropdown_AddonSelection.OnSelected = function(guiComponent)
			local newSelection = tostring(guiComponent.Text)

			-- Check if changed
			if newSelection == selectedExpansion then
				return
			end

			selectedExpansion = newSelection

			-- Redo content based on new selection
			PopulateSettingsIntoUI(list, selectedExpansion)
		end
	end

	-- Default
	PopulateSettingsIntoUI(list, selectedExpansion)
end

Networking.Receive("NT.ConfigUpdate", function(msg)
	NTConfig.ReceiveConfig(msg)

	if configUI == nil then
		return
	end
	if configUI.RectTransform == nil then
		return
	end

	local parent = configUI.RectTransform.Parent

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
