
NTP = {} -- Neurotrauma Pharmacy
NTP.Name="Pharmacy"
NTP.Version = "A1.0.8"
NTP.VersionNum = 01000800
NTP.MinNTVersion = "A1.15.0"
NTP.MinNTVersionNum = 01150000
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

        -- Symbiote patch for pill effects with calyxanide ingredient / husk cure combo
        if NTS ~= nil then 
            dofile(NTP.Path.."/Lua/Scripts/symbiotepatch.lua")
        end
    end,1)

end