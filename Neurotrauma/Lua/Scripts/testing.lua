-- set the below variable to true to enable debug and testing features
NT.TestingEnabled = false

Hook.Add("chatMessage", "NT.testing", function(msg, client)
	if msg == "nt test" then -- a glorified suicide button
		if client.Character == nil then return true end

		HF.SetAfflictionLimb(client.Character, "gate_ta_ra", LimbType.RightArm, 100)
		HF.SetAfflictionLimb(client.Character, "gate_ta_la", LimbType.LeftArm, 100)
		HF.SetAfflictionLimb(client.Character, "gate_ta_rl", LimbType.RightLeg, 100)
		HF.SetAfflictionLimb(client.Character, "gate_ta_ll", LimbType.LeftLeg, 100)

		return true -- hide message
	elseif msg == "nt unfuck" then -- a command to remove non-sensical stuff
		if client.Character == nil then return true end

		HF.SetAfflictionLimb(client.Character, "tll_amputation", LimbType.Head, 0)
		HF.SetAfflictionLimb(client.Character, "trl_amputation", LimbType.Head, 0)
		HF.SetAfflictionLimb(client.Character, "tla_amputation", LimbType.Head, 0)
		HF.SetAfflictionLimb(client.Character, "tra_amputation", LimbType.Head, 0)

		HF.SetAfflictionLimb(client.Character, "tll_amputation", LimbType.Torso, 0)
		HF.SetAfflictionLimb(client.Character, "trl_amputation", LimbType.Torso, 0)
		HF.SetAfflictionLimb(client.Character, "tla_amputation", LimbType.Torso, 0)
		HF.SetAfflictionLimb(client.Character, "tra_amputation", LimbType.Torso, 0)

		for key, character in pairs(Character.CharacterList) do
			if not character.IsDead then
				if character.IsHuman then
					HF.AddAffliction(character, "luabotomypurger", 2)
					if character.TeamID == 1 or character.TeamID == 2 then
						Timer.Wait(function()
							HF.SetAffliction(character, "luabotomy", 0.1)
						end, 4000)
					end
				end
			end
		end

		return true -- hide message
	elseif msg == "nt1" then
		if not NT.TestingEnabled then return end
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
		if not NT.TestingEnabled then return end
		-- insert other testing stuff here
		local crewenum = Character.GetFriendlyCrew(client.Character)
		local targetchar = nil
		local i = 0
		for char in crewenum do
			print(char.Name)
			targetchar = char
			i = i + 1
			if i == 2 then break end
		end

		client.SetClientCharacter(nil)

		print(targetchar)

		Timer.Wait(function()
			client.SetClientCharacter(targetchar)
		end, 50)

		return true
	end
end)

DebugConsole = LuaUserData.CreateStatic("Barotrauma.DebugConsole")

local function registerDebugCommands()
	if NT.DebugCommandsRegistered then return end
	NT.DebugCommandsRegistered = true

	LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.DebugConsole"], "GetCharacterNames")
	LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.DebugConsole"], "FindMatchingCharacter")

	LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CharacterHealth"], "afflictions")
	LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CharacterHealth"], "limbHealths")
	LuaUserData.MakeMethodAccessible(
		Descriptors["Barotrauma.CharacterHealth"],
		"GetVitalityDecreaseWithVitalityMultipliers"
	)
	LuaUserData.RegisterType(
		"System.Collections.Generic.Dictionary`2[[Barotrauma.Affliction],[Barotrauma.CharacterHealth+LimbHealth]]"
	)
	LuaUserData.RegisterType(
		"System.Collections.Generic.KeyValuePair`2[[Barotrauma.Affliction],[Barotrauma.CharacterHealth+LimbHealth]]"
	)

	local function findCharacter(str)
		local character = nil
		if not str or str == "" or str == "/me" then
			character = Character.Controlled
		else
			character = DebugConsole.FindMatchingCharacter({ str })
		end
		return character
	end

	local limbAliases = {
		leftarm = LimbType.LeftArm,
		la = LimbType.LeftArm,
		larm = LimbType.LeftArm,
		bracoe = LimbType.LeftArm,
		rightarm = LimbType.RightArm,
		ra = LimbType.RightArm,
		rarm = LimbType.RightArm,
		bracod = LimbType.RightArm,
		leftleg = LimbType.LeftLeg,
		ll = LimbType.LeftLeg,
		lleg = LimbType.LeftLeg,
		pernae = LimbType.LeftLeg,
		rightleg = LimbType.RightLeg,
		rl = LimbType.RightLeg,
		rleg = LimbType.RightLeg,
		pernad = LimbType.RightLeg,
		head = LimbType.Head,
		cabeca = LimbType.Head,
		torso = LimbType.Torso,
	}

	local randomExtremities = {
		LimbType.LeftArm,
		LimbType.RightArm,
		LimbType.LeftLeg,
		LimbType.RightLeg,
	}

	local function normalizeText(value)
		if value == nil then return nil end
		value = string.lower(tostring(value))
		value = string.gsub(value, "[áàâã]", "a")
		value = string.gsub(value, "[éèê]", "e")
		value = string.gsub(value, "[íìî]", "i")
		value = string.gsub(value, "[óòôõ]", "o")
		value = string.gsub(value, "[úùû]", "u")
		value = string.gsub(value, "ç", "c")
		return value
	end

	local function randomFrom(list)
		return list[math.random(1, #list)]
	end

	local function resolveTestLimb(value, allowTorsoHead)
		local key = normalizeText(value)
		if key == nil or key == "" or key == "random" or key == "any" or key == "qualquer" then
			return randomFrom(randomExtremities)
		end
		if key == "arm" or key == "braco" then return randomFrom({ LimbType.LeftArm, LimbType.RightArm }) end
		if key == "leg" or key == "perna" then return randomFrom({ LimbType.LeftLeg, LimbType.RightLeg }) end

		local limb = limbAliases[key]
		if limb == LimbType.Head or limb == LimbType.Torso then
			return allowTorsoHead and limb or randomFrom(randomExtremities)
		end
		return limb or randomFrom(randomExtremities)
	end

	local function limbLabel(limb)
		if limb == LimbType.LeftArm then return "braco esquerdo" end
		if limb == LimbType.RightArm then return "braco direito" end
		if limb == LimbType.LeftLeg then return "perna esquerda" end
		if limb == LimbType.RightLeg then return "perna direita" end
		if limb == LimbType.Head then return "cabeca" end
		if limb == LimbType.Torso then return "torso" end
		return "membro desconhecido"
	end

	local function sendBotTestCommand(command, args)
		if CLIENT and Game.IsMultiplayer then
			local limbArg = args[1] or "random"
			local characterName = args[2]
			if not characterName or characterName == "" or characterName == "/me" then
				characterName = Character.Controlled and Character.Controlled.Name or ""
			end
			Game.client.SendConsoleCommand(command .. " " .. limbArg .. " " .. '"' .. characterName .. '"')
			return true
		end
		return false
	end

	local function botTestTarget(args)
		return findCharacter(args[2])
	end

	local function printBotTestResult(name, target, limb)
		print("[NT BotTest] " .. name .. " aplicado em " .. tostring(target.Name) .. " (" .. limbLabel(limb) .. ")")
	end

	Game.AddCommand(
		"nt_listafflictions",
		"nt_listafflictions [character name] [client/server]: Lists all afflictions on a character",
		function(args)
			if CLIENT and args[2] == "server" then
				if Game.IsMultiplayer then
					if not args[1] or args[1] == "/me" then
						args[1] = Character.Controlled and Character.Controlled.Name or ""
					end
					Game.client.SendConsoleCommand("nt_listafflictions " .. '"' .. args[1] .. '"')
				end
				return
			end

			local target = findCharacter(args[1])
			if not target then return end

			print(target.Name, " vitality: ", target.Vitality, "/", target.MaxVitality, " Mass: ", target.Mass)
			local genericafflictions, limbafflictions = {}, {}
			for kvp in target.CharacterHealth.afflictions do
				if kvp.Value then
					if not limbafflictions[kvp.Value] then limbafflictions[kvp.Value] = {} end
					table.insert(limbafflictions[kvp.Value], kvp.Key)
				else
					table.insert(genericafflictions, kvp.Key)
				end
			end
			for limbhealth, afflictions in pairs(limbafflictions) do
				print(limbhealth.Name or "Unnamed limb")
				for affliction in afflictions do
					print(
						"#  ",
						affliction.Name,
						" = ",
						affliction.Strength,
						" (vitality decrease: ",
						target.CharacterHealth.GetVitalityDecreaseWithVitalityMultipliers(affliction),
						")"
					)
				end
			end
			print("Generic afflictions")
			for affliction in genericafflictions do
				print(
					"# ",
					affliction.Name,
					" = ",
					affliction.Strength,
					" (vitality decrease: ",
					affliction.GetVitalityDecrease(target.CharacterHealth),
					")"
				)
			end
		end,
		--GetValidArguments
		function()
			return { DebugConsole.GetCharacterNames(), { "client", "server" } }
		end,
		true
	)

	Game.AddCommand(
		"nt_listcreatures",
		"nt_listcreatures [printafflictionsgeneric/printafflictionsfull]: Lists all non-human creatures currently on the server",
		function(args)
			if CLIENT and Game.IsMultiplayer then
				Game.client.SendConsoleCommand("nt_listcreatures " .. '"' .. args[1] .. '"')
				return
			end

			local function printAfflictions(target, args)
				local genericafflictions, limbafflictions = {}, {}
				for kvp in target.CharacterHealth.afflictions do
					if kvp.Value then
						if not limbafflictions[kvp.Value] then limbafflictions[kvp.Value] = {} end
						table.insert(limbafflictions[kvp.Value], kvp.Key)
					else
						table.insert(genericafflictions, kvp.Key)
					end
				end
				if args[1] == "printafflictionsgeneric" or args[1] == "printafflictionsfull" then
					print("Generic afflictions")
					for affliction in genericafflictions do
						print(
							"# ",
							affliction.Name,
							" = ",
							affliction.Strength,
							" (vitality decrease: ",
							affliction.GetVitalityDecrease(target.CharacterHealth),
							")"
						)
					end
				end
				if args[1] == "printafflictionsfull" then
					print("Limb afflictions")
					for limbhealth, afflictions in pairs(limbafflictions) do
						print(limbhealth.Name or "Unnamed limb")
						for affliction in afflictions do
							print(
								"#  ",
								affliction.Name,
								" = ",
								affliction.Strength,
								" (vitality decrease: ",
								target.CharacterHealth.GetVitalityDecreaseWithVitalityMultipliers(affliction),
								")"
							)
						end
					end
				end
			end

			for key, character in pairs(Character.CharacterList) do
				if not character.IsHuman then
					print(
						character.SpeciesName,
						" vitality: ",
						character.Vitality,
						"/",
						character.MaxVitality,
						" Mass: ",
						character.Mass
					)
					if args[1] == "printafflictionsgeneric" or args[1] == "printafflictionsfull" then
						printAfflictions(character, args)
					end
				end
			end
		end,
		--GetValidArguments
		function()
			return { { "printafflictionsgeneric", "printafflictionsfull" } }
		end,
		true
	)

	Game.AddCommand(
		"nt_nugget",
		"nt_nugget [character name]: Nuggets the character",
		function(args)
			if CLIENT and Game.IsMultiplayer then
				if not args[1] or args[1] == "/me" then
					args[1] = Character.Controlled and Character.Controlled.Name or ""
				end
				Game.client.SendConsoleCommand("nt_nugget " .. '"' .. args[1] .. '"')
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
			return { DebugConsole.GetCharacterNames() }
		end,
		true
	)

	Game.AddCommand(
		"nt_unnugget",
		"nt_unnugget [character name]: Unnuggets the character",
		function(args)
			if CLIENT and Game.IsMultiplayer then
				if not args[1] or args[1] == "/me" then
					args[1] = Character.Controlled and Character.Controlled.Name or ""
				end
				Game.client.SendConsoleCommand("nt_unnugget " .. '"' .. args[1] .. '"')
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
			return { DebugConsole.GetCharacterNames() }
		end,
		true
	)

	Game.AddCommand(
		"nt_bt_fracture",
		"nt_bt_fracture [random/arm/leg/leftarm/rightarm/leftleg/rightleg] [character name]: breaks an arm or leg for bot first-aid testing",
		function(args)
			if sendBotTestCommand("nt_bt_fracture", args) then return end

			local target = botTestTarget(args)
			if not target then return end
			local limb = resolveTestLimb(args[1], false)
			NT.BreakLimb(target, limb, 100)
			HF.AddAfflictionLimb(target, "blunttrauma", limb, 25, target)
			HF.AddAfflictionLimb(target, "pain_extremity", limb, 25, target)
			HF.AddAfflictionLimb(target, "bleeding", limb, 8, target)
			printBotTestResult("fratura", target, limb)
		end,
		function()
			return { { "random", "arm", "leg", "leftarm", "rightarm", "leftleg", "rightleg" }, DebugConsole.GetCharacterNames() }
		end,
		true
	)

	Game.AddCommand(
		"nt_bt_artery",
		"nt_bt_artery [random/arm/leg/leftarm/rightarm/leftleg/rightleg/torso/head] [character name]: cuts an artery for emergency bot testing",
		function(args)
			if sendBotTestCommand("nt_bt_artery", args) then return end

			local target = botTestTarget(args)
			if not target then return end
			local limb = resolveTestLimb(args[1], true)
			NT.ArteryCutLimb(target, limb, 25)
			HF.AddAfflictionLimb(target, "lacerations", limb, 20, target)
			HF.AddAfflictionLimb(target, "bleeding", limb, 45, target)
			HF.AddAfflictionLimb(target, "bleedingnonstop", limb, 25, target)
			HF.AddAffliction(target, "bloodloss", 15, target)
			printBotTestResult("corte arterial", target, limb)
		end,
		function()
			return { { "random", "arm", "leg", "leftarm", "rightarm", "leftleg", "rightleg", "torso", "head" }, DebugConsole.GetCharacterNames() }
		end,
		true
	)

	Game.AddCommand(
		"nt_bt_bleed",
		"nt_bt_bleed [random/arm/leg/leftarm/rightarm/leftleg/rightleg/torso/head] [character name]: creates severe bleeding and a wound for bot testing",
		function(args)
			if sendBotTestCommand("nt_bt_bleed", args) then return end

			local target = botTestTarget(args)
			if not target then return end
			local limb = resolveTestLimb(args[1], true)
			HF.AddAfflictionLimb(target, "gunshotwound", limb, 35, target)
			HF.AddAfflictionLimb(target, "lacerations", limb, 20, target)
			HF.AddAfflictionLimb(target, "bleeding", limb, 85, target)
			HF.AddAfflictionLimb(target, "bleedingnonstop", limb, 12, target)
			HF.AddAffliction(target, "bloodloss", 25, target)
			printBotTestResult("sangramento grave", target, limb)
		end,
		function()
			return { { "random", "arm", "leg", "leftarm", "rightarm", "leftleg", "rightleg", "torso", "head" }, DebugConsole.GetCharacterNames() }
		end,
		true
	)

	Game.AddCommand(
		"nt_bt_cardiac",
		"nt_bt_cardiac [character name]: causes a realistic cardiac arrest test state",
		function(args)
			if CLIENT and Game.IsMultiplayer then
				local characterName = args[1]
				if not characterName or characterName == "" or characterName == "/me" then
					characterName = Character.Controlled and Character.Controlled.Name or ""
				end
				Game.client.SendConsoleCommand("nt_bt_cardiac " .. '"' .. characterName .. '"')
				return
			end

			local target = findCharacter(args[1])
			if not target then return end
			HF.SetAffliction(target, "tachycardia", 0, target)
			HF.SetAffliction(target, "fibrillation", 25, target)
			HF.SetAffliction(target, "cardiacarrest", 100, target)
			HF.AddAffliction(target, "oxygenlow", 60, target)
			HF.AddAffliction(target, "hypoxemia", 45, target)
			HF.AddAffliction(target, "sym_unconsciousness", 10, target)
			print("[NT BotTest] parada cardiaca aplicada em " .. tostring(target.Name))
		end,
		function()
			return { DebugConsole.GetCharacterNames() }
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

if CLIENT and Game.IsMultiplayer then Networking.Receive("NT_debug", function(msg)
	registerDebugCommands()
end) end

registerDebugCommands()
