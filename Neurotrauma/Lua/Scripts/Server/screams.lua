-- Hooks XML Lua event "NT.causeScreams" to cause character to scream if config has enabled screaming
Hook.Add("NT.causeScreams", "NT.causeScreams", function(...)
    if not NTConfig.Get("NT_screams", true) then return end

    local character = table.pack(...)[3]
    HF.SetAffliction(character, "screaming", 10)
end)
