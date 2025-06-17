NTSP = {} -- Neurotrauma Surgery Plus
NTSP.Name = "NT Surgery Plus"
NTSP.Version = "A1.2.5"
NTSP.VersionNum = 01020500
NTSP.MinNTVersion = "A1.7.12"
NTSP.MinNTVersionNum = 01080700
NTSP.Path = table.pack(...)[1]
Timer.Wait(function()
	if NTC ~= nil and NTC.RegisterExpansion ~= nil then
		NTC.RegisterExpansion(NTSP)
	end
end, 1)

-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then
	Timer.Wait(function()
		if NTC == nil then
			print("Error loading NT Surgery Plus: It appears Neurotrauma isn't loaded!")
			return
		end

		dofile(NTSP.Path .. "/Lua/Scripts/humanupdate.lua")
		dofile(NTSP.Path .. "/Lua/Scripts/items.lua")
		dofile(NTSP.Path .. "/Lua/Scripts/addidtags.lua")

		NTC.AddPreHumanUpdateHook(NTSP.PreUpdateHuman)
		NTC.AddHumanUpdateHook(NTSP.PostUpdateHuman)
	end, 1)
end

Timer.Wait(function()
	dofile(NTSP.Path .. "/Lua/Scripts/configdata.lua")
end, 1)
