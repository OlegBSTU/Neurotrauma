
-- This file contains a bunch of useful functions that see heavy use in the other scripts.
NTCyb.HF = {} -- Helperfunctions

function NTCyb.HF.LimbIsCyber(character,limbtype) 
    return HF.HasAfflictionLimb(character,"ntc_cyberlimb",HF.NormalizeLimbType(limbtype),0.1)
end

function NTCyb.UncyberifyLimb(character,limbtype)

    limbtype = HF.NormalizeLimbType(limbtype)

    HF.SetAfflictionLimb(character,"ntc_cyberlimb",limbtype,0)
    HF.SetAfflictionLimb(character,"ntc_cyberarm",limbtype,0)
    HF.SetAfflictionLimb(character,"ntc_cyberleg",limbtype,0)
    HF.SetAfflictionLimb(character,"ntc_legspeed",limbtype,0)
    HF.SetAfflictionLimb(character,"ntc_armspeed",limbtype,0)
    HF.SetAfflictionLimb(character,"ntc_waterproof",limbtype,0)
    HF.SetAfflictionLimb(character,"ntc_loosescrews",limbtype,0)
    HF.SetAfflictionLimb(character,"ntc_damagedelectronics",limbtype,0)
    HF.SetAfflictionLimb(character,"ntc_bentmetal",limbtype,0)
    HF.SetAfflictionLimb(character,"ntc_materialloss",limbtype,0)

    if limbtype == LimbType.RightArm then HF.SetAffliction(character,"ra_cyber",0)
    elseif limbtype == LimbType.LeftArm then HF.SetAffliction(character,"la_cyber",0)
    elseif limbtype == LimbType.RightLeg then HF.SetAffliction(character,"rl_cyber",0)
    elseif limbtype == LimbType.LeftLeg then HF.SetAffliction(character,"ll_cyber",0) end
end

function NTCyb.CyberifyLimb(character,limbtype,iswaterproof)
    
    if limbtype == LimbType.RightArm then 
        HF.SetAffliction(character,"ra_cyber",100)
        HF.SetAfflictionLimb(character,"ntc_cyberarm",limbtype,100)
        HF.SetAfflictionLimb(character,"ntc_armspeed",limbtype,100)
        if iswaterproof == true then
            HF.SetAfflictionLimb(character,"ntc_waterproof",limbtype,100)
        end
    elseif limbtype == LimbType.LeftArm then 
        HF.SetAffliction(character,"la_cyber",100)
        HF.SetAfflictionLimb(character,"ntc_cyberarm",limbtype,100)
        HF.SetAfflictionLimb(character,"ntc_armspeed",limbtype,100)
        if iswaterproof == true then
            HF.SetAfflictionLimb(character,"ntc_waterproof",limbtype,100)
        end
    elseif limbtype == LimbType.RightLeg then 
        HF.SetAffliction(character,"rl_cyber",100)
        HF.SetAfflictionLimb(character,"ntc_cyberleg",limbtype,100)
        HF.SetAfflictionLimb(character,"ntc_legspeed",limbtype,100)
        if iswaterproof == true then
            HF.SetAfflictionLimb(character,"ntc_waterproof",limbtype,100)
        end
    elseif limbtype == LimbType.LeftLeg then 
        HF.SetAffliction(character,"ll_cyber",100) 
        HF.SetAfflictionLimb(character,"ntc_cyberleg",limbtype,100)
        HF.SetAfflictionLimb(character,"ntc_legspeed",limbtype,100)
        if iswaterproof == true then
            HF.SetAfflictionLimb(character,"ntc_waterproof",limbtype,100)
        end
    end

    -- get rid of all the flesh-only stuff
    
    NT.ArteryCutLimb(character,limbtype,-1000)
    NT.BreakLimb(character,limbtype,-1000)
    NT.DislocateLimb(character,limbtype,-1000)
    NT.SurgicallyAmputateLimb(character,limbtype,0,0)

    HF.SetAfflictionLimb(character,"arteriesclamp",limbtype,0)
    HF.SetAfflictionLimb(character,"surgeryincision",limbtype,0)
    HF.SetAfflictionLimb(character,"clampedbleeders",limbtype,0)
    HF.SetAfflictionLimb(character,"drilledbones",limbtype,0)
    HF.SetAfflictionLimb(character,"retractedskin",limbtype,0)
    HF.SetAfflictionLimb(character,"suturedi",limbtype,0)
    HF.SetAfflictionLimb(character,"suturedw",limbtype,0)

    HF.SetAfflictionLimb(character,"internaldamage",limbtype,0)
    HF.SetAfflictionLimb(character,"burn",limbtype,0)
    HF.SetAfflictionLimb(character,"gunshotwound",limbtype,0)
    HF.SetAfflictionLimb(character,"bitewounds",limbtype,0)
    HF.SetAfflictionLimb(character,"explosiondamage",limbtype,0)
    HF.SetAfflictionLimb(character,"bleeding",limbtype,0)
    HF.SetAfflictionLimb(character,"lacerations",limbtype,0)
    HF.SetAfflictionLimb(character,"blunttrauma",limbtype,0)

    HF.SetAfflictionLimb(character,"bonecut",limbtype,0)

    -- do the thing

    HF.SetAfflictionLimb(character,"ntc_cyberlimb",limbtype,100)
end