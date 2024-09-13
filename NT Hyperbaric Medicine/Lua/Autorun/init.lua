
NTHM = {} -- Neurotrauma Hyperbaric
NTHM.Name="Hyperbaric"
NTHM.Version = "A1.0.0"
NTHM.VersionNum = 01000000
NTHM.MinNTVersion = "A1.9.0"
NTHM.MinNTVersionNum = 01090000
NTHM.Path = table.pack(...)[1]
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTHM) end end,1)

Timer.Wait(function()

	if NTC == nil then
		print("Error loading NT Hyperbaric: It appears Neurotrauma isn't loaded!")
		return
	end
	
		--server side or singleplayer scripts
	if SERVER or (CLIENT and not Game.IsMultiplayer) then
		--dofile(NTHM.Path.."/Lua/Server/template.lua")
	end
	
	
		--client side only scripts (in case we want to add visuals)
	if CLIENT then
		--dofile(NTHM.Path.."/Lua/Client/template.lua")
	end
	
	
end,1)