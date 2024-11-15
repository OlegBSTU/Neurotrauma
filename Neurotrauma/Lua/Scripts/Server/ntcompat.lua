NTC = {} -- a class containing compatibility functions for other mods to make use of neurotraumas symptom system

-- use this function to register your expansion mod to be displayed by the
-- console lua startup readout of neurotrauma expansions

-- check surgery plus or cybernetics for an example
-- example of code for registering your expansion in init.lua:

-- MyExp = {} -- Example Expansions
-- MyExp.Name="My Expansion"
-- MyExp.Version = "A1.0"
-- MyExp.VersionNum = 01000000 -- split into two digits (01->1.; 00->0.; 00->0h; 00->0) -> 1.0.0h0
-- MyExp.MinNTVersion = "A1.7.1"
-- MyExp.MinNTVersionNum = 01070100 -- 01.07.01.00 -> A1.7.1h0
-- Timer.Wait(function() if NT ~= nil then NTC.RegisterExpansion(MyExp) end end,1)

NTC.RegisteredExpansions = {}
function NTC.RegisterExpansion(expansionMainObject)
    table.insert(NTC.RegisteredExpansions,expansionMainObject)
end

-- a table of tables, each character that has some custom data has an entry
NTC.CharacterData = {}

-- use this function to induce symptoms temporarily
-- duration is in humanupdates (~2 seconds), should at least be 2 to prevent symptom flickering
function NTC.SetSymptomTrue(character,symptomidentifer,duration)
    if duration==nil then duration=2 end

    NTC.AddEmptyCharacterData(character)
    local data = NTC.GetCharacterData(character)
    data[symptomidentifer]=duration

    NTC.CharacterData[character.ID]=data
end

-- use this function to suppress symptoms temporarily. this takes precedence over NTC.SetSymptomTrue.
-- duration is in humanupdates (~2 seconds), should at least be 2 to prevent symptom flickering
function NTC.SetSymptomFalse(character,symptomidentifer,duration)
    if duration==nil then duration=2 end

    NTC.AddEmptyCharacterData(character)
    local data = NTC.GetCharacterData(character)
    data["!"..symptomidentifer]=duration

    NTC.CharacterData[character.ID]=data
end

-- usage example: anywhere in your lua code, cause 4 seconds (2 humanupdates) of pale skin with this:
-- NTC.SetSymptomTrue(targetCharacter,"sym_paleskin",2)

-- a list of possible symptom identifiers:

-- sym_unconsciousness
-- tachycardia
-- hyperventilation
-- hypoventilation
-- dyspnea
-- sym_cough
-- sym_paleskin
-- sym_lightheadedness
-- sym_blurredvision
-- sym_confusion
-- sym_headache
-- sym_legswelling
-- sym_weakness
-- sym_wheezing
-- sym_vomiting
-- sym_nausea
-- sym_hematemesis
-- sym_fever
-- sym_abdomdiscomfort
-- sym_bloating
-- sym_jaundice
-- sym_sweating
-- sym_palpitations
-- sym_craving
-- pain_abdominal
-- pain_chest
-- lockleftarm
-- lockrightarm
-- lockleftleg
-- lockrightleg

-- with the following identifiers you can either cause things or prevent them.
-- i recommend setting the duration when using these to cause things to 1.

-- triggersym_seizure
-- triggersym_coma
-- triggersym_stroke
-- triggersym_heartattack
-- triggersym_cardiacarrest
-- triggersym_respiratoryarrest


-- prints all of the current compatibility data in the chat
-- might be useful for debugging
function NTC.DebugPrintAllData()
    local res = "neurotrauma compatibility data:\n"
    for key, value in pairs(NTC.CharacterData) do

        res=res.."\n"..value["character"].Name
        for key2,value2 in pairs(value) do
        
            res =res.."\n   "..tostring(key2).." : "..tostring(value2)
        end
    end

    PrintChat(res)
end

NTC.PreHumanUpdateHooks = {}
-- use this function to add a function to be executed before humanupdate with a character parameter
function NTC.AddPreHumanUpdateHook(func)
    NTC.PreHumanUpdateHooks[#NTC.PreHumanUpdateHooks+1] = func
end

NTC.HumanUpdateHooks = {}
-- use this function to add a function to be executed after humanupdate with a character parameter
function NTC.AddHumanUpdateHook(func)
    NTC.HumanUpdateHooks[#NTC.HumanUpdateHooks+1] = func
end

NTC.OnDamagedHooks = {}
-- use this function to add a function to be executed after ondamaged
-- with a characterhealth, attack result and limb parameter
function NTC.AddOnDamagedHook(func)
    NTC.OnDamagedHooks[#NTC.OnDamagedHooks+1] = func
end

NTC.ModifyingOnDamagedHooks = {}
-- use this function to add a function to be executed before ondamaged
-- with a characterhealth, afflictions and limb parameter, and afflictions return type
function NTC.AddModifyingOnDamagedHook(func)
    NTC.ModifyingOnDamagedHooks[#NTC.ModifyingOnDamagedHooks+1] = func
end

NTC.CharacterSpeedMultipliers = {}
-- use this function to multiply a characters speed for one human update.
-- should always be called from within a prehumanupdate hook
function NTC.MultiplySpeed(character,multiplier)
    if NTC.CharacterSpeedMultipliers[character] == nil then
        NTC.CharacterSpeedMultipliers[character] = multiplier
    else 
        NTC.CharacterSpeedMultipliers[character] = NTC.CharacterSpeedMultipliers[character]*multiplier
    end
end

-- use this function to register an affliction to be detected by the hematology analyzer
function NTC.AddHematologyAffliction(identifier)
    Timer.Wait(function()
        if not HF.TableContains(NT.HematologyDetectable,identifier) then
        table.insert(NT.HematologyDetectable,identifier) end
    end,1)
end

-- use this function to register an affliction to be healed by sutures
-- identifier: the identifier of the affliction to be healed
-- surgeryskillgain: how much surgery skill is gained by healing this affliction (optional, default: 0)
-- requiredaffliction: what affliction has to be present alongside the healed affliction for it to get healed (optional, default: none)
-- func: a function that gets run if the affliction is present. if provided, doesnt heal the affliction automatically (optional, default: none)
-- func(item, usingCharacter, targetCharacter, limb)
function NTC.AddSuturedAffliction(identifier,surgeryskillgain,requiredaffliction,func)
    Timer.Wait(function()
        if not HF.TableContains(NT.SutureAfflictions,identifier) then
            NT.SutureAfflictions[identifier] = {
                xpgain = surgeryskillgain,
                case = requiredaffliction,
                func = func
            } end
    end,1)
end

NTC.AfflictionsAffectingVitality = {
    bleeding = true,
    bleedingnonstop = true,
    burn = true,
    acidburn = true,
    lacerations = true,
    gunshotwound = true,
    bitewounds = true,
    explosiondamage = true,
    blunttrauma = true,
    internaldamage = true,
    organdamage = true,
    cerebralhypoxia = true,
    gangrene = true,
    th_amputation = true,
    sh_amputation = true,
    suturedw = true,
    alcoholaddiction = true,
    opiateaddiction = true,
}
function NTC.AddAfflictionAffectingVitality(identifier)
    NTC.AfflictionsAffectingVitality[identifier] = true
end

-- these functions are used by neurotrauma to check for symptom overrides
function NTC.GetSymptom(character,symptomidentifer)
    local chardata = NTC.GetCharacterData(character)
    if chardata == nil then return false end

    local durationleft = chardata[symptomidentifer]

    if(durationleft == nil) then return false end

    return true
end
function NTC.GetSymptomFalse(character,symptomidentifer)
    local chardata = NTC.GetCharacterData(character)
    if chardata == nil then return false end

    local durationleft = chardata["!"..symptomidentifer]

    if(durationleft == nil) then return false end

    return true
end

-- sets multiplier data for one humanupdate, should be called from within a humanupdate hook
function NTC.SetMultiplier(character,multiplieridentifier,multiplier)
    NTC.AddEmptyCharacterData(character)
    local data = NTC.GetCharacterData(character)
    data["mult_"..multiplieridentifier]=NTC.GetMultiplier(character,multiplieridentifier)*multiplier
    NTC.CharacterData[character.ID]=data
end
function NTC.GetMultiplier(character,multiplieridentifier)
    local data = NTC.GetCharacterData(character)
    if data == nil or data["mult_"..multiplieridentifier] == nil then return 1 end
    return data["mult_"..multiplieridentifier]
end

-- sets tag data for one humanupdate, should be called from within a humanupdate hook
function NTC.SetTag(character,tagidentifier)
    NTC.AddEmptyCharacterData(character)
    local data = NTC.GetCharacterData(character)
    data["tag_"..tagidentifier]=1
end
function NTC.HasTag(character,tagidentifier)
    local data = NTC.GetCharacterData(character)
    if data == nil or data["tag_"..tagidentifier] == nil then return false end
    return true
end

-- don't concern yourself with these
function NTC.AddEmptyCharacterData(character)
    if NTC.GetCharacterData(character) ~= nil then return end
    local newdat = {}
    newdat["character"] = character
    NTC.CharacterData[character.ID]=newdat
end
function NTC.CheckChardataEmpty(character)
    local chardat = NTC.GetCharacterData(character)
    if (chardat == nil or HF.TableSize(chardat) > 1) then return end

    -- remove entry from data
    NTC.CharacterData[character.ID] = nil
end
function NTC.GetCharacterData(character)
    return NTC.CharacterData[character.ID]
end
function NTC.TickCharacter(character)
    local chardata = NTC.GetCharacterData(character)
    if chardata==nil then return end

    for key,value in pairs(chardata) do
        if key ~="character" then
            if HF.StartsWith(key,"mult_") then -- multipliers
                chardata[key] = nil
                NTC.CheckChardataEmpty(character)
            else -- symptoms
                local durationleft = value
                if durationleft ~= nil and durationleft > 1 then
                    chardata[key] = durationleft-1
                else 
                    chardata[key] = nil
                    NTC.CheckChardataEmpty(character)
                end
            end
        end
    end

    NTC.CharacterData[character.ID] = chardata
end
function NTC.GetSpeedMultiplier(character)
    if NTC.CharacterSpeedMultipliers[character] ~= nil then return NTC.CharacterSpeedMultipliers[character] end
    return 1
end