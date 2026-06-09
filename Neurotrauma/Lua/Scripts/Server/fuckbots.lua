LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.HumanAIController"], "SpeakAboutIssues")

-- The original Neurotrauma build disabled bot rescue/treatment objectives here.
-- This modified build keeps vanilla bot rescue/treatment objectives enabled.
-- Lua/Scripts/Server/botfirstaid.lua only teaches vanilla AI which Neurotrauma
-- first-aid items fit which afflictions; it does not run a custom triage AI.
NTConfig.Set("NT_disableBotAlgorithms", false)

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
	"pain_chest", -- not urgent causes
	"sym_weakness",
	"sym_sweating",
	"dyspnea",
	"sym_bloating",
	"sym_legswelling",
	"sym_craving",
	"sym_palpitations",
}
NT.SymsForNPC = { ntaffs = afflictions }

-- How to add own symptoms example:
--local goobertable = { "goober", "gooberer" }
--table.insert(NT.SymsForNPC, goobertable)

-- allows npcs to talk about their neuro afflictions

Hook.Patch("Barotrauma.HumanAIController", "SpeakAboutIssues", function(instance)
	local character = instance.Character

	if not HF.HasAffliction(character, "luabotomy", 1) then return end

	local message = ""
	local chatType = ChatMessageType.Default

	if ChatMessage.CanUseRadio(character) then chatType = ChatMessageType.Radio end

	for identifier in NT.SymsForNPC.ntaffs do
		if HF.HasAffliction(character, identifier, 1) then
			message = TextManager.Get("npcdialogsym." .. identifier)
			character.Speak(message, chatType, math.random(0, 5), Identifier(identifier .. "DialogSym"), 600.0)
			break
		end
	end

	-- Extra symptom tables can be registered by other modules. Skip the built-in
	-- table here because it was already handled above.
	for key, table in pairs(NT.SymsForNPC) do
		if key ~= "ntaffs" then
			for identifier in table do
				if HF.HasAffliction(character, identifier, 1) then
					message = TextManager.Get("npcdialogsym." .. identifier)
					character.Speak(message, chatType, math.random(0, 5), Identifier(identifier .. "DialogSym"), 600.0)
					break
				end
			end
		end
	end
end, Hook.HookMethodType.After)
