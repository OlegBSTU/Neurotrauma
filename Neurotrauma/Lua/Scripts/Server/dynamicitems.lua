-- Based on config settings, which items ought to be destroyed
local function DynamicRemoveItems()
	local blockedItems = HF.DynamicUnavailableItems()

	for _, item in pairs(Item.ItemList) do
		local id = item.Prefab.Identifier.Value
		if blockedItems[id] then Entity.Spawner.AddEntityToRemoveQueue(item) end
	end
end

-- On level swap, remove any items that shouldn't be there
Hook.Add("roundEnd", "nt_dynamicremoveitems", function()
	DynamicRemoveItems()
end)

-- Recreate stores command to make sure newly added items are actually in stores
Game.AddCommand("nt_recreatestores", "Recreate all stores.", function()
	if Game.GameSession.Map ~= nil then
		for location in Game.GameSession.Map.Locations do
			location.CreateStores(true)
		end
	else
		print("nt_recreatestores: Tried to recreate stores in the campaign map, but there is none!")
	end
end)
