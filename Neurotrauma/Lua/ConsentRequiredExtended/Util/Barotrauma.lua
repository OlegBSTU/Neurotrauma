-- Functions for interfacing with Barotrauma.

local Environment = require 'ConsentRequiredExtended.Util.Environment'
local _ENV = Environment.PrepareEnvironment(_ENV)

local Clr = require 'ConsentRequiredExtended.Util.Clr'
local UserData = require 'ConsentRequiredExtended.Util.UserData'

---Functions related to working with Barotrauma.AttackResult.
AttackResult = {}

---Initialise AttackResults.
local function Init_AttackResult()
    -- Registrations.
    UserData.RegisterStandardType("System.Reflection.FieldInfo")

    -- Construct a List<Affliction> generic type.
    local afflictionsListClrType = Clr.CreateConstructedGenericType("System.Collections.Generic.List`1",
        "Barotrauma.Affliction")
    local attackResultAfflictionsField = Clr.GetRawClrType("Barotrauma.AttackResult").GetField("Afflictions")

    ---Instantiates a new AttackResult with damage and empty afflictions.
    ---@param damage number An amount of damage.
    function AttackResult.NewAttackResultFromDamage(damage)
        -- Instantiate a new AttackResult.
        local attackResult = _G.AttackResult(damage, nil)

        -- Instantiate an empty List<Afflictions> (this is to prevent NREs),
        -- and set it to attackResult.Afflictions. This is a readonly field,
        -- hence the use of reflection.
        local afflictionsList = UserData.FromClrType({}, afflictionsListClrType)
        attackResultAfflictionsField.SetValue(attackResult, afflictionsList)

        return attackResult
    end
end

---Runs at start-up, handles registrations, etc.
function Init()
    Init_AttackResult()
end

function Test()
    local errors = {}
    local function AssertEquals(testDescription, expected, got)
        if expected ~= got then
            local errorString = string.format(
                "Test Error: %s\n\texpected = %s\n\tgot = %s",
                testDescription,
                tostring(expected),
                tostring(got)
            )
            table.insert(errors, errorString)
        end
    end
    local atkRes = AttackResult.NewAttackResultFromDamage(10)
    AssertEquals("atkRes.Damage", 10, atkRes.Damage)
    AssertEquals("atkRes.Afflictions is null", true, atkRes.Afflictions ~= nil)
    AssertEquals("#atkRes.Afflictions is non-zero", 0, #atkRes.Afflictions)

    if #errors == 0 then
        print("Tests successful")
    else
        for _, err in pairs(errors) do
            print(err)
        end
    end
end

Init()
return Environment.Export(_ENV)
