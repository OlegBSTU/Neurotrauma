
NTCyb = {} -- Neurotrauma Cybernetics
NTCyb.Name="Cybernetics"
NTCyb.Version = "A1.3.0"
NTCyb.VersionNum = 01030000
NTCyb.MinNTVersion = "A1.9.0"
NTCyb.MinNTVersionNum = 01090000
NTCyb.Path = table.pack(...)[1]
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTCyb) end end,1)

-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then

    Timer.Wait(function()
        if NT ~= nil and NT.VersionNum < 01090000 then
            print("Error loading NT Cybernetics: old Neurotrauma detected, use the modern fork published by 'guns'")
            Game.SendMessage("Error loading NT Cybernetics: old Neurotrauma detected, use the modern fork published by 'guns'")
            return
        end
        if NTC == nil then
            print("Error loading NT Cybernetics: It appears Neurotrauma isn't loaded!")
            Game.SendMessage("Error loading NT Cybernetics: It appears Neurotrauma isn't loaded!", ChatMessageType.Server)
            return
        end

        dofile(NTCyb.Path.."/Lua/Scripts/empexplosionpatch.lua")
        dofile(NTCyb.Path.."/Lua/Scripts/humanupdate.lua")
        dofile(NTCyb.Path.."/Lua/Scripts/items.lua")
        dofile(NTCyb.Path.."/Lua/Scripts/items.shared.lua")
        dofile(NTCyb.Path.."/Lua/Scripts/ondamaged.lua")
        dofile(NTCyb.Path.."/Lua/Scripts/helperfunctions.lua")
    
        dofile(NTCyb.Path.."/Lua/Scripts/testing.lua")

        NTC.AddPreHumanUpdateHook(NTCyb.UpdateHuman)
    end,1)
else
    Timer.Wait(function()
        if NT ~= nil and NT.VersionNum < 01090000 then
            local msg = "Error loading NT Cybernetics: old Neurotrauma detected, use the modern fork published by 'guns'"
            print(msg)
            Game.ChatBox.AddMessage(ChatMessage.Create("", msg, ChatMessageType.Server, nil))
            return
        end
        dofile(NTCyb.Path.."/Lua/Scripts/items.client.lua")
        dofile(NTCyb.Path.."/Lua/Scripts/items.shared.lua")
    end, 1)
end

Timer.Wait(function()
    dofile(NTCyb.Path.."/Lua/Scripts/configdata.lua")
end, 1)
