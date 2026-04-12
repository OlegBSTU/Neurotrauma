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
            return affliction[1]
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