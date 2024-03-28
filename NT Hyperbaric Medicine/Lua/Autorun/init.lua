
NTS = {} -- Neurotrauma Symbiote
NTS.Name="Symbiote"
NTS.Version = "A1.0.0h1"
NTS.VersionNum = 01000001
NTS.MinNTVersion = "A1.8.5"
NTS.MinNTVersionNum = 01080500
NTS.Path = table.pack(...)[1]
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTS) end end,1)

-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then

    Timer.Wait(function()
        if NTC == nil then
            print("Error loading NT Symbiote: It appears Neurotrauma isn't loaded!")
            return
        end

        dofile(NTS.Path.."/Lua/Scripts/helperfunctions.lua")

        dofile(NTS.Path.."/Lua/Scripts/humanupdate.lua")
        dofile(NTS.Path.."/Lua/Scripts/items.lua")
        dofile(NTS.Path.."/Lua/Scripts/testing.lua")

    end,1)

end