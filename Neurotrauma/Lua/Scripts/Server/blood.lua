-- Neurotrauma blood types functions
-- Hooks Lua event "characterCreated" to create a randomized blood type for spawned character and sets their immunity to 100
---@diagnostic disable: lowercase-global, undefined-global
NT.BLOODTYPE = { -- blood types and chance in percent
    {"ominus",7},
    {"oplus",37},
    {"aminus",6},
    {"aplus",36},
    {"bminus",2},
    {"bplus",8},
    {"abminus",1},
    {"abplus",3}}
NT.setBlood = {}
NT.foundAny = false

-- Insert all blood types in one table for RandomizeBlood()
for index, value in ipairs(NT.BLOODTYPE) do
    -- print(index," : ",value[1],", ",value[2],"%")
    table.insert(NT.setBlood,index, {value[2],value[1]})
end

-- Applies math.random() blood type.
-- returns the applied bloodtype as an affliction identifier
function NT.RandomizeBlood(character)
    rand = math.random(0,99)
    local i = 0
    for index, value in ipairs(NT.setBlood) do
        i = i + value[1]
        if (i > rand) then
            HF.SetAffliction(character, value[2], 100)
            return value[2]
        end
    end
end

Hook.Add("characterCreated", "NT.BloodAndImmunity", function(createdCharacter)
    Timer.Wait(function()
        if (createdCharacter.IsHuman and not createdCharacter.IsDead) then
            
            NT.TryRandomizeBlood(createdCharacter)

            -- add immunity
            local conditional2 = createdCharacter.CharacterHealth.GetAffliction("immunity")
            if (conditional2 == nil) then
                HF.SetAffliction(createdCharacter,"immunity",100)
            end
        end
    end, 1000)
end)

-- applies a new bloodtype only if the character doesnt already have one
function NT.TryRandomizeBlood(character)
    NT.GetBloodtype(character)
end

-- returns the bloodtype of the character as an affliction identifier string
-- generates blood type if none present
function NT.GetBloodtype(character)
    for index, affliction in ipairs(NT.BLOODTYPE) do
        local conditional = character.CharacterHealth.GetAffliction(affliction[1])

        if (conditional ~= nil and conditional.Strength > 0) then
            return affliction[1] -- TODO: give out abplus (AB+) to enemy team for blood infusions
        end
    end

    return NT.RandomizeBlood(character)
end

function NT.HasBloodtype(character)
    for index, affliction in ipairs(NT.BLOODTYPE) do
        local conditional = character.CharacterHealth.GetAffliction(affliction[1])

        if (conditional ~= nil and conditional.Strength > 0) then
            return true
        end
    end

    return false
end

Hook.Add("OnInsertedIntoBloodAnalyzer", "NT.BloodAnalyzer", function(effect, deltaTime, item, targets, position)
    -- Hematology Analyzer (bloodanalyzer) can scan inserted blood bags
    if item.ParentInventory == nil or item.ParentInventory.Owner == nil or not item.ParentInventory.Owner.IsPlayer then
        return
    end
    local character = item.ParentInventory.Owner
    local contained = item.OwnInventory.GetItemAt(0)

    -- NT adds bloodbag; NT Blood Work or 'Real Sonar Medical Item Recipes Patch for Neurotrauma' add allblood, lets check for either
    if contained ~= nil and (contained.HasTag("bloodbag") or contained.HasTag("allblood")) then
        HF.GiveItem(character,"ntsfx_syringe")
        Timer.Wait(function()
            if item == nil or character == nil or item.OwnInventory.GetItemAt(0) ~= contained then
                return
            end

            local identifier = contained.Prefab.Identifier.Value
            local packtype = "o-"
            if identifier ~= "antibloodloss2" then
                packtype = string.sub(identifier, string.len("bloodpack")+1)
            end
            local bloodTypeDisplay = string.gsub(packtype, "abc", "c")
            bloodTypeDisplay = string.gsub(bloodTypeDisplay, "plus", "+")
            bloodTypeDisplay = string.gsub(bloodTypeDisplay, "minus", "-")
            bloodTypeDisplay = string.upper(bloodTypeDisplay)

            local readoutString = "Bloodpack: " .. bloodTypeDisplay
            -- check if acidosis, alkalosis or sepsis
            local tags = HF.SplitString(contained.Tags,",")
            for tag in tags do
                if tag == "sepsis" then
                    readoutString = readoutString .. "\nSepsis detected"
                end

                if HF.StartsWith(tag,"acid") then
                    local split = HF.SplitString(tag,":")
                    if split[2] ~= nil then
                        readoutString = readoutString .. "\nAcidosis: " .. tonumber(split[2]) .. "%"
                    end
                elseif HF.StartsWith(tag,"alkal") then
                    local split = HF.SplitString(tag,":")
                    if split[2] ~= nil then
                        readoutString = readoutString .. "\nAlkalosis: " .. tonumber(split[2]) .. "%"
                    end
                end
            end

            HF.DMClient(HF.CharacterToClient(character), readoutString, Color(127,255,255,255))
        end, 1500)
    end
end)
