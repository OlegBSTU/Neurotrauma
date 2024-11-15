
NTP = {} -- Neurotrauma Pharmacy
NTP.Name="Pharmacy"
NTP.Version = "A1.0.6h3"
NTP.VersionNum = 01000603
NTP.MinNTVersion = "A1.9.0"
NTP.MinNTVersionNum = 01090000
NTP.Path = table.pack(...)[1]
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTP) end end,1)

-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then

    dofile(NTP.Path.."/Lua/Scripts/humanupdate.lua")
    dofile(NTP.Path.."/Lua/Scripts/items.lua")
    dofile(NTP.Path.."/Lua/Scripts/pills.lua")
    dofile(NTP.Path.."/Lua/Scripts/testing.lua")

    Timer.Wait(function()
        if NTC == nil then
            print("Error loading NT Pharmacy: It appears Neurotrauma isn't loaded!")
            return
        end

        NTC.AddPreHumanUpdateHook(NTP.PreUpdateHuman)
        NTC.AddHumanUpdateHook(NTP.PostUpdateHuman)
    end,1)

end