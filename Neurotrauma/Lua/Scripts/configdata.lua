NTConfig = { Entries = {}, Expansions = {} } -- contains all config options, their default, type, valid ranges, difficulty influence

local configDirectoryPath = Game.SaveFolder .. "/ModConfigs"
local configFilePath = configDirectoryPath .. "/Neurotrauma.json"

-- This is the function that gets used in other mods to add their own settings to the config
function NTConfig.AddConfigOptions(expansion)
	table.insert(NTConfig.Expansions, expansion)

	for key, entry in pairs(expansion.ConfigData) do
		NTConfig.Entries[key] = entry
		NTConfig.Entries[key].value = entry.default
		-- Inject the Expansion of origin into config entries 
		entry.expansion = expansion.Name
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
	NT_header1 = { 
		name = "Neurotrauma", 
		type = "category" 
	},

	NT_dislocationChance = {
		name = "Dislocation chance multiplier",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { max = 5 },
		group = true,
		resettable = true,
	},

	NT_fractureChance = {
		name = "Fracture chance multiplier",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 2, max = 5 },
		group = true,
		resettable = true,
	},

	NT_pneumothoraxChance = {
		name = "Pneumothorax chance multiplier",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { max = 5 },
		group = true,
		resettable = true,
	},

	NT_tamponadeChance = {
		name = "Tamponade chance multiplier",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { max = 3 },
		group = true,
		resettable = true,
	},

	NT_heartattackChance = {
		name = "Heart attack chance multiplier",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 1 },
		group = true,
		resettable = true,
	},

	NT_strokeChance = {
		name = "Stroke chance multiplier",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 1 },
		group = true,
		resettable = true,
	},

	NT_infectionRate = {
		name = "Infection rate multiplier",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 1.5, max = 5 },
		group = true,
		resettable = true,
	},

	NT_CPRFractureChance = {
		name = "CPR fracture chance multiplier",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 1 },
		group = true,
		resettable = true,
	},

	NT_traumaticAmputationChance = {
		name = "Traumatic amputation chance multiplier",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { max = 3 },
		group = true,
		resettable = true,
	},

	NT_neurotraumaGain = {
		name = "Neurotrauma gain rate",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 3, max = 10 },
		group = true,
		resettable = true,
	},

	NT_organDamageGain = {
		name = "Organ damage gain rate",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 2, max = 8 },
		group = true,
		resettable = true,
	},

	NT_fibrillationSpeed = {
		name = "Fibrillation gain rate",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 1.5, max = 8 },
		group = true,
		resettable = true,
	},

	NT_gangrenespeed = {
		name = "Gangrene gain rate",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 5 },
		group = true,
		resettable = true,
	},

	--NT_velocityWeight = {
	--	name = "Velocity weight",
	--	default = 1,
	--	range = { 0, 100 },
	--	type = "float",
	--	difficultyCharacteristics = { multiplier = 0.5, max = 5 },
	--	description = "How much fall velocity is allowed for sharing damage into other limbs.",
	--},

	NT_falldamageCeiling = {
		name = "Maximum fall damage multiplier",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 5 },
		group = true,
		resettable = true,
	},

	NT_falldamage = {
		name = "Falldamage multiplier",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 5 },
		group = true,
		resettable = true,
	},

	NT_falldamageSeriousInjuryChance = {
		name = "Falldamage serious injury chance multiplier",
		default = 1,
		range = { 0, 100 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 5 },
		group = true,
		resettable = true,
	},
	
	NT_Calculations = {
		name = "Character calculations",
		default = true,
		type = "bool",
		description = "Runs calculations that are necessary for the functionality of the mod. Shouldn't be disabled unless there is borderline unplayable desynchronisation and lag, in which case it might help with a bit.",
	},

	NT_vanillaSkillCheck = {
		name = "Vanilla skill check formula",
		default = false,
		type = "bool",
		description = "Changes the chance to succeed a lua skillcheck from skill/requiredskill to 100-(requiredskill-skill))/100 .",
	},

	NT_disableBotAlgorithms = {
		name = "Disable bot treatment algorithms",
		default = true,
		type = "bool",
		description = "Prevents bots from attempting to treat afflictions.\nThis is desireable, because bots suck at treating things for the current moment.",
	},

	NT_screams = { 
		name = "Screams", 
		default = true, 
		type = "bool", 
		description = "Characters scream when in pain." 
	},

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
	
	NTCRE_ConsentRequiredExtra = {
		name = "NPCs consent requirement to medical interactions",
		default = false,
		type = "bool",
		description = "Integrated consent required mod.\nIf enabled, NPCs outside of your team or submarine mission will get aggravated by medical interactions.",
	},

	NT_creatureNoFallDamage = {
		name = "Excluded creatures that abuse the fall damage mechanic",
		default = {
			"Mudraptor",
			"Mudraptor_unarmored",
			"Mudraptor_veteran",
			"Spineling_giant",
		},
		style = "SpeciesName,SpeciesName",
		type = "string",
		boxsize = 0.1,
		description = "An abuse of fall damage is commonly shown by creatures with heavy or ridicilous knockback, that at worst will instakill or stunlock you.\nYou can add or remove creatures to customize this list to your liking. Use debug command `nt_listcreatures` to list the SpeciesName of the creature you are patching in your game.\nReport other creatures that abuse fall damage to the discord server to improve this default list.",
	},

	NTSCAN_header1 = { name = "Scanner Settings", type = "category" },

	NTSCAN_enablecoloredscanner = {
		name = "Colored Scanner",
		default = true,
		type = "bool",
		description = "Enable colored health scanner text messages.",
	},

	NTSCAN_lowmedThreshold = {
		name = "Low-Medium Text Threshold",
		default = 25,
		range = { 0, 100 },
		type = "float",
		description = "Where the Low progress color ends and Medium progress color begins.",
		group = true
	},

	NT_medhighThreshold = {
		name = "Medium-High Text Threshold",
		default = 65,
		range = { 0, 100 },
		type = "float",
		description = "Where the Medium progress color ends and High progress color begins.",
		group = true
	},

	NTSCAN_basecolor = {
		name = "Base Text Color",
		default = { "100,100,200" },
		style = "R,G,B",
		type = "string",
		boxsize = 0.05,
		description = "Scanner text color.",
		noMLTB = true,
		group = true,
		resettable = true,
	},

	NTSCAN_namecolor = {
		name = "Name Text Color",
		default = { "125,125,225" },
		style = "R,G,B",
		type = "string",
		boxsize = 0.05,
		description = "Scanner text color for player names.",
		noMLTB = true,
		group = true,
		resettable = true,
	},

	NTSCAN_lowcolor = {
		name = "Low Priority Color",
		default = { "100,200,100" },
		style = "R,G,B",
		type = "string",
		boxsize = 0.05,
		description = "Scanner text color for afflictions that have low progress.",
		noMLTB = true,
		group = true,
		resettable = true,
	},

	NTSCAN_medcolor = {
		name = "Medium Priority Color",
		default = { "200,200,100" },
		style = "R,G,B",
		type = "string",
		boxsize = 0.05,
		description = "Scanner text color for afflictions that have medium progress.",
		noMLTB = true,
		group = true,
		resettable = true,
	},

	NTSCAN_highcolor = {
		name = "High Priority Color",
		default = { "250,100,100" },
		style = "R,G,B",
		type = "string",
		boxsize = 0.05,
		description = "Scanner text color for afflictions that have high progress.",
		noMLTB = true,
		group = true,
		resettable = true,
	},
	NTSCAN_vitalcolor = {
		name = "Vital Priority Color",
		default = { "255,0,0" },
		style = "R,G,B",
		type = "string",
		boxsize = 0.05,
		description = "Scanner text color for vital afflictions (Arterial bleed, Traumatic amputation).",
		noMLTB = true,
		group = true,
		resettable = true,
	},
	NTSCAN_removalcolor = {
		name = "Removed Organ Color",
		default = { "0,255,255" },
		style = "R,G,B",
		type = "string",
		boxsize = 0.05,
		description = "Scanner text color for removed organs (Heart removed, leg amputation).",
		noMLTB = true,
		group = true,
		resettable = true,
	},
	NTSCAN_customcolor = {
		name = "Custom Category Color",
		default = { "180,50,200" },
		style = "R,G,B",
		type = "string",
		boxsize = 0.05,
		description = "Scanner text color for the custom category.",
		noMLTB = true,
		group = true,
		resettable = true,
	},

	NTSCAN_VitalCategory = {
		name = "Included Vital Afflictions",
		default = {
			"cardiacarrest",
			"ll_arterialcut",
			"rl_arterialcut",
			"la_arterialcut",
			"ra_arterialcut",
			"t_arterialcut",
			"h_arterialcut",
			"tra_amputation",
			"tla_amputation",
			"trl_amputation",
			"tll_amputation",
			"th_amputation",
		},
		style = "identifier,identifier",
		type = "string",
		boxsize = 0.1,
		description = "You can add or remove afflictions to customize this list to your liking.",
	},

	NTSCAN_RemovalCategory = {
		name = "Included Removal Affictions",
		default = {
			"heartremoved",
			"brainremoved",
			"lungremoved",
			"kidneyremoved",
			"liverremoved",
			"sra_amputation",
			"sla_amputation",
			"srl_amputation",
			"sll_amputation",
			"sh_amputation",
		},
		style = "identifier, identifier",
		type = "string",
		boxsize = 0.1,
		description = "You can add or remove afflictions to customize this list to your liking.",
	},

	NTSCAN_CustomCategory = {
		name = "Custom Affliction Category",
		default = { "" },
		style = "identifier,identifier",
		type = "string",
		boxsize = 0.1,
		description = "You can add or remove afflictions to customize this list to your liking.",
	},

	NTSCAN_IgnoredCategory = {
		name = "Ignored Afflictions",
		default = { "" },
		style = "identifier,identifier",
		type = "string",
		boxsize = 0.1,
		description = "Afflictions added to this category will be ignored by the health scanner.",
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
