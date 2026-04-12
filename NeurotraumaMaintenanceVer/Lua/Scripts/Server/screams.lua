Hook.Add("NT.causeScreams", "NT.causeScreams", function(...)
    if not NTConfig.Get("NT_screams",true) then return end

    local character = table.pack(...)[3]
    HF.SetAffliction(character,"screaming",10)
end)