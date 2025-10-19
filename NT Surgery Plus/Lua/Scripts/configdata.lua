NTSP.ConfigData = {
	NTSP_header1 = { name = NTSP.Name, type = "category" },

	NTSP_enableSurgicalInfection = {
		name = "surgical infection",
		default = true,
		type = "bool",
		difficultyCharacteristics = { multiplier = 0.5 },
	},
	NTSP_enableSurgerySkill = { name = "surgery skill", default = true, type = "bool" },
	NT_beepboop = {
		name = "fractures remove casts!",
		default = true,
		type = "bool",
		difficultyCharacteristics = { multiplier = 0.5 },
		description = "when receiving damage that would cause a fracture, remove plaster casts on the limb",
	},
}
NTConfig.AddConfigOptions(NTSP)
