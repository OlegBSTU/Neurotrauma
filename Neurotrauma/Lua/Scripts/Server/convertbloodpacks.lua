-- THIS FILE IS NO LONGER IN USE
-- the defunct item in question has been removed from the mod
-- i'm keeping it here for...safekeeping i guess

LuaUserData.RegisterTypeBarotrauma("PurchasedItem")
LuaUserData.RegisterType("System.Xml.Linq.XElement")

local VANILLA_PREFAB_ID = "antibloodloss2"
local DEFUNCT_PREFAB_ID = "bloodpackominus"

-- Removes vanilla bloodpacks from cached stores in case the user installed
-- this mod mid-campaign.
-- NOTE: stores that had their stocks generated before installing this mod
-- won't have any new medical items added.
Hook.HookMethod("Barotrauma.Location", "LoadStores", function(instance, ptable)
	if instance.Stores == nil then
		return
	end

	for storeId, store in pairs(instance.Stores) do
		for _, purchasedItem in pairs(store.Stock) do
			local itemId = purchasedItem.ItemPrefabIdentifier
			if itemId == DEFUNCT_PREFAB_ID then
				-- print("Removing defunct bloodpack (qty " .. purchasedItem.Quantity .. ") from " .. tostring(storeId))
				store.RemoveStock({ purchasedItem })
			end
		end
	end
end, Hook.HookMethodType.After)

-- Replaces all vanilla bloodpack items with O- blood
local function replaceItems()
	local ntBloodPrefab = ItemPrefab.Prefabs[DEFUNCT_PREFAB_ID]
	local vanillaBloodPrefab = ItemPrefab.Prefabs[VANILLA_PREFAB_ID]
	if ntBloodPrefab == nil then
		print("ERROR: couldn't find " .. DEFUNCT_PREFAB_ID)
		return
	end

	for _, item in pairs(Item.ItemList) do
		local id = tostring(item.Prefab.Identifier)
		if id == DEFUNCT_PREFAB_ID then
			-- Don't replace decorative blood packs
			if item.NonInteractable then
				return
			end

			local pos = item.WorldPosition
			local inv = item.ParentInventory
			local condition = item.ConditionPercentage
			local quality = item.Quality
			-- print("replacing blood pack (pos=" .. tostring(pos) .. ", inv=" .. tostring(inv) .. ")")

			local slotIdx = -1
			if inv ~= nil then
				slotIdx = inv.FindIndex(item)
				if slotIdx < 0 then
					print(
						"ERROR: couldn't find item ("
							.. tostring(item)
							.. ", pos "
							.. tostring(pos)
							.. ") in inventory ("
							.. tostring(inv)
							.. ")"
					)
					return
				end
			end

			-- We call `Drop()` first in case the inventory is full because
			-- `AddEntityToRemoveQueue` may not remove the item before we
			-- insert the new one, causing the inventory to overflow.
			item.Drop()
			Entity.Spawner.AddEntityToRemoveQueue(item)

			Entity.Spawner.AddItemToSpawnQueue(vanillaBloodPrefab, pos, condition, quality, function(newItem)
				newItem.Rotation = item.Rotation
				-- Stolen items stay stolen
				newItem.AllowStealing = item.AllowStealing
				newItem.OriginalOutpost = item.OriginalOutpost

				if inv ~= nil then
					if not inv.TryPutItem(newItem, slotIdx, false, true, nil) then
						print(
							"ERROR: failed to replace neurotrauma bloodpack ("
								.. tostring(item)
								.. ", pos "
								.. tostring(pos)
								.. ", slotIdx "
								.. tostring(slotIdx)
								.. ", inv "
								.. tostring(inv)
								.. ") with new item: "
								.. tostring(newItem)
						)
					end
				end
			end)
		end
	end
end

Hook.Add("roundStart", "NT.ConvertBloodPacks", function()
	replaceItems()
end)

-- Hook.Add("chatMessage", "NT.BloodPackTesting", function(msg, client)
--     if (msg == "convertblood") then
--         replaceItems()
--     end
-- end)
