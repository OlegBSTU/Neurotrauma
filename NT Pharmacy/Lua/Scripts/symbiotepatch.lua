NTP.PillData.items.calyxanide = {
	types = { "active" },
	skillrequirement = 38,
	effects = {
		--{ type = "addeffect", identifier = "huskinfection", amount = -50 },
		{ type = "addeffect", identifier = "af_calyxanide", amount = 50 },
	},
	faileffects = {
		--{ type = "addeffect", identifier = "huskinfection", amount = -30 },
		{ type = "addeffect", identifier = "af_calyxanide", amount = 50 },
	},
}

NTP.PillData.combos.antihusk = {
	requireditems = { { id = "antibiotics" }, { id = "calyxanide" } },
	forbiddenitems = {},
	coloroverride = { 22, 204, 143 },
	descriptionoverride = "antihusk",
	effectoverride = {
		skillrequirement = 30,
		effects = {
			--{type="addeffect",identifier="huskinfection",amount=-70},
			{ type = "addeffect", identifier = "af_calyxanide", amount = 100 },
			{ type = "addeffect", identifier = "huskinfectionresistance", amount = 500 },
		},
		faileffects = {
			--{type="addeffect",identifier="huskinfection",amount=-40},
			{ type = "addeffect", identifier = "af_calyxanide", amount = 100 },
			{ type = "addeffect", identifier = "huskinfectionresistance", amount = 300 },
		},
	},
}
