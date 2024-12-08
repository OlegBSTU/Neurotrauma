-- Modders, please use ModDir:Neurotrauma when taking dependencies, and
-- name your patches with the word "neurotrauma" (letter case doesnt matter)

-- sets NT.modconflict to true if incompatible mod detected
-- this applies meta affliction "modconflict" every round
-- prints out the warning and incompatible mod on server startup
-- Hooks Lua event "roundStart" to do the above each round
NT.modconflict = false
function NT.CheckModConflicts()
	NT.modconflict = false
	if NTConfig.Get("NT_ignoreModConflicts", false) then
		return
	end

	local itemsToCheck = { "antidama2", "opdeco_hospitalbed" }

	for prefab in ItemPrefab.Prefabs do
		if HF.TableContains(itemsToCheck, prefab.Identifier.Value) then
			local mod = prefab.ConfigElement.ContentPackage.Name
			if not string.find(string.lower(mod), "neurotrauma") then
				NT.modconflict = true
				print("Found Neurotrauma incompatibility with mod: ", mod)
				print("WARNING! mod conflict detected! Neurotrauma may not function correctly and requires a patch!")
				return
			end
		end
	end
end

Timer.Wait(function()
	NT.CheckModConflicts()
end, 1000)
Hook.Add("roundStart", "NT.RoundStart.modconflicts", function()
	Timer.Wait(function()
		NT.CheckModConflicts()
	end, 10000)
end)
