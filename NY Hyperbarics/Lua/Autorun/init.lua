-- I actually dont now lua and have no idea if this is correct (probably version numbers are incorrect, anything else should be fin I hope)

NTS = {} -- Neurotrauma Hyperbarics
NTS.Name="Hyperbarics"
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
            print("Error loading NT Hyperbarics: It appears Neurotrauma isn't loaded!")
            return
        end

-- Insert other lua files here

    end,1)

end