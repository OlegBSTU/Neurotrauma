
NTHM = {} -- Neurotrauma Symbiote
NTHM.Name="Symbiote"
NTHM.Version = "A1.0.0h0"
NTHM.VersionNum = 01000000
NTHM.MinNTVersion = "A1.9.0"
NTHM.MinNTVersionNum = 01090000
NTHM.Path = table.pack(...)[1]
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTHM) end end,1)

-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then

    Timer.Wait(function()
        if NTC == nil then
            print("Error loading NT Hyperbaric Medicine: It appears Neurotrauma isn't loaded!")
            return
        end

        -- dofile(NTHM.Path.."/Lua/Scripts/helperfunctions.lua")

        -- dofile(NTHM.Path.."/Lua/Scripts/humanupdate.lua")
        -- dofile(NTHM.Path.."/Lua/Scripts/items.lua")
        -- dofile(NTHM.Path.."/Lua/Scripts/testing.lua")

    end,1)

end