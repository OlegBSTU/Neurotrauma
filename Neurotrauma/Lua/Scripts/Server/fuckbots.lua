LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.HumanAIController"], "SpeakAboutIssues")

-- hopefully this stops bots from doing any rescuing at all.
-- and also hopefully my assumption that this very specific thing
-- about bots is what is causing them to eat frames is correct.

if NTConfig.Get("NT_disableBotAlgorithms", true) then
	Hook.Patch("Barotrauma.AIObjectiveRescueAll", "IsValidTarget", {
		"Barotrauma.Character",
		"Barotrauma.Character",
		"out System.Boolean",
	}, function(instance, ptable)
		-- TODO: some bot behavior
		-- make it hostile act if:
		-- surgery without corresponding ailments
		-- treatment without ailments

		-- basic self treatments:
		-- find items to treat each other for blood loss or bleeding or suturable damage or fractures and dislocations
		-- ^ would possibly need items to have proper suitable treatments too, and yk bots dont spawn with enough meds...

		ptable.PreventExecution = true
		return false
	end, Hook.HookMethodType.Before)
end

-- allows npcs to talk about their neuro afflictions

Hook.Patch("Barotrauma.HumanAIController", "SpeakAboutIssues", function(instance)
	local character = instance.Character

	local message = ""

	local chatType = ChatMessageType.Default
	if ChatMessage.CanUseRadio(character) then
		chatType = ChatMessageType.Radio
	end

	local afflictions = {
		"n_fracture", -- urgent perceivable afflictions
		"h_arterialcut",
		"ll_arterialcut",
		"rl_arterialcut",
		"ra_arterialcut",
		"la_arterialcut",
		"sym_hematemesis", -- urgent causes
		"sym_paleskin",
		"sym_confusion",
		"sym_lightheadedness",
		"pain_abdominal",
		"inflammation",
		"gangrene",
		"fever",
		"sym_headache",
		"sym_blurredvision",
		"t_fracture", -- not urgent afflictions
		"h_fracture",
		"ra_fracture",
		"la_fracture",
		"rl_fracture",
		"ll_fracture",
		"dislocation1",
		"dislocation2",
		"dislocation3",
		"dislocation4",
		"pain_chest", -- not urgent causes
		"sym_weakness",
		"sym_sweating",
		"dyspnea",
		"sym_bloating",
		"sym_legswelling",
		"sym_craving",
		"sym_palpitations",
	}

	for identifier in afflictions do
		if HF.HasAffliction(character, identifier, 1) then
			message = TextManager.Get("npcdialogsym." .. identifier)
			print(message)
			character.Speak(message, chatType, math.random(0, 5), Identifier(identifier .. "DialogSym"), 600.0)
		end
	end
end, Hook.HookMethodType.After)
