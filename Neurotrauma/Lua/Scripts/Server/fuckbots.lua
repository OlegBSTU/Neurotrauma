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
	if character.Inventory.GetItemInLimbSlot(InvSlotType.Headset) then
		chatType = ChatMessageType.Radio
	end

	if HF.HasAffliction(character, "sym_palpitations", 1) then
		message = "I can hear my heart beating."
		character.Speak(message, chatType, math.random(0,5), Identifier("DialogPalpitations"), 600.0)
	end

	if HF.HasAffliction(character, "inflammation", 1) then
		message = "My wound feels warm and swollen."
		character.Speak(message, chatType, math.random(0,5), Identifier("DialogueInflammation"), 120.0)
	end

end, Hook.HookMethodType.After)