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
    ab_plus = "abplus",
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
