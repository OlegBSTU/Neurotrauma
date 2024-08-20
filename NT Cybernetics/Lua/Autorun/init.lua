
NTCyb = {} -- Neurotrauma Cybernetics
NTCyb.Name="Cybernetics"
NTCyb.Version = "A1.2.4h1"
NTCyb.VersionNum = 01020401
NTCyb.MinNTVersion = "A1.8.7"
NTCyb.MinNTVersionNum = 01080700
NTCyb.Path = table.pack(...)[1]
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTCyb) end end,1)

-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then

    Timer.Wait(function()
        if NTC == nil then
            print("Error loading NT Cybernetics: It appears Neurotrauma isn't loaded!")
            return
        end

        dofile(NTCyb.Path.."/Lua/Scripts/empexplosionpatch.lua")
        dofile(NTCyb.Path.."/Lua/Scripts/humanupdate.lua")
        dofile(NTCyb.Path.."/Lua/Scripts/items.lua")
        dofile(NTCyb.Path.."/Lua/Scripts/ondamaged.lua")
        dofile(NTCyb.Path.."/Lua/Scripts/helperfunctions.lua")
        dofile(NTCyb.Path.."/Lua/Scripts/configdata.lua")
    
        dofile(NTCyb.Path.."/Lua/Scripts/testing.lua")

        NTC.AddPreHumanUpdateHook(NTCyb.UpdateHuman)
    end,1)
else
    Timer.Wait(function()
        dofile(NTCyb.Path.."/Lua/Scripts/items.client.lua")
    end, 1)
end
