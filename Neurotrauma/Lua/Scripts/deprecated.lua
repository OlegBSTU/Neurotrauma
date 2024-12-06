---blood types and chance in percent
---@deprecated Use the NTTypes.BloodType enumeration instead
NT.BLOODTYPE = {
    { "ominus",  7 },
    { "oplus",   37 },
    { "aminus",  6 },
    { "aplus",   36 },
    { "bminus",  2 },
    { "bplus",   8 },
    { "abminus", 1 },
    { "abplus",  3 }
}

--- applies a new bloodtype only if the character doesnt already have one
---@deprecated Use the NT.GetBloodtype(character)
function NT.TryRandomizeBlood(character)
    NT.GetBloodtype(character)
end
