-- hopefully this stops bots from doing any rescuing at all.
-- and also hopefully my assumption that this very specific thing
-- about bots is what is causing them to eat frames is correct.

if NTConfig.Get("NT_disableBotAlgorithms", true) then
    Hook.Patch("Barotrauma.AIObjectiveRescueAll", "IsValidTarget", {
        "Barotrauma.Character",
        "Barotrauma.Character",
        "out System.Boolean"
    }, function(instance, ptable)
        -- TODO: some bot behavior
        -- make it hostile act if:
        -- surgery without corresponding ailments
        -- treatment without ailments

        -- basic self treatments:
        -- find items to treat each other for blood loss or bleeding or suturable damage or fractures and dislocations
        -- ^ would possibly need items to have proper suitable treatments too, and yk bots dont spawn with enough meds...

        ptable.PreventExecution = true
        return false
    end, Hook.HookMethodType.Before)
end
