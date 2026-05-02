local _Int32 = LuaUserData.RegisterType("System.Int32")

-- Stack specific items together; if you want only the left leg to be cheaper than a right one go fuck yourself
local ItemVariants = {
	antibloodloss2 = "NT_ItemPrice_bloodpacks",
	bloodpackoplus = "NT_ItemPrice_bloodpacks",
	bloodpackaminus = "NT_ItemPrice_bloodpacks",
	bloodpackaplus = "NT_ItemPrice_bloodpacks",
	bloodpackbminus = "NT_ItemPrice_bloodpacks",
	bloodpackbplus = "NT_ItemPrice_bloodpacks",
	bloodpackabminus = "NT_ItemPrice_bloodpacks",
	bloodpackabplus = "NT_ItemPrice_bloodpacks",
	rarm = "NT_ItemPrice_arms",
	larm = "NT_ItemPrice_arms",
	rleg = "NT_ItemPrice_legs",
	lleg = "NT_ItemPrice_legs",
	rarmp = "NT_ItemPrice_bionicarms",
	larmp = "NT_ItemPrice_bionicarms",
	rlegp = "NT_ItemPrice_bioniclegs",
	llegp = "NT_ItemPrice_bioniclegs",
}

-- Fetch config multipliers
local function GetItemMultiplier(identifier)
	if identifier == nil then return 1.0 end

	-- Add grouping so blood bags don't fucking kill me
	local configKey = ItemVariants[identifier] or ("NT_ItemPrice_" .. identifier)

	if NTConfig.Entries[configKey] == nil then return 1.0 end

	local value = NTConfig.Get(configKey, 1.0)
	return tonumber(value) or 1.0
end

-- PRICE CHANGING
-- Hook into the price-determining function and add a multiplier
Hook.Patch("Barotrauma.Location+StoreInfo", "GetAdjustedItemBuyPrice", function(instance, ptable)
	local item = ptable["item"]
	if item == nil or item.Identifier == nil then return end

	local id = item.Identifier.Value
	local mult = GetItemMultiplier(id)

	-- Don't do extra math if the item value is unchanged
	if mult == 1.0 then return end

	-- Get the 'actual price' after the game is done with it's calculations
	local base = ptable.OriginalReturnValue
	if base == nil then return end

	-- Apply config-determined multiplier
	local result = math.floor(base * mult + 0.5)

	ptable.ReturnValue = LuaUserData.CreateUserDataFromDescriptor(result, _Int32)
end, Hook.HookMethodType.After)

-- FABRICATOR CHANGES
-- You cannot fabricate the item; this is accomplished by taking the Filter that gets made whenever you open a fabricator, and hiding the specific item IDs we want to hide.
local fabricatorType = LuaUserData.RegisterType("Barotrauma.Items.Components.Fabricator")
LuaUserData.MakeFieldAccessible(fabricatorType, "itemList")
Hook.Patch("Barotrauma.Items.Components.Fabricator", "FilterEntities", function(instance, ptable)
	Timer.Wait(function()
		local blockedItems = HF.DynamicUnavailableItems()

		for child in instance.itemList.Content.Children do
			local recipe = child.UserData

			if recipe and LuaUserData.IsTargetType(recipe, "Barotrauma.FabricationRecipe") then
				local id = recipe.TargetItem.Identifier.Value

				if blockedItems[id] then child.Visible = false end
			end
		end
	end, 1)
end, Hook.HookMethodType.After)

-- STORE CHANGES
-- You cannot buy the item; we simply hook into store availability and hide the item.
-- Ensure the items CANNOT be specials.
local storeType = LuaUserData.RegisterType("Barotrauma.Store")
LuaUserData.MakeFieldAccessible(storeType, "storeBuyList")
LuaUserData.MakeFieldAccessible(storeType, "storeDailySpecialsGroup")

Hook.Patch("Barotrauma.Store", "FilterStoreItems", {
	"Barotrauma.MapEntityCategory",
	"System.String",
}, function(instance, ptable)
	Timer.Wait(function()
		-- Fetch items to hide
		local blockedItems = HF.DynamicUnavailableItems()

		local storeList = instance.storeBuyList
		if storeList then
			for child in storeList.Content.Children do
				local item = child.UserData

				if item and item.ItemPrefab then
					local id = item.ItemPrefab.Identifier.Value
					-- Hide items within the table every refresh
					if blockedItems[id] then child.Visible = false end
				end
			end
		end
	end, 10)
end, Hook.HookMethodType.After)

-- Force config sync on level swap to ensure things go properly
Hook.Add("roundStart", "forcesyncconfig", function()
	if Game.IsMultiplayer then
		local msg = Networking.Start("NT.ConfigRequest")
		Networking.Send(msg)
	end
end)
