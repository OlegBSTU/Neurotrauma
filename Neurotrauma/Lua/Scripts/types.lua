--- Types of data in neurotrauma
NTTypes = {}

---@enum BloodType
--- All kinds of blood types
NTTypes.BloodType = {
    o_minus = "ominus",
    o_plus = "oplus",
    a_minus = "aminus",
    a_plus = "aplus",
    b_minus = "bminus",
    b_plus = "bplus",
    ab_minus = "abminus",
    ab_plus = "abplus"
}

---@enum BloodChance
--- All kinds of blood Chance
NTTypes.BloodChance = {
    { NTTypes.BloodType.o_minus,  7 },
    { NTTypes.BloodType.o_plus,   37 },
    { NTTypes.BloodType.a_minus,  6 },
    { NTTypes.BloodType.a_plus,   36 },
    { NTTypes.BloodType.b_minus,  2 },
    { NTTypes.BloodType.b_plus,   8 },
    { NTTypes.BloodType.ab_minus, 1 },
    { NTTypes.BloodType.ab_plus,  3 }
}

---@enum LimbTypes
--- All types of limbs
--- [1] - Type
--- [2] - String representation
NTTypes.LimbTypes = {
    { LimbType.Torso,    "Torso" },
    { LimbType.Head,     "Head" },
    { LimbType.LeftArm,  "Left Arm" },
    { LimbType.RightArm, "Right Arm" },
    { LimbType.LeftLeg,  "Left Leg" },
    { LimbType.RightLeg, "Right Leg" }
}
