-- Spawns items inside medstartercrate
-- Hooks XML Lua event "NT.medstartercrate.spawn" to create medstartercrate items and put them inside it
Hook.Add(
	"NT.medstartercrate.spawn",
	"NT.medstartercrate.spawn",
	function(effect, deltaTime, item, targets, worldPosition)
		Timer.Wait(function()
			if item == nil then
				return
			end

			-- check if the item already got populated before
			-- got broken somehow and is no longer needed, handled with oneshot="true" for the StatusEffect inside the medstartercrate item that calls this hook on spawn

			-- local populated = item.HasTag("used")
			-- if populated then return end

			-- add used tag

			-- local tags = HF.SplitString(item.Tags,",")
			-- table.insert(tags,"used")
			-- local tagstring = ""
			-- for index, value in ipairs(tags) do
			-- tagstring = tagstring..value
			-- if index < #tags then tagstring=tagstring.."," end
			-- end
			-- item.Tags = tagstring

			-- populate with goodies!!

			if item.Scale == 0.5 then
				return
			end
			item.Scale = 0.5
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
				HF.SpawnItemPlusFunction("antisepticspray", function(params2)
					HF.SpawnItemPlusFunction("antiseptic", nil, nil, params2.item.OwnInventory, 0)
				end, nil, params.item.OwnInventory, 5)
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
				HF.SpawnItemPlusFunction("organscalpel_kidneys", nil, nil, params.item.OwnInventory, 8)
				HF.SpawnItemPlusFunction("organscalpel_liver", nil, nil, params.item.OwnInventory, 9)
				HF.SpawnItemPlusFunction("organscalpel_lungs", nil, nil, params.item.OwnInventory, 10)
				HF.SpawnItemPlusFunction("organscalpel_heart", nil, nil, params.item.OwnInventory, 11)
			end, nil, item.OwnInventory, 3)

			HF.SpawnItemPlusFunction("bloodanalyzer", nil, nil, item.OwnInventory, 6)
			HF.SpawnItemPlusFunction("healthscanner", function(params)
				local prefab = ItemPrefab.GetItemPrefab("batterycell")
				Entity.Spawner.AddItemToSpawnQueue(prefab, params["item"].WorldPosition, nil, nil, function(batteryItem)
					params["item"].OwnInventory.TryPutItem(batteryItem)
				end)
			end, nil, item.OwnInventory, 7)
		end, 35)
	end
)

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
