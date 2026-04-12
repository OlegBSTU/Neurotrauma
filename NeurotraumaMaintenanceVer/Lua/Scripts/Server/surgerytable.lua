
-- lifted and translated from betterhealthui
local NormalHeartrate = 60
local MaxTachycardiaHeartrate = 180;
local MaxFibrillationHeartrate = 300;
local function GetHeartrate(character)

    if (character == nil or character.CharacterHealth==nil or character.IsDead) then return 0 end

    local rate = NormalHeartrate

    local cardiacarrest = character.CharacterHealth.GetAffliction("cardiacarrest")

    -- return 0 rate if in cardiac arrest
    if (cardiacarrest ~= nil and cardiacarrest.Strength >= 0.5) then return 0 end

    local tachycardia = character.CharacterHealth.GetAffliction("tachycardia")
    local fibrillation = character.CharacterHealth.GetAffliction("fibrillation")

    if (fibrillation~=nil) then
        rate = HF.Lerp(MaxTachycardiaHeartrate, MaxFibrillationHeartrate, fibrillation.Strength/100 * (1+math.random()*0.5))
    elseif (tachycardia ~= nil) then
        rate = HF.Lerp(NormalHeartrate, MaxTachycardiaHeartrate, tachycardia.Strength / 100)
    end

    return rate
end

local function GetPH(character)

    if (character == nil or character.CharacterHealth==nil) then return 0 end

    local acidosis = HF.GetAfflictionStrength(character,"acidosis",0)
    local alkalosis = HF.GetAfflictionStrength(character,"alkalosis",0)

    return alkalosis-acidosis
end

Hook.Add("surgerytable.update", "surgerytable.update", function (effect, deltaTime, item, targets, worldPosition)

    -- fetch controller component
    local controllerComponent = item.GetComponentString("Controller")
    if controllerComponent == nil then item.SendSignal("0","state_out") return end
    
    -- check if targets present
    -- laying on the table
    local target = controllerComponent.User
    -- noone one the table? check the targets array for the one with the least vitality
    if target == nil or not target.IsHuman then
        local minVitality = 999
        for index, value in ipairs(targets) do
            if value.Name ~= nil and value.IsHuman and (value.Vitality < minVitality) then
                minVitality = value.Vitality
                target = value
            end
        end
    end
    -- no target found
    if target == nil or not target.IsHuman then item.SendSignal("0","state_out") return end

    -- send signals
    item.SendSignal("1","state_out")
    if target.IsDead then item.SendSignal("0","alive_out") else item.SendSignal("1","alive_out") end
    if target.IsDead or HF.HasAffliction(target,"sym_unconsciousness",0.1) then item.SendSignal("0","conscious_out") else item.SendSignal("1","conscious_out") end
    item.SendSignal(target.Name,"name_out")
    item.SendSignal(tostring(HF.Round(target.Vitality)),"vitality_out")
    if target.IsDead then item.SendSignal("0","bloodpressure_out")
    else item.SendSignal(tostring(HF.Round(HF.GetAfflictionStrength(target,"bloodpressure",100))),"bloodpressure_out") end
    item.SendSignal(tostring(HF.Round(100-HF.GetAfflictionStrength(target,"hypoxemia",0))),"bloodoxygen_out")
    item.SendSignal(tostring(HF.Round(HF.GetAfflictionStrength(target,"cerebralhypoxia",0))),"neurotrauma_out")
    item.SendSignal(tostring(HF.Round(HF.GetAfflictionStrength(target,"organdamage",0))),"organdamage_out")
    
    local heartrate = HF.Round(GetHeartrate(target))
    item.SendSignal(tostring(heartrate),"heartrate_out")

    local breathingrate = math.random(15,18)
    if HF.HasAffliction(target,"respiratoryarrest") or target.IsDead then breathingrate=0 
    elseif HF.HasAffliction(target,"hyperventilation") then breathingrate=breathingrate+math.random(6,8)
    elseif HF.HasAffliction(target,"hypoventilation") then breathingrate=breathingrate-math.random(6,8) end
    item.SendSignal(tostring(breathingrate),"breathingrate_out")

    item.SendSignal(tostring(HF.BoolToNum(HF.HasAffliction(target,"surgeryincision"),1)),"insurgery_out")

    if 
    target.IsDead and
    target.causeOfDeath~=nil 
    then
        item.SendSignal(HF.CauseOfDeathToString(target.causeOfDeath),"causeofdeath_out")
    end

    local bloodph = HF.Round(GetPH(target))
    item.SendSignal(tostring(bloodph),"bloodph_out")

end)

--Hook.Add("surgerytable.forceon", "surgerytable.forceon", function (effect, deltaTime, item, targets, worldPosition)
--    -- fetch controller component
--    local controllerComponent = item.GetComponentString("Controller")
--    if controllerComponent == nil or controllerComponent.IsActive then return end
--
--    -- check if targets present
--    if targets == nil or #targets <= 0 then return end
--    local target = nil
--    for index, value in ipairs(targets) do
--        target=value
--        if target ~=nil then break end
--    end
--    if target == nil then return end
--
--    -- was experimenting with forcing the patient into laying down here, sort of worked... until 0 vitality.
--    -- it's too janky to be released.
--    
--    -- target.Stun = 0
--    -- HF.SetAffliction(target,"givein",0)
--    -- controllerComponent.Select(target)
--    -- target.SelectedConstruction = item
--end)