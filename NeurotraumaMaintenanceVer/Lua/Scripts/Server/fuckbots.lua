
-- hopefully this stops bots from doing any rescuing at all.
-- and also hopefully my assumption that this very specific thing
-- about bots is what is causing them to eat frames is correct.

if NTConfig.Get("NT_disableBotAlgorithms",true) then
    Hook.Patch("Barotrauma.AIObjectiveRescueAll", "IsValidTarget", function (instance, ptable)
        ptable.PreventExecution = true
        return false
    end, Hook.HookMethodType.Before)    
end


