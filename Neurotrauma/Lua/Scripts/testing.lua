-- set the below variable to true to enable debug and testing features
NT.TestingEnabled = false

Hook.Add("chatMessage", "NT.testing", function(msg, client)
	if msg == "nt test" then -- a glorified suicide button
		if client.Character == nil then
			return true
		end

		HF.SetAfflictionLimb(client.Character, "gate_ta_ra", LimbType.RightArm, 100)
		HF.SetAfflictionLimb(client.Character, "gate_ta_la", LimbType.LeftArm, 100)
		HF.SetAfflictionLimb(client.Character, "gate_ta_rl", LimbType.RightLeg, 100)
		HF.SetAfflictionLimb(client.Character, "gate_ta_ll", LimbType.LeftLeg, 100)

		return true -- hide message
	elseif msg == "nt unfuck" then -- a command to remove non-sensical extremity amputations on the head and torso
		if client.Character == nil then
			return true
		end

		HF.SetAfflictionLimb(client.Character, "tll_amputation", LimbType.Head, 0)
		HF.SetAfflictionLimb(client.Character, "trl_amputation", LimbType.Head, 0)
		HF.SetAfflictionLimb(client.Character, "tla_amputation", LimbType.Head, 0)
		HF.SetAfflictionLimb(client.Character, "tra_amputation", LimbType.Head, 0)

		HF.SetAfflictionLimb(client.Character, "tll_amputation", LimbType.Torso, 0)
		HF.SetAfflictionLimb(client.Character, "trl_amputation", LimbType.Torso, 0)
		HF.SetAfflictionLimb(client.Character, "tla_amputation", LimbType.Torso, 0)
		HF.SetAfflictionLimb(client.Character, "tra_amputation", LimbType.Torso, 0)

		return true -- hide message
	elseif msg == "nt1" then
		if not NT.TestingEnabled then
			return
		end
		-- insert testing stuff here

		local test = { val = "true" }

		local function testfunc(param)
			param.val = "false"
		end

		print(test.val)
		testfunc(test)
		print(test.val)

		return true
	elseif msg == "nt2" then
		if not NT.TestingEnabled then
			return
		end
		-- insert other testing stuff here
		local crewenum = Character.GetFriendlyCrew(client.Character)
		local targetchar = nil
		local i = 0
		for char in crewenum do
			print(char.Name)
			targetchar = char
			i = i + 1
			if i == 2 then
				break
			end
		end

		client.SetClientCharacter(nil)

		print(targetchar)

		Timer.Wait(function()
			client.SetClientCharacter(targetchar)
		end, 50)

		return true
	end
end)

DebugConsole = LuaUserData.CreateStatic('Barotrauma.DebugConsole')

local function registerDebugCommands()
	LuaUserData.MakeMethodAccessible(Descriptors['Barotrauma.DebugConsole'], 'GetCharacterNames') 
	LuaUserData.MakeMethodAccessible(Descriptors['Barotrauma.DebugConsole'], 'FindMatchingCharacter') 

	LuaUserData.MakeFieldAccessible(Descriptors['Barotrauma.CharacterHealth'], 'afflictions') 
	LuaUserData.MakeFieldAccessible(Descriptors['Barotrauma.CharacterHealth'], 'limbHealths') 
	LuaUserData.MakeMethodAccessible(Descriptors['Barotrauma.CharacterHealth'], 'GetVitalityDecreaseWithVitalityMultipliers') 
	LuaUserData.RegisterType('System.Collections.Generic.Dictionary`2[[Barotrauma.Affliction],[Barotrauma.CharacterHealth+LimbHealth]]') 
	LuaUserData.RegisterType('System.Collections.Generic.KeyValuePair`2[[Barotrauma.Affliction],[Barotrauma.CharacterHealth+LimbHealth]]')

	local function findCharacter(str)
	local character = nil
	if not str or str == "" or str == "/me" then
		character = Character.Controlled
	else
		character = DebugConsole.FindMatchingCharacter({str})
	end
		return character
	end

	Game.AddCommand("nt_listafflictions", "nt_listafflictions [character name] [client/server]: Lists all afflictions on a character", 
		function(args)
			if CLIENT and args[2] == "server" then
				if Game.IsMultiplayer then
					if not args[1] or args[1] == "/me" then
						args[1] = Character.Controlled and Character.Controlled.Name or ""
					end
					Game.client.SendConsoleCommand("nt_listafflictions " .. "\"" .. args[1] .. "\"")
				end
				return
			end

			local target = findCharacter(args[1])
			if not target then return end

			print(target.Name, ' vitality: ', target.Vitality , '/', target.MaxVitality, ' Mass: ', target.Mass) 
			local genericafflictions, limbafflictions = {}, {} 
			for kvp in target.CharacterHealth.afflictions do 
				if kvp.Value then 
					if not limbafflictions[kvp.Value] then
						limbafflictions[kvp.Value] = {} 
					end 
					table.insert(limbafflictions[kvp.Value], kvp.Key) 
				else 
					table.insert(genericafflictions, kvp.Key) 
				end 
			end 
			for limbhealth, afflictions in pairs(limbafflictions) do 
			 	print(limbhealth.Name or 'Unnamed limb') 
				for affliction in afflictions do 
					print('#  ', affliction.Name, ' = ', affliction.Strength, ' (vitality decrease: ', target.CharacterHealth.GetVitalityDecreaseWithVitalityMultipliers(affliction),')') 
				end 
			end 
			print('Generic afflictions') 
			for affliction in genericafflictions do 
				print('# ', affliction.Name, ' = ', affliction.Strength, ' (vitality decrease: ', affliction.GetVitalityDecrease(target.CharacterHealth),')')
			end 
		end,
		--GetValidArguments
		function()
			return {DebugConsole.GetCharacterNames(),{"client", "server"}}
		end,
		true
	)

	Game.AddCommand("nt_nugget", "nt_nugget [character name]: Nuggets the character", 
		function(args)
			if CLIENT and Game.IsMultiplayer then
				if not args[1] or args[1] == "/me" then
					args[1] = Character.Controlled and Character.Controlled.Name or ""
				end
				Game.client.SendConsoleCommand("nt_nugget " .. "\"" .. args[1] .. "\"")
				return
			end

			local target = findCharacter(args[1])
			if not target then return end

			HF.SetAfflictionLimb(target, "gate_ta_ra", LimbType.RightArm, 100)
			HF.SetAfflictionLimb(target, "gate_ta_la", LimbType.LeftArm, 100)
			HF.SetAfflictionLimb(target, "gate_ta_rl", LimbType.RightLeg, 100)
			HF.SetAfflictionLimb(target, "gate_ta_ll", LimbType.LeftLeg, 100)
		end,
		--GetValidArguments
		function()
			return {DebugConsole.GetCharacterNames()}
		end,
		true
	)

	Game.AddCommand("nt_unnugget", "nt_unnugget [character name]: Unnuggets the character", 
		function(args)
			if CLIENT and Game.IsMultiplayer then
				if not args[1] or args[1] == "/me" then
					args[1] = Character.Controlled and Character.Controlled.Name or ""
				end
				Game.client.SendConsoleCommand("nt_unnugget " .. "\"" .. args[1] .. "\"")
				return
			end

			local target = findCharacter(args[1])
			if not target then return end

			HF.SetAfflictionLimb(target, "tll_amputation", LimbType.Head, 0)
			HF.SetAfflictionLimb(target, "trl_amputation", LimbType.Head, 0)
			HF.SetAfflictionLimb(target, "tla_amputation", LimbType.Head, 0)
			HF.SetAfflictionLimb(target, "tra_amputation", LimbType.Head, 0)

			HF.SetAfflictionLimb(target, "tll_amputation", LimbType.Torso, 0)
			HF.SetAfflictionLimb(target, "trl_amputation", LimbType.Torso, 0)
			HF.SetAfflictionLimb(target, "tla_amputation", LimbType.Torso, 0)
			HF.SetAfflictionLimb(target, "tra_amputation", LimbType.Torso, 0)
		end,
		--GetValidArguments
		function()
			return {DebugConsole.GetCharacterNames()}
		end,
		true
	)
end

Game.AddCommand("nt_debug", "nt_debug : Enables debug neurotrauma commands", function()
	if not NT.TestingEnabled then
		print("neurotrauma debug enabled")
		registerDebugCommands()
		NT.TestingEnabled = true

		local msg = Networking.Start("NT_debug")
		Networking.Send(msg)
	end
end, nil, true)

if CLIENT and Game.IsMultiplayer then
	Networking.Receive("NT_debug", function(msg)
		registerDebugCommands()
	end)
end

if NT.TestingEnabled then 
	registerDebugCommands()
end

