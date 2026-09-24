-- Spawns items inside specified container
NT.ContainerFillsStartsWith = {}
NT.ContainerFills = {}
NT.ContainerFills.medstartercrate = {
	func = function(item)
		HF.SpawnItemPlusFunction("medtoolbox", function(params)
			HF.SpawnItemPlusFunction("defibrillator", nil, nil, params.item.OwnInventory, 0)
			HF.SpawnItemPlusFunction("autocpr", nil, nil, params.item.OwnInventory, 1)
			for i = 1, 2, 1 do
				HF.SpawnItemPlusFunction("tourniquet", nil, nil, params.item.OwnInventory, 2)
			end
			for i = 1, 2, 1 do
				HF.SpawnItemPlusFunction("ringerssolution", nil, nil, params.item.OwnInventory, 3)
			end
			HF.SpawnItemPlusFunction("surgicaldrill", nil, nil, params.item.OwnInventory, 4)
			HF.SpawnItemPlusFunction("surgerysaw", nil, nil, params.item.OwnInventory, 5)
		end, nil, item.OwnInventory, 0)

		HF.SpawnItemPlusFunction("medtoolbox", function(params)
			HF.SpawnItemPlusFunction("antibleeding1", nil, nil, params.item.OwnInventory, 0)
			HF.SpawnItemPlusFunction("gypsum", nil, nil, params.item.OwnInventory, 1)
			HF.SpawnItemPlusFunction("opium", nil, nil, params.item.OwnInventory, 2)
			HF.SpawnItemPlusFunction("antibiotics", nil, nil, params.item.OwnInventory, 3)
			HF.SpawnItemPlusFunction("ointment", nil, nil, params.item.OwnInventory, 4)
		end, nil, item.OwnInventory, 1)

		HF.SpawnItemPlusFunction("surgerytoolbox", function(params)
			HF.SpawnItemPlusFunction("advscalpel", nil, nil, params.item.OwnInventory, 0)
			HF.SpawnItemPlusFunction("advhemostat", nil, nil, params.item.OwnInventory, 1)
			HF.SpawnItemPlusFunction("advretractors", nil, nil, params.item.OwnInventory, 2)
			for i = 1, 16, 1 do
				HF.SpawnItemPlusFunction("suture", nil, nil, params.item.OwnInventory, 3)
			end
			HF.SpawnItemPlusFunction("tweezers", nil, nil, params.item.OwnInventory, 4)
			HF.SpawnItemPlusFunction("traumashears", nil, nil, params.item.OwnInventory, 5)
			HF.SpawnItemPlusFunction("drainage", nil, nil, params.item.OwnInventory, 6)
			HF.SpawnItemPlusFunction("needle", nil, nil, params.item.OwnInventory, 7)
		end, nil, item.OwnInventory, 3)

		HF.SpawnItemPlusFunction("bloodanalyzer", nil, nil, item.OwnInventory, 6)
		HF.SpawnItemPlusFunction("healthscanner", function(params)
			local prefab = ItemPrefab.GetItemPrefab("batterycell")
			Entity.Spawner.AddItemToSpawnQueue(prefab, params["item"].WorldPosition, nil, nil, function(batteryItem)
				params["item"].OwnInventory.TryPutItem(batteryItem)
			end)
		end, nil, item.OwnInventory, 7)
	end,
	desiredcontainer = "any",
}

NT.ContainerFills.surgerytoolboxset = {
	func = function(item)
		HF.SpawnItemPlusFunction("advscalpel", nil, nil, item.OwnInventory, 0)
		HF.SpawnItemPlusFunction("advhemostat", nil, nil, item.OwnInventory, 1)
		HF.SpawnItemPlusFunction("advretractors", nil, nil, item.OwnInventory, 2)
		HF.SpawnItemPlusFunction("tweezers", nil, nil, item.OwnInventory, 3)
		HF.SpawnItemPlusFunction("traumashears", nil, nil, item.OwnInventory, 4)
		HF.SpawnItemPlusFunction("surgicaldrill", nil, nil, item.OwnInventory, 5)
		HF.SpawnItemPlusFunction("surgerysaw", nil, nil, item.OwnInventory, 6)
	end,
	desiredcontainer = "any",
}

NT.ContainerFills.surgerytoolboxsetscalpel = {
	func = function(item)
		HF.SpawnItemPlusFunction("advscalpel", nil, nil, item.OwnInventory, 0)
		HF.SpawnItemPlusFunction("advhemostat", nil, nil, item.OwnInventory, 1)
		HF.SpawnItemPlusFunction("advretractors", nil, nil, item.OwnInventory, 2)
		HF.SpawnItemPlusFunction("tweezers", nil, nil, item.OwnInventory, 3)
		HF.SpawnItemPlusFunction("traumashears", nil, nil, item.OwnInventory, 4)
		HF.SpawnItemPlusFunction("surgicaldrill", nil, nil, item.OwnInventory, 5)
		HF.SpawnItemPlusFunction("surgerysaw", nil, nil, item.OwnInventory, 6)
		HF.SpawnItemPlusFunction("organscalpel_liver", nil, nil, item.OwnInventory, 7)
		HF.SpawnItemPlusFunction("organscalpel_kidneys", nil, nil, item.OwnInventory, 8)
		HF.SpawnItemPlusFunction("organscalpel_heart", nil, nil, item.OwnInventory, 9)
		HF.SpawnItemPlusFunction("organscalpel_lungs", nil, nil, item.OwnInventory, 10)
		HF.SpawnItemPlusFunction("organscalpel_brain", nil, nil, item.OwnInventory, 11)
	end,
	desiredcontainer = "any",
}

NT.ContainerFills.surgerytoolboxsetstarter = {
	func = function(item)
		HF.SpawnItemPlusFunction("advscalpel", nil, nil, item.OwnInventory, 0)
		HF.SpawnItemPlusFunction("advhemostat", nil, nil, item.OwnInventory, 1)
		HF.SpawnItemPlusFunction("advretractors", nil, nil, item.OwnInventory, 2)
		HF.SpawnItemPlusFunction("tweezers", nil, nil, item.OwnInventory, 3)
		HF.SpawnItemPlusFunction("traumashears", nil, nil, item.OwnInventory, 4)
		HF.SpawnItemPlusFunction("surgicaldrill", nil, nil, item.OwnInventory, 5)
		HF.SpawnItemPlusFunction("surgerysaw", nil, nil, item.OwnInventory, 6)
		HF.SpawnItemPlusFunction("osteosynthesisimplants", nil, nil, item.OwnInventory, 7)
		HF.SpawnItemPlusFunction("spinalimplant", nil, nil, item.OwnInventory, 8)
		for i = 1, 4, 1 do
			HF.SpawnItemPlusFunction("drainage", nil, nil, item.OwnInventory, 9)
		end
		HF.SpawnItemPlusFunction("multiscalpel", nil, nil, item.OwnInventory, 10)
		for i = 1, 16, 1 do
			HF.SpawnItemPlusFunction("suture", nil, nil, item.OwnInventory, 11)
		end
	end,
	desiredcontainer = "medcabinet",
}

NT.ContainerFills.organtoolbox = {
	func = function(item)
		HF.SpawnItemPlusFunction("gelipack", nil, nil, item.OwnInventory, 0)
		HF.SpawnItemPlusFunction("gelipack", nil, nil, item.OwnInventory, 1)
	end,
	desiredcontainer = "medcabinet",
}

NT.ContainerFills.aed = {
	func = function(item)
		HF.SpawnItemPlusFunction("batterycell", nil, nil, item.OwnInventory, 0)
	end,
	desiredcontainer = "medcabinet",
}

NT.ContainerFills.antisepticspray = {
	func = function(item)
		HF.SpawnItemPlusFunction("antiseptic", nil, nil, item.OwnInventory, 0)
	end,
	desiredcontainer = "medcabinet",
}

NT.ContainerFills.bvm = {
	func = function(item)
		HF.SpawnItemPlusFunction("oxygentank", nil, nil, item.OwnInventory, 0)
	end,
	desiredcontainer = "medcabinet",
}

NT.ContainerFills.autocpr = {
	func = function(item)
		HF.SpawnItemPlusFunction("batterycell", nil, nil, item.OwnInventory, 0)
	end,
	desiredcontainer = "medcabinet",
}

-- Hooks XML Lua event "NT.container.spawn" to create container items and put them inside it
Hook.Add("NT.containerfills.spawn", "NT.containerfills.spawn", function(effect, deltaTime, item, targets, worldPosition)
	if item == nil then return end

	local parentEntityString = string.lower(item.ContainerIdentifier.ToString())
	local identifier = item.Prefab.Identifier.Value

	if
		not string.find(NT.ContainerFills[identifier].desiredcontainer, "any")
		and not string.find(parentEntityString, NT.ContainerFills[identifier].desiredcontainer)
	then
		return
	end

	local methodtorun = NT.ContainerFills[identifier].func
	if methodtorun ~= nil then
		methodtorun(item)
		return
	end

	-- StartsWith functions
	for key, value in pairs(NT.ContainerFillsStartsWith) do
		if HF.StartsWith(identifier, key) then
			value(item, usingCharacter, targetCharacter, limb)
			return
		end
	end
end)

Hook.Add("character.giveJobItems", "NT.giveHealthScannersBatteries", function(character)
	Timer.Wait(function()
		for item in character.Inventory.AllItems do
			local thisIdentifier = item.Prefab.Identifier.Value
			if thisIdentifier == "healthscanner" then
				if item.OwnInventory ~= nil and item.OwnInventory.GetItemAt(0) == nil then
					local prefab = ItemPrefab.GetItemPrefab("batterycell")
					Entity.Spawner.AddItemToSpawnQueue(prefab, character.WorldPosition, nil, nil, function(batteryItem)
						item.OwnInventory.TryPutItem(batteryItem, character)
					end)
				end
			end
		end
	end, 1000)
end)
