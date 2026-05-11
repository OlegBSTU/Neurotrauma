
local convertedDamageTypes = {"bleeding","blunttrauma","lacerations","burn","gunshotwound","bitewounds","explosiondamage","internaldamage","foreignbody"}

local damageTypeSFXDict = {}
damageTypeSFXDict["blunttrauma"]     = "ntcsfx_cyberblunt"
damageTypeSFXDict["lacerations"]     = "ntcsfx_cyberblunt"
damageTypeSFXDict["burn"]            = "ntcsfx_welding"
damageTypeSFXDict["gunshotwound"]    = "ntcsfx_cyberblunt"
damageTypeSFXDict["bitewounds"]      = "ntcsfx_cyberbite"
damageTypeSFXDict["explosiondamage"] = "ntcsfx_cyberblunt"
damageTypeSFXDict["internaldamage"]  = "ntcsfx_cyberblunt"
damageTypeSFXDict["foreignbody"]     = "ntcsfx_cyberblunt"

Timer.Wait(function() 
NTC.AddOnDamagedHook(function (characterHealth, attackResult, hitLimb)
    
    -- automatically convert damage types
    local targetChar = characterHealth.Character
    local causeDamageTypeConversion = false
    local identifier = ""
    local sfxidentifier = nil

    for index, value in ipairs(attackResult.Afflictions) do
        if value.Strength > 1 then 
            identifier = value.Prefab.Identifier.Value

            if HF.TableContains(convertedDamageTypes,identifier) then
                causeDamageTypeConversion = true 
                if damageTypeSFXDict[identifier] ~= nil then sfxidentifier = damageTypeSFXDict[identifier] end
            end
        end
    end

    if causeDamageTypeConversion and NTCyb.HF.LimbIsCyber(targetChar,hitLimb.type) then
        if sfxidentifier ~= nil then HF.GiveItem(targetChar,sfxidentifier) end
        Timer.Wait(function() NTCyb.ConvertDamageTypes(targetChar,hitLimb.type) end,1)
    end
end)

local oldDislocateLimb = NT.DislocateLimb
NT.DislocateLimb = function(character,limbtype,strength)
    strength = strength or 1
    if strength > 0 and NTCyb.HF.LimbIsCyber(character,limbtype) then return end
    oldDislocateLimb(character,limbtype,strength)
end

local oldBreakLimb = NT.BreakLimb
NT.BreakLimb = function(character,limbtype,strength)
    strength = strength or 5
    if strength > 0 and NTCyb.HF.LimbIsCyber(character,limbtype) then return end
    oldBreakLimb(character,limbtype,strength)
end

local oldArteryCutLimb = NT.ArteryCutLimb
NT.ArteryCutLimb = function(character,limbtype,strength)
    strength=strength or 5
    if strength > 0 and NTCyb.HF.LimbIsCyber(character,limbtype) then return end
    oldArteryCutLimb(character,limbtype,strength)
end

end,1)
