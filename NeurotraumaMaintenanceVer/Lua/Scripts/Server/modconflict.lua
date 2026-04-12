Timer.Wait(function()
    NT.CheckModConflicts()
end,1000)

Hook.Add("roundStart", "NT.RoundStart.modconflicts", function()
    Timer.Wait(function()
        NT.CheckModConflicts()
    end,10000)
    
end)

NT.modconflict = false
function NT.CheckModConflicts()
    NT.modconflict = false
    if NTConfig.Get("NT_ignoreModConflicts",false) then return end

    local itemsToCheck = {"antidama2","opdeco_hospitalbed"}

    for prefab in ItemPrefab.Prefabs do
        if HF.TableContains(itemsToCheck,prefab.Identifier.Value) then
            local mod = prefab.ConfigElement.ContentPackage.Name
            if mod ~= "Neurotrauma" then
                NT.modconflict = true
                print("WARNING! mod conflict detected! Neurotrauma may not function correctly!")
                return
            end
        end
    end

end