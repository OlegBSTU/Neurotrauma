function pushHistory(str, newStr)
	local substrings = {}

	for substring in str:gmatch("[^,]+") do
		table.insert(substrings, substring)
	end

	newStr = tostring(newStr) .. ","

	table.insert(substrings, newStr)

	if #substrings > 9 then
		table.remove(substrings, 1)
	end

	if #substrings > 1 then
		return table.concat(substrings, ",")
	else
		return substrings[1]
	end
end

function popHistory(str)
	local substrings = {}
	for substring in str:gmatch("[^,]+") do
		table.insert(substrings, substring)
	end

	table.remove(substrings)

	return table.concat(substrings, ",")
end

function getLastElement(str)
	local substrings = {}
	for substring in str:gmatch("[^,]+") do
		table.insert(substrings, substring)
	end

	return substrings[#substrings]
end

local blockValue = "qqwwee"

Hook.Add("neuroGuide.openPage", "neuroguide.openPage", function(effect, deltaTime, item, targets, worldPosition)
	local userCharacter = targets[1]
	local pageName = effect.Tags
	local pageIdentifier = item.Prefab.Identifier
	local targetInventory = userCharacter.Inventory

	local allowedSlots = { InvSlotType.RightHand }
	local prefab = ItemPrefab.GetItemPrefab(pageName)

	if prefab ~= nil and item ~= nil then
		local oldMemCompValue = item.GetComponentString("MemoryComponent").value

		Entity.Spawner.AddItemToRemoveQueue(item)

		Timer.Wait(function()
			Entity.Spawner.AddItemToSpawnQueue(prefab, targetInventory, nil, nil, function(newItem)
				targetInventory.TryPutItemWithAutoEquipCheck(newItem, userCharacter, allowedSlots, true)
				local newMemComp = newItem.GetComponentString("MemoryComponent")

				newMemComp.value = oldMemCompValue

				newMemComp.value = pushHistory(newMemComp.value, pageIdentifier)
			end)
		end, 100)
	end
end)

Hook.Add("neuroGuide.backButton", "neuroguide.backButton", function(effect, deltaTime, item, targets, worldPosition)
	local memComp = item.GetComponentString("MemoryComponent")

	local userCharacter = targets[1]
	local pageName = getLastElement(memComp.value)

	local targetInventory = userCharacter.Inventory

	local allowedSlots = { InvSlotType.RightHand }

	if pageName ~= nil and pageName ~= "" then
		local prefab = ItemPrefab.GetItemPrefab(pageName)

		if prefab ~= nil and item ~= nil then
			local story = popHistory(memComp.value)

			Entity.Spawner.AddItemToRemoveQueue(item)
			Timer.Wait(function()
				Entity.Spawner.AddItemToSpawnQueue(prefab, targetInventory, nil, nil, function(newItem)
					targetInventory.TryPutItemWithAutoEquipCheck(newItem, userCharacter, allowedSlots, true)

					local newMemComp = newItem.GetComponentString("MemoryComponent")
					newMemComp.value = story
				end)
			end, 100)
		end
	else
		memComp.value = "" -- Clear if smth gone wrong
	end
end)
