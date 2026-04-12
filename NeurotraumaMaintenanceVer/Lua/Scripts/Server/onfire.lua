Hook.HookMethod("Barotrauma.Character", "ApplyStatusEffects", function (instance, ptable)
    if(ptable.actionType == ActionType.OnFire) then
        local function ApplyBurn(character,limbtype)
            HF.AddAfflictionLimb(character,"onfire",limbtype,ptable.deltaTime)
        end

        if instance.IsHuman then
            ApplyBurn(instance,LimbType.Torso)
            ApplyBurn(instance,LimbType.Head)
            ApplyBurn(instance,LimbType.LeftArm)
            ApplyBurn(instance,LimbType.RightArm)
            ApplyBurn(instance,LimbType.LeftLeg)
            ApplyBurn(instance,LimbType.RightLeg)
        else 
            HF.AddAfflictionLimb(instance,"onfire",instance.AnimController.MainLimb.type,ptable.deltaTime*5)
        end
        
    end
end, Hook.HookMethodType.After)