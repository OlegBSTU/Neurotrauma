
NTTut = {} -- Neurotrauma Tutorial
NTTut.Name="NeuroTutorial"
NTTut.Version = "1.04"
NTTut.VersionNum = 01040000
NTTut.MinNTVersion = "A1.8.0h1"
NTTut.MinNTVersionNum = 01080001
NTTut.Path = table.pack(...)[1]
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTTut) end end,1)

-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then

    dofile(NTTut.Path.."/Lua/Scripts/HF.lua")
    dofile(NTTut.Path.."/Lua/Scripts/Server/signalitems.lua")
    dofile(NTTut.Path.."/Lua/Scripts/Server/inertiainhibitor.lua")
    
    Timer.Wait(function()
        if NTC == nil then
            print("Error loading NeuroTutorial: It appears Neurotrauma isn't loaded!")
            return
        end
    end,1)

end
