NTConfig = { Entries = {}, Expansions = {} } -- contains all config options, their default, type, valid ranges, difficulty influence

local configDirectoryPath = Game.SaveFolder .. "/ModConfigs"
local configFilePath = configDirectoryPath .. "/Neurotrauma.json"

-- this is the function that gets used in other mods to add their own settings to the config
function NTConfig.AddConfigOptions(expansion)
	table.insert(NTConfig.Expansions, expansion)

	for key, entry in pairs(expansion.ConfigData) do
		NTConfig.Entries[key] = entry
		NTConfig.Entries[key].value = entry.default
	end
end

function NTConfig.SaveConfig()
	--prevent both owner client and server saving config at the same time and potentially erroring from file access
	if Game.IsMultiplayer and CLIENT and Game.Client.MyClient.IsOwner then
		return
	end

	local tableToSave = {}
	for key, entry in pairs(NTConfig.Entries) do
		tableToSave[key] = entry.value
	end

	File.CreateDirectory(configDirectoryPath)
	File.Write(configFilePath, json.serialize(tableToSave))
end

function NTConfig.ResetConfig()
	local tableToSave = {}
	for key, entry in pairs(NTConfig.Entries) do
		tableToSave[key] = entry.default
		NTConfig.Entries[key] = entry
		NTConfig.Entries[key].value = entry.default
	end

	-- File.CreateDirectory(configDirectoryPath)
	-- File.Write(configFilePath, json.serialize(tableToSave))
end

function NTConfig.LoadConfig()
	if not File.Exists(configFilePath) then
		return
	end

	local readConfig = json.parse(File.Read(configFilePath))

	for key, value in pairs(readConfig) do
		if NTConfig.Entries[key] then
			NTConfig.Entries[key].value = value
		end
	end
end

function NTConfig.Get(key, default)
	if NTConfig.Entries[key] then
		return NTConfig.Entries[key].value
	end
	return default
end

function NTConfig.Set(key, value)
	if NTConfig.Entries[key] then
		NTConfig.Entries[key].value = value
	end
end

function NTConfig.SendConfig(reciverClient)
	local tableToSend = {}
	for key, entry in pairs(NTConfig.Entries) do
		tableToSend[key] = entry.value
	end

	local msg = Networking.Start("NT.ConfigUpdate")
	msg.WriteString(json.serialize(tableToSend))
	if SERVER then
		Networking.Send(msg, reciverClient and reciverClient.Connection or nil)
	else
		Networking.Send(msg)
	end
end

function NTConfig.ReceiveConfig(msg)
	local RecivedTable = {}
	RecivedTable = json.parse(msg.ReadString())
	for key, value in pairs(RecivedTable) do
		NTConfig.Set(key, value)
	end
end

NT.ConfigData = {
	NT_header1 = { name = "Neurotrauma", type = "category" },

	NT_dislocationChance = {
		name = "Dislocation chance",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { max = 5 },
	},
	NT_fractureChance = {
		name = "Fracture chance",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 2, max = 5 },
	},
	NT_pneumothoraxChance = {
		name = "Pneumothorax chance",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { max = 5 },
	},
	NT_tamponadeChance = {
		name = "Tamponade chance",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { max = 3 },
	},
	NT_heartattackChance = {
		name = "Heart attack chance",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 1 },
	},
	NT_strokeChance = {
		name = "Stroke chance",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 1 },
	},
	NT_infectionRate = {
		name = "Infection rate",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 1.5, max = 5 },
	},
	NT_CPRFractureChance = {
		name = "CPR fracture chance",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 1 },
	},
	NT_traumaticAmputationChance = {
		name = "Traumatic amputation chance",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { max = 3 },
	},
	NT_neurotraumaGain = {
		name = "Neurotrauma gain",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 3, max = 10 },
	},
	NT_organDamageGain = {
		name = "Organ damage gain",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 2, max = 8 },
	},
	NT_fibrillationSpeed = {
		name = "Fibrillation rate",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 1.5, max = 8 },
	},
	NT_gangrenespeed = {
		name = "Gangrene rate",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 5 },
	},
	NT_falldamage = {
		name = "Falldamage",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 5 },
	},
	NT_falldamageSeriousInjuryChance = {
		name = "Falldamage serious injury chance",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 5 },
	},
	NT_vanillaSkillCheck = {
		name = "Vanilla skill check formula",
		default = false,
		type = "bool",
		description = "Changes the chance to succeed a lua skillcheck from skill/requiredskill to 100-(requiredskill-skill))/100",
	},
	NT_disableBotAlgorithms = {
		name = "Disable bot treatment algorithms",
		default = true,
		type = "bool",
		description = "Prevents bots from attempting to treat afflictions.\nThis is desireable, because bots suck at treating things, and their bad attempts lag out the game immensely.",
	},
	NT_screams = { name = "Screams", default = true, type = "bool", description = "Characters scream when in pain." },
	NT_ignoreModConflicts = {
		name = "Ignore mod conflicts",
		default = false,
		type = "bool",
		description = "Prevent the mod conflict affliction from showing up.",
	},
	NT_organRejection = {
		name = "Organ rejection",
		default = false,
		type = "bool",
		difficultyCharacteristics = { multiplier = 0.5 },
		description = "When transplanting an organ, there is a chance that the organ gets rejected.\nThe higher the patients immunity at the time of the transplant, the higher the chance.",
	},
	NT_fracturesRemoveCasts = {
		name = "Fractures remove casts",
		default = true,
		type = "bool",
		difficultyCharacteristics = { multiplier = 0.5 },
		description = "When receiving damage that would cause a fracture, remove plaster casts on the limb",
	},

	NTCRE_header1 = { name = "Consent Required", type = "category" },
	NTCRE_ConsentRequired = {
		name = "Enable Consent Required",
		default = true,
		type = "bool",
		description = "Integrated consent required mod.\nIf disabled, none of NPCs will get aggravated by medical interactions.",
	},
	
	NTSCAN_header1 = { name="Scanner Settings", type="category" },
	
	NTSCAN_enablecoloredscanner = {
		name = "Enable Colored Scanner",
		default = true,
		type = "bool",
		description = "Enable colored health scanner text messages.",
	},
	
	NTSCAN_lowcolor = {
		name = "Low Priority Color",
		default = "100,200,100",
		type = "string",
		description = "Scanner text color for afflictions that have less than 35 progress.",
	},
	
	NTSCAN_medcolor = {
		name = "Medium Priority Color",
		default = "200,200,100",
		type = "string",
		description = "Scanner text color for afflictions that have progress between 35 and 65.",
	},
	
	NTSCAN_highcolor = {
		name = "High Priority Color",
		default = "250,100,100",
		type = "string",
		description = "Scanner text color for afflictions that have more than 65 progress.",
	},
	NTSCAN_vitalcolor = {
		name = "Vital Priority Color",
		default = "255,0,0",
		type = "string",
		description = "Scanner text color for vital afflictions (Arterial bleed, Traumatic amputation).",
	},
	NTSCAN_removalcolor = {
		name = "Removed Organ Color",
		default = "0,255,255",
		type = "string",
		description = "Scanner text color for removed organs (Heart removed, leg amputation).",
	},
	NTSCAN_genecolor = {
		name = "Gene Color",
		default = "180,50,200",
		type = "string",
		description = "Scanner text color for genes (Husk genes, Mudraptor genes).",
	},
}
NTConfig.AddConfigOptions(NT)

-- wait a bit before loading the config so all options have had time to be added
-- do note that this unintentionally causes a couple ticks time on load during which the config is always the default
-- remember to put default values in your NTConfig.Get calls!
Timer.Wait(function()
	NTConfig.LoadConfig()

	Timer.Wait(function()
		NTConfig.SaveConfig()
	end, 1000)
end, 50)
