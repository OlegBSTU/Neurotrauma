---@enum BloodType
--- All kinds of blood types
--- [1] - Type
--- [2] - Affliction ID
NTTypes.BloodType = {
	o_minus = "ominus",
	o_plus = "oplus",
	a_minus = "aminus",
	a_plus = "aplus",
	b_minus = "bminus",
	b_plus = "bplus",
	ab_minus = "abminus",
	ab_plus = "abplus",
}

---@enum BloodChance
--- All kinds of blood Chance
--- [1] - Type
--- [2] - Chance of appearance
NTTypes.BloodChance = {
	{ NTTypes.BloodType.o_minus, 7 },
	{ NTTypes.BloodType.o_plus, 37 },
	{ NTTypes.BloodType.a_minus, 6 },
	{ NTTypes.BloodType.a_plus, 36 },
	{ NTTypes.BloodType.b_minus, 2 },
	{ NTTypes.BloodType.b_plus, 8 },
	{ NTTypes.BloodType.ab_minus, 1 },
	{ NTTypes.BloodType.ab_plus, 3 },
}
