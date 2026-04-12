--if Game.IsMultiplayer and CLIENT then return end

NT = {} -- Neurotrauma
NT.Name="Neurotrauma"
NT.Version = "A1.8.7"
NT.VersionNum = 01080700
NT.Path = table.pack(...)[1]

dofile(NT.Path.."/Lua/Scripts/helperfunctions.lua")

-- all things config
dofile(NT.Path.."/Lua/Scripts/configdata.lua")

-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then

    -- Version and expansion display
    Timer.Wait(function() Timer.Wait(function()
        local runstring = "\n/// Running Neurotrauma V "..NT.Version.." ///\n"

        -- add dashes
        local linelength = string.len(runstring)+4
        local i = 0
        while i < linelength do runstring=runstring.."-" i=i+1 end
        local hasAddons = #NTC.RegisteredExpansions>0

        -- add expansions
        for val in NTC.RegisteredExpansions do
            runstring = runstring.."\n+ "..(val.Name or "Unnamed expansion").." V "..(val.Version or "???")
            if val.MinNTVersion ~= nil and NT.VersionNum < (val.MinNTVersionNum or 1) then
                runstring = runstring.."\n-- WARNING! Neurotrauma version "..val.MinNTVersion.." or higher required!"
            end
        end

        -- No expansions
        runstring=runstring.."\n"
        if not hasAddons then
            runstring = runstring.."- Not running any expansions\n"
        end

        print(runstring)
    end,1) end,1)

    dofile(NT.Path.."/Lua/Scripts/Server/ntcompat.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/blood.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/humanupdate.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/ondamaged.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/items.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/onfire.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/cpr.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/surgerytable.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/fuckbots.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/lootcrates.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/multiscalpel.lua") -- its important for this to run after items.lua
    dofile(NT.Path.."/Lua/Scripts/Server/falldamage.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/screams.lua")
    dofile(NT.Path.."/Lua/Scripts/Server/modconflict.lua")
    
    dofile(NT.Path.."/Lua/Scripts/testing.lua")
end

-- client-side code
if CLIENT then
    dofile(NT.Path.."/Lua/Scripts/Client/configgui.lua")
end