local limbTypes = {
    LimbType.LeftArm,
    LimbType.RightArm,
    LimbType.LeftLeg,
    LimbType.RightLeg,
    LimbType.Torso,
    LimbType.Head
}

Timer.Wait(function()


    NTC.AddHematologyAffliction("af_calyxanide")
    NT.Afflictions.af_calyxanide = {max=100,update=function(c,i)
        if c.stats.stasis then return end

        c.afflictions[i].strength = HF.Clamp(c.afflictions[i].strength - NT.Deltatime * 0.5,0,100)

        if c.afflictions[i].strength > 0 then
            if c.afflictions.surgery_huskhealth.strength > 80 then
                -- reduce husk health
                c.afflictions.surgery_huskhealth.strength = c.afflictions.surgery_huskhealth.strength
                    - NT.Deltatime*1
            end

            -- reduce husk infection
            local prevHuskInfection = HF.GetAfflictionStrength(c.character,"huskinfection")
            local newHuskInfection = prevHuskInfection-NT.Deltatime*1

            -- 0-10%    : fully treat
            -- 10-25%   : prevent increase
            -- 25%-99%  : lower to 25%
            -- >99%     : :skull:
            if (prevHuskInfection > 25 or prevHuskInfection < 10) and prevHuskInfection < 99 then
                HF.SetAffliction(c.character,"huskinfection",newHuskInfection) end
        end
    end
    }

    NT.Afflictions.husklamp = {max=10,update=function(c,i)
        if c.afflictions[i].strength > 0.1 then

            -- increase immunity
            if not HF.HasAffliction(c.character,"afimmunosuppressant") then
                c.afflictions.immunity.strength = c.afflictions.immunity.strength+5*NT.Deltatime end

            -- heal lungs
            if c.afflictions.lungdamage.strength<99 then
                c.afflictions.lungdamage.strength = c.afflictions.lungdamage.strength - 0.04*NT.Deltatime end

            -- limb specifics
            for limbType in limbTypes do

                if HF.GetAfflictionStrengthLimb(c.character,limbType,"ointmented") < 10 then
                    HF.AddAfflictionLimb(c.character,"ointmented",limbType,2 * NT.Deltatime) end
                if HF.GetAfflictionStrengthLimb(c.character,limbType,"burn") < 50 then
                    HF.AddAfflictionLimb(c.character,"burn",limbType,-0.2 * NT.Deltatime) end
            
            end
            
        end
    end
    }

    NT.Afflictions.surgery_huskhealth = {max=100,update=function(c,i)
        if c.stats.stasis then c.afflictions[i].strength=0 return end
        if not NTS.HF.HasHusk(c.character) then c.afflictions[i].strength=0 return end
        if not HF.HasAffliction(c.character,"bonecuttorso",99) then c.afflictions[i].strength=0 return end

        -- husk parasite health regeneration
        if c.afflictions.af_calyxanide.strength <= 0.1 and c.afflictions[i].strength>0.1 then
            c.afflictions[i].strength = HF.Clamp(c.afflictions[i].strength
            + NT.Deltatime * 0.5
            ,0,100)
        end
        
    end
    }

    NT.Afflictions.bonecuttorso = {max=100,update=function(c,i)
        if c.stats.stasis then c.afflictions[i].strength=0 return end

        -- husk parasite health instantiation
        if c.afflictions[i].strength >= 99 and c.afflictions.surgery_huskhealth.strength <= 0.1 and NTS.HF.HasHusk(c.character) then
            HF.GiveItem(c.character,"ntsfx_huskhurt")
            c.afflictions.surgery_huskhealth.strength = HF.Clamp(100-c.afflictions.af_calyxanide.strength,80,100)
        end
    end
    }

    -- making symbiosis treat neurotrauma stuff
    NT.Afflictions.husksymbiosis = {max=100,update=function(c,i)
        if c.stats.stasis then return end
        if c.afflictions[i].strength<1 then return end

        -- treat stuff
        c.afflictions.sepsis.strength=0
        c.afflictions.hemotransfusionshock.strength=0
        c.afflictions.pneumothorax.strength=0
        c.afflictions.internalbleeding.strength= c.afflictions.internalbleeding.strength-0.5 * NT.Deltatime
        c.afflictions.acidosis.strength= c.afflictions.acidosis.strength-0.2 * NT.Deltatime
        c.afflictions.alkalosis.strength= c.afflictions.alkalosis.strength-0.2 * NT.Deltatime
        c.afflictions.lungdamage.strength= c.afflictions.lungdamage.strength-0.05 * NT.Deltatime
        c.afflictions.oxygenlow.strength= c.afflictions.oxygenlow.strength-100 * NT.Deltatime
        NTC.SetSymptomFalse(c.character,"hyperventilation",2)
        NTC.SetSymptomFalse(c.character,"hypoventilation",2)
        c.afflictions.respiratoryarrest.strength=0
        NTC.SetSymptomFalse(c.character,"dyspnea",2)
            
        -- limb specifics
        for limbType in limbTypes do
            if HF.GetAfflictionStrengthLimb(c.character,limbType,"gangrene")<15 then
                HF.AddAfflictionLimb(c.character,"gangrene",limbType,-0.1 * NT.Deltatime) end
        end

        -- wait a tick with this because otherwise it'll be removed before being used
        Timer.Wait(function() NTC.SetMultiplier(c.character,"hypoxemiagain",0.1) end,1)

        -- symbiotic stasis
        local shouldBeInStasis = 
            c.afflictions.cardiacarrest.strength > 0.1
            or c.afflictions.cerebralhypoxia.strength > 102
            or c.afflictions.coma.strength > 20
            or c.character.Vitality < 0
            or c.character.bloodloss > 80

        if shouldBeInStasis then
            c.afflictions.huskstasis.strength = 10
        end

    end}

    NT.Afflictions.huskstasis = {max=10,update=function(c,i)
        if c.stats.stasis then return end
        if c.afflictions[i].strength<1 then return end

        -- treat stuff
        c.afflictions.internalbleeding.strength= c.afflictions.internalbleeding.strength-5 * NT.Deltatime
        c.afflictions.coma.strength= c.afflictions.coma.strength-10 * NT.Deltatime
        c.afflictions.tamponade.strength= c.afflictions.tamponade.strength-5 * NT.Deltatime
        c.afflictions.bonedamage.strength= c.afflictions.bonedamage.strength-5 * NT.Deltatime
        c.afflictions.traumaticshock.strength= c.afflictions.traumaticshock.strength-5 * NT.Deltatime
        HF.SetAffliction(c.character,"cpr_buff_auto",2)
            
        -- heal organs
        if c.afflictions.heartdamage.strength<99 then
        c.afflictions.heartdamage.strength= c.afflictions.heartdamage.strength-0.5 * NT.Deltatime end
        if c.afflictions.lungdamage.strength<99 then
        c.afflictions.lungdamage.strength= c.afflictions.lungdamage.strength-0.5 * NT.Deltatime end
        if c.afflictions.liverdamage.strength<99 then
        c.afflictions.liverdamage.strength= c.afflictions.liverdamage.strength-0.5 * NT.Deltatime end
        if c.afflictions.kidneydamage.strength<50 then
        c.afflictions.kidneydamage.strength= c.afflictions.kidneydamage.strength-0.5 * NT.Deltatime
        elseif c.afflictions.kidneydamage.strength<99 then
            c.afflictions.kidneydamage.strength= HF.Clamp(c.afflictions.kidneydamage.strength-0.5 * NT.Deltatime,51,100)
        end

        -- do some good
        if c.afflictions.analgesia.strength<40 then
            c.afflictions.analgesia.strength= c.afflictions.analgesia.strength-5 * NT.Deltatime end
        if c.afflictions.seizure.strength < 5 then
            NTC.SetSymptomTrue(c.character,"triggersym_seizure",2) end

        -- limb specifics
        for limbType in limbTypes do
            -- arterial bleeds
            NT.ArteryCutLimb(c.character,limbType,-10*NT.Deltatime)
            -- fractures
            if HF.Chance(0.05) then
                NT.BreakLimb(c.character,limbType,-1000)
            end
            -- foreign bodies
            HF.AddAfflictionLimb(c.character,"foreignbody",limbType,-1 * NT.Deltatime)

        end

        c.afflictions[i].strength = c.afflictions[i].strength-1*NT.Deltatime
        NTC.SetSymptomTrue(c.character,"sym_unconsciousness",2)
    end}

    
    function NTS.UpdateHuman(character)

        -- check if wearing husk robes
        if HF.GetInnerWearIdentifier(character) == "zealotrobes" and NTS.HF.HasHusk(character) then
            -- heal shit
            HF.SetAffliction(character,"sepsis",0)
            HF.SetAffliction(character,"hemotransfusionshock",0)
            HF.SetAffliction(character,"pneumothorax",0)
            HF.AddAffliction(character,"internalbleeding",-0.5 * NT.Deltatime)
            HF.AddAffliction(character,"acidosis",-0.2 * NT.Deltatime)
            HF.AddAffliction(character,"alkalosis",-0.2 * NT.Deltatime)
            HF.AddAffliction(character,"lungdamage",-0.05 * NT.Deltatime)
            HF.AddAffliction(character,"oxygenlow",-100 * NT.Deltatime)
            NTC.SetSymptomFalse(character,"hyperventilation",2)
            NTC.SetSymptomFalse(character,"hypoventilation",2)
            
            -- limb specifics
            for limbType in limbTypes do
                if HF.GetAfflictionStrengthLimb(character,limbType,"gangrene")<15 then
                    HF.AddAfflictionLimb(character,"gangrene",limbType,-0.1 * NT.Deltatime) end
            end
        end

    end
    NTC.AddHumanUpdateHook(NTS.UpdateHuman)

end,1)