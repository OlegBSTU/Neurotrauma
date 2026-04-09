
NTP.PillData = {}
NTP.PillData.items = {
    -- /// bases ///
    alienblood={types={"base"},skillrequirement=60,
        effects={
            {type="capacity",value=3},
            {type="potencymult",value=1.2},
            {type="addeffect",identifier="psychosis",amount=5}},
        faileffects={
            {type="capacity",value=3},
            {type="potencymult",value=0.8},
            {type="addeffect",identifier="psychosis",amount=10}}
    },
    antibloodloss1={weight=0.5,types={"base"},skillrequirement=10,
        effects={
            {type="capacity",value=1},
            {type="potencymult",value=0.9}},
        faileffects={
            {type="capacity",value=1},
            {type="potencymult",value=0.7}}
    },
    ringerssolution={variantof="antibloodloss1"},
    antibloodloss2={weight=0.3,types={"base"},skillrequirement=40,
        effects={
            {type="capacity",value=2},
            {type="potencymult",value=1.1}},
        faileffects={
            {type="capacity",value=2},
            {type="potencymult",value=0.9}}
    },
    bloodpackominus={variantof="antibloodloss2"},
    bloodpackoplus={variantof="antibloodloss2"},
    bloodpackaminus={variantof="antibloodloss2"},
    bloodpackaplus={variantof="antibloodloss2"},
    bloodpackbminus={variantof="antibloodloss2"},
    bloodpackbplus={variantof="antibloodloss2"},
    bloodpackabminus={variantof="antibloodloss2"},
    bloodpackabplus={variantof="antibloodloss2"},

    -- /// binders ///
    ethanol={types={"binder"},weight=2,skillrequirement=20,
        effects={},
        faileffects={
            {type="addeffect",identifier="drunk",amount=5}}
    },
    mannitol={types={"binder"},skillrequirement=60,
        effects={
            {type="yieldmult",value=2},
            {type="addeffect",identifier="afmannitol",amount=10}},
        faileffects={
            {type="yieldmult",value=2},
            {type="addeffect",identifier="afmannitol",amount=5}}
    },
    elastin={types={"binder"},skillrequirement=40,
        effects={
            {type="potencymult",value=1.25}},
        faileffects={
            {type="potencymult",value=0.9}}
    },
    plastic={types={"binder"},skillrequirement=50,
        effects={
            {type="yieldmult",value=0.5},
            {type="potencymult",value=1.6}},
        faileffects={
            {type="yieldmult",value=0.5},
            {type="potencymult",value=1}}
    },

    -- /// active ingredients ///
    opium={types={"active"},skillrequirement=15,
        effects={
            {type="addeffect",identifier="analgesia",amount=10},
            {type="addeffect",identifier="opiateaddiction",amount=2.5},
            {type="addeffect",identifier="opiateoverdose",amount=4.37},
            {type="addeffect",identifier="opiatewithdrawal",amount=-7.5}},
        faileffects={
            {type="addeffect",identifier="analgesia",amount=5},
            {type="addeffect",identifier="opiateaddiction",amount=10},
            {type="addeffect",identifier="opiateoverdose",amount=7.5},
            {type="addeffect",identifier="opiatewithdrawal",amount=-7.5}}
    },
    antidama1={types={"active"},skillrequirement=30,
        effects={
            {type="addeffect",identifier="analgesia",amount=25},
            {type="addeffect",identifier="opiateaddiction",amount=5},
            {type="addeffect",identifier="opiateoverdose",amount=5},
            {type="addeffect",identifier="opiatewithdrawal",amount=-15}},
        faileffects={
            {type="addeffect",identifier="analgesia",amount=12.5},
            {type="addeffect",identifier="opiateaddiction",amount=12.5},
            {type="addeffect",identifier="opiateoverdose",amount=10},
            {type="addeffect",identifier="opiatewithdrawal",amount=-15}}
    },
    antidama2={types={"active"},skillrequirement=45,
        effects={
            {type="addeffect",identifier="analgesia",amount=37.5},
            {type="addeffect",identifier="opiateaddiction",amount=7.5},
            {type="addeffect",identifier="opiateoverdose",amount=11.25},
            {type="addeffect",identifier="opiatewithdrawal",amount=-50}},
        faileffects={
            {type="addeffect",identifier="analgesia",amount=25},
            {type="addeffect",identifier="opiateaddiction",amount=20},
            {type="addeffect",identifier="opiateoverdose",amount=15},
            {type="addeffect",identifier="opiatewithdrawal",amount=-50}}
    },
    antinarc={types={"active"},skillrequirement=40,
        effects={
            {type="addeffect",identifier="analgesia",amount=-30},
            {type="addeffect",identifier="opiateoverdose",amount=-30},
            {type="addeffect",identifier="opiatewithdrawal",amount=-30}},
        faileffects={
            {type="addeffect",identifier="coma",amount=8,chance=0.5},
            {type="addeffect",identifier="analgesia",amount=-30},
            {type="addeffect",identifier="opiateoverdose",amount=-15},
            {type="addeffect",identifier="opiatewithdrawal",amount=-15}}
    },
    antibiotics={types={"active"},skillrequirement=25,
        effects={
            {type="addeffect",identifier="afantibiotics",amount=25}},
        faileffects={
            {type="addeffect",identifier="afantibiotics",amount=15}}
    },
    adrenaline={types={"active"},skillrequirement=0,
        effects={{type="addeffect",identifier="afadrenaline",amount=30}}
    },
    liquidoxygenite={types={"active"},skillrequirement=72,
        effects={
            {type="addeffect",identifier="organdamage",amount=2.5},
            {type="addeffect",identifier="kidneydamage",amount=2.5},
            {type="addeffect",identifier="heartdamage",amount=2.5},
            {type="addeffect",identifier="lungdamage",amount=2.5},
            {type="addeffect",identifier="liverdamage",amount=2.5},
            {type="addeffect",identifier="hypoxemia",amount=-100},
        },
        faileffects={
            {type="addeffect",identifier="organdamage",amount=2.5},
            {type="addeffect",identifier="kidneydamage",amount=2.5},
            {type="addeffect",identifier="heartdamage",amount=2.5},
            {type="addeffect",identifier="lungdamage",amount=2.5},
            {type="addeffect",identifier="liverdamage",amount=2.5},
            {type="addeffect",identifier="hypoxemia",amount=-60}
        }
    },
    deusizine={types={"active"},skillrequirement=72,
        effects={
            {type="addeffect",identifier="burn",amount=2},
            {type="addeffect",identifier="organdamage",amount=-20},
            {type="addeffect",identifier="internaldamage",amount=-20},
            {type="addeffect",identifier="bloodloss",amount=-20},
            {type="addeffect",identifier="hypoxemia",amount=-50},
        },
        faileffects={
            {type="addeffect",identifier="burn",amount=6},
            {type="addeffect",identifier="organdamage",amount=-10},
            {type="addeffect",identifier="internaldamage",amount=-10},
            {type="addeffect",identifier="bloodloss",amount=-10},
            {type="addeffect",identifier="hypoxemia",amount=-20},
        }
    },
    meth={types={"active"},skillrequirement=35,
        effects={
            {type="addeffect",identifier="haste",amount=210},
            {type="addeffect",identifier="organdamage",amount=7},
            {type="addeffect",identifier="cerebralhypoxia",amount=7},
            {type="addeffect",identifier="psychosis",amount=15},
            {type="addeffect",identifier="chemaddiction",amount=7},
            {type="addeffect",identifier="chemwithdrawal",amount=-45},
        },
        faileffects={
            {type="addeffect",identifier="haste",amount=150},
            {type="addeffect",identifier="organdamage",amount=15},
            {type="addeffect",identifier="cerebralhypoxia",amount=15},
            {type="addeffect",identifier="psychosis",amount=22},
            {type="addeffect",identifier="chemaddiction",amount=15},
            {type="addeffect",identifier="chemwithdrawal",amount=-45},
        }
    },
    steroids={types={"active"},skillrequirement=35,
        effects={
            {type="addeffect",identifier="strengthen",amount=210},
            {type="addeffect",identifier="organdamage",amount=7},
            {type="addeffect",identifier="cerebralhypoxia",amount=7},
            {type="addeffect",identifier="psychosis",amount=15},
            {type="addeffect",identifier="chemaddiction",amount=7},
            {type="addeffect",identifier="chemwithdrawal",amount=-45},
        },
        faileffects={
            {type="addeffect",identifier="strengthen",amount=150},
            {type="addeffect",identifier="organdamage",amount=15},
            {type="addeffect",identifier="cerebralhypoxia",amount=15},
            {type="addeffect",identifier="psychosis",amount=22},
            {type="addeffect",identifier="chemaddiction",amount=15},
            {type="addeffect",identifier="chemwithdrawal",amount=-45},
        }
    },
    hyperzine={types={"active"},skillrequirement=50,
        effects={
            {type="addeffect",identifier="haste",amount=200},
            {type="addeffect",identifier="strengthen",amount=200},
            {type="addeffect",identifier="organdamage",amount=5},
            {type="addeffect",identifier="cerebralhypoxia",amount=5},
            {type="addeffect",identifier="psychosis",amount=15},
            {type="addeffect",identifier="chemaddiction",amount=10},
            {type="addeffect",identifier="chemwithdrawal",amount=-45},
        },
        faileffects={
            {type="addeffect",identifier="haste",amount=200},
            {type="addeffect",identifier="strengthen",amount=200},
            {type="addeffect",identifier="organdamage",amount=10},
            {type="addeffect",identifier="cerebralhypoxia",amount=10},
            {type="addeffect",identifier="psychosis",amount=30},
            {type="addeffect",identifier="chemaddiction",amount=10},
            {type="addeffect",identifier="chemwithdrawal",amount=-45},
        }
    },
    antipsychosis={types={"active"},skillrequirement=37,
        effects={
            {type="addeffect",identifier="psychosis",amount=-50},
            {type="addeffect",identifier="hallucinating",amount=-50},
            {type="addeffect",identifier="alcoholwithdrawal",amount=-50}
        },
        faileffects={
            {type="addeffect",identifier="psychosis",amount=-12},
            {type="addeffect",identifier="hallucinating",amount=-12},
            {type="addeffect",identifier="alcoholwithdrawal",amount=-12}
        }
    },
    antiparalysis={types={"active"},skillrequirement=64,
        effects={
            {type="addeffect",identifier="paralysisresistance",amount=400},
            {type="addeffect",identifier="psychosis",amount=2.5},
            {type="addeffect",identifier="anesthesia",amount=-200}
        },
        faileffects={
            {type="addeffect",identifier="paralysisresistance",amount=200},
            {type="addeffect",identifier="psychosis",amount=20},
            {type="addeffect",identifier="anesthesia",amount=-200}
        }
    },
    propofol={types={"active"},skillrequirement=0,
        effects={{type="addeffect",identifier="anesthesia",amount=1}}
    },
    streptokinase={types={"active"},skillrequirement=0,
        effects={
            {type="addeffect",identifier="heartattack",amount=-20},
            {type="addeffect",identifier="hemotransfusionshock",amount=-50},
            {type="addeffect",identifier="afstreptokinase",amount=25}
        }
    },
    thiamine={types={"active"},skillrequirement=20,
        effects={
            {type="addeffect",identifier="afthiamine",amount=25}
        },
        faileffects={
            {type="addeffect",identifier="afthiamine",amount=15}
        }
    },
    immunosuppressant={types={"active"},skillrequirement=40,
        effects={
            {type="addeffect",identifier="afimmunosuppressant",amount=25}
        },
        faileffects={
            {type="addeffect",identifier="afimmunosuppressant",amount=15},
            {type="addeffect",identifier="sepsis",amount=1,chance=0.5}
        }
    },
    calyxanide={types={"active"},skillrequirement=38,
        effects={
            {type="addeffect",identifier="huskinfection",amount=-50}
        },
        faileffects={
            {type="addeffect",identifier="huskinfection",amount=-30}
        }
    },
    morbusineantidote={types={"active"},skillrequirement=0,
        effects={
            {type="addeffect",identifier="morbusinepoisoning",amount=-50}
        }
    },
    cyanideantidote={types={"active"},skillrequirement=0,
        effects={
            {type="addeffect",identifier="cyanidepoisoning",amount=-50}
        }
    },
    sufforinantidote={types={"active"},skillrequirement=0,
        effects={
            {type="addeffect",identifier="sufforinpoisoning",amount=-50}
        }
    },
    deliriumineantidote={types={"active"},skillrequirement=0,
        effects={
            {type="addeffect",identifier="deliriuminepoisoning",amount=-50},
            {type="addeffect",identifier="psychosis",amount=-7}
        }
    },
    antirad={types={"active"},skillrequirement=0,
        effects={
            {type="addeffect",identifier="radiationsickness",amount=-50}
        }
    },
    stabilozine={types={"active"},skillrequirement=0,
        effects={
            {type="addeffect",identifier="drunk",amount=-15},
            {type="addeffect",identifier="morbusinepoisoning",amount=-15},
            {type="addeffect",identifier="cyanidepoisoning",amount=-15},
            {type="addeffect",identifier="sufforinpoisoning",amount=-15},
            {type="addeffect",identifier="deliriuminepoisoning",amount=-15},
            {type="addeffect",identifier="opiatewithdrawal",amount=-15},
            {type="addeffect",identifier="chemwithdrawal",amount=-15},
            {type="addeffect",identifier="alcoholwithdrawal",amount=-15},
            {type="addeffect",identifier="radiationsickness",amount=-15},
            {type="addeffect",identifier="paralysis",amount=-15},
        }
    },
    carbon={types={"active"},skillrequirement=0,
        effects={
            {type="addeffect",identifier="drunk",amount=-7},
            {type="addeffect",identifier="morbusinepoisoning",amount=-7},
            {type="addeffect",identifier="cyanidepoisoning",amount=-7},
            {type="addeffect",identifier="sufforinpoisoning",amount=-7},
            {type="addeffect",identifier="deliriuminepoisoning",amount=-7},
            {type="addeffect",identifier="radiationsickness",amount=-15},
            {type="addeffect",identifier="paralysis",amount=-7},
        }
    },
    lithium={types={"active"},skillrequirement=0,
        effects={{type="addeffect",identifier="nausea",amount=20}}},
    lead={types={"active"},skillrequirement=0,
        effects={{type="addeffect",identifier="cerebralhypoxia",amount=20}}},
    uranium={types={"active"},skillrequirement=0,
        effects={{type="addeffect",identifier="radiationsickness",amount=20}}},
    thorium={types={"active"},skillrequirement=0,
        effects={{type="addeffect",identifier="radiationsickness",amount=30}}},
    nitroglycerin={types={"active"},skillrequirement=0,
        effects={
            {type="addeffect",identifier="cardiacarrest",amount=-100},
            {type="addeffect",identifier="heartattack",amount=-50},
        }
    },
    sulphuricacid={types={"active"},skillrequirement=0,
        effects={
            {type="addeffect",identifier="burn",amount=7.5}
        }
    },
    tonicliquid={types={"active"},skillrequirement=0,
        effects={
            {type="addeffect",identifier="durationincrease",amount=150}
        }
    },
    combatstimulantsyringe={types={"active"},skillrequirement=35,
        effects={
            {type="addeffect",identifier="combatstimulant",amount=37},
            {type="addeffect",identifier="chemaddiction",amount=10}
        },
        faileffects={
            {type="addeffect",identifier="combatstimulant",amount=37},
            {type="addeffect",identifier="chemaddiction",amount=20}
        }
    },
    pressurestabilizer={types={"active"},skillrequirement=35,
        effects={
            {type="addeffect",identifier="pressurestabilized",amount=500}
        },
        faileffects={
            {type="addeffect",identifier="pressurestabilized",amount=250}
        }
    },
    mannitolplus={types={"active"},skillrequirement=60,
        effects={
            {type="addeffect",identifier="afmannitol",amount=30},
            {type="addeffect",identifier="cerebralhypoxia",amount=-10}
        },
        faileffects={
            {type="addeffect",identifier="afmannitol",amount=15},
            {type="addeffect",identifier="cerebralhypoxia",amount=-5}
        }
    },
    hallucinogenicbufotoxin={types={"active"},skillrequirement=30,
        effects={
            {type="addeffect",identifier="paralysis",amount=-30},
            {type="addeffect",identifier="psychosis",amount=10}
        },
        faileffects={
            {type="addeffect",identifier="paralysis",amount=-15},
            {type="addeffect",identifier="psychosis",amount=10}
        }
    },
    -- poisons
    morbusine={types={"active"},weight=0.4,skillrequirement=0,
        effects={{type="addeffect",identifier="morbusinepoisoning",amount=1}}},
    cyanide={types={"active"},weight=0.4,skillrequirement=0,
        effects={{type="addeffect",identifier="cyanidepoisoning",amount=1}}},
    sufforin={types={"active"},weight=0.4,skillrequirement=0,
        effects={{type="addeffect",identifier="sufforinpoisoning",amount=1}}},
    deliriumine={types={"active"},weight=0.4,skillrequirement=0,
        effects={{type="addeffect",identifier="deliriuminepoisoning",amount=1}}},
    chloralhydrate={types={"active"},skillrequirement=0,
        effects={{type="addeffect",identifier="incrementalstun",amount=15}}},
    radiotoxin={types={"active"},weight=0.4,skillrequirement=0,
        effects={{type="addeffect",identifier="radiationsickness",amount=32}}},
    paralyzant={types={"active"},weight=0.2,skillrequirement=0,
        effects={{type="addeffect",identifier="paralysis",amount=1}}},
    paralyxis={variantof="paralyzant"},
    raptorbaneextract={types={"active"},skillrequirement=0,
        effects={{type="addeffect",identifier="nausea",amount=25}}},
    poop={types={"active"},weight=0.4,skillrequirement=0,
        effects={{type="addeffect",identifier="sepsis",amount=1}}},
    
    -- /// exipients ///
    sodium={types={"filler"},skillrequirement=15,
        effects={
            {type="addtag",tag="soluable"},
            {type="potencymult",value=1.2}},
        faileffects={
            {type="addtag",tag="soluable"},
            {type="potencymult",value=0.8}}
    },
    silicon={types={"filler"},skillrequirement=25,
        effects={
            {type="sprite",value="tablets"},
            {type="potencymult",value=0.5},
            {type="yieldmult",value=2}},
        faileffects={
            {type="sprite",value="tablets"},
            {type="potencymult",value=0.35},
            {type="yieldmult",value=2}}
    },
    magnesium={types={"filler"},skillrequirement=15,
        effects={
            {type="sprite",value="horsepill"},
            {type="potencymult",value=2},
            {type="yieldmult",value=0.5}},
        faileffects={
            {type="sprite",value="horsepill"},
            {type="potencymult",value=1.3},
            {type="yieldmult",value=0.5}}
    },
    calcium={types={"filler"},skillrequirement=25,
        effects={
            {type="potencymult",value=0.35},
            {type="yieldmult",value=3}},
        faileffects={
            {type="potencymult",value=0.20},
            {type="yieldmult",value=3}}
    },
    chlorine={types={"filler"},skillrequirement=50,
        effects={
            {type="potencymult",value=1.3},
            {type="addeffect",identifier="burn",amount=2}},
        faileffects={
            {type="potencymult",value=0.7},
            {type="addeffect",identifier="burn",amount=8}}
    },

    -- /// dyes ///
    redpaint={types={"dye"},skillrequirement=0,
        effects={{type="color",r=255,g=51,b=51}}},
    greenpaint={types={"dye"},skillrequirement=0,
        effects={{type="color",r=51,g=255,b=51}}},
    bluepaint={types={"dye"},skillrequirement=0,
        effects={{type="color",r=51,g=51,b=255}}},
    blackpaint={types={"dye"},skillrequirement=0,
        effects={{type="color",r=51,g=51,b=51}}},
    whitepaint={types={"dye"},skillrequirement=0,
        effects={{type="color",r=255,g=255,b=255}}},
}
NTP.PillData.combos = {
    antihusk={
        requireditems={{id="antibiotics"},{id="calyxanide"}},
        forbiddenitems={},
        coloroverride={22,204,143},
        descriptionoverride="antihusk",
        effectoverride={skillrequirement=30,
            effects={
                {type="addeffect",identifier="huskinfection",amount=-70},
                {type="addeffect",identifier="huskinfectionresistance",amount=500},
            },
            faileffects={
                {type="addeffect",identifier="huskinfection",amount=-40},
                {type="addeffect",identifier="huskinfectionresistance",amount=300},
            }
        }
    },
    sodiumboom1={
        requireditems={{id="antibloodloss1"},{id="sodium"}},
        effectoverride={skillrequirement=0,
            effects={{type="addtag",tag="instantexplode"}}
        }
    },
    sodiumboom2={
        requireditems={{id="ringerssolution"},{id="sodium"}},
        effectoverride={skillrequirement=0,
            effects={{type="addtag",tag="instantexplode"}}
        }
    },
}

-- extrude variants (wait twice so other mods can add variants of other things)
Timer.Wait(function() Timer.Wait(function()
    for key,val in pairs(NTP.PillData.items) do
        if val.variantof ~= nil then
            NTP.PillData.items[key] = NTP.PillData.items[val.variantof]
        end
    end
end,1) end,1)


function NTP.TagsToPillconfig(tags)
    local res = {fx={},yield=2,capacity=0,tags={},ingredients={},color=nil,description=nil}
    for i, tag in ipairs(tags) do
        if HF.StartsWith(tag,"yld/") then
            local args = HF.SplitString(tag,"/")
            res.yield = tonumber(args[2] or "2")
        elseif HF.StartsWith(tag,"cap/") then
            local args = HF.SplitString(tag,"/")
            res.capacity = tonumber(args[2] or "2")
        elseif HF.StartsWith(tag,"des/") then
            local args = HF.SplitString(tag,"/")
            res.description = args[2]
        elseif HF.StartsWith(tag,"col/") then
            local args = HF.SplitString(tag,"/")
            res.color = {tonumber(args[2]),tonumber(args[3]),tonumber(args[4])}
        elseif HF.StartsWith(tag,"ing/") then
            local args = HF.SplitString(tag,"/")
            res.ingredients[args[2]] = tonumber(args[3]) or 1
        elseif HF.StartsWith(tag,"fx/") then
            local args = HF.SplitString(tag,"/")
            res.fx[args[2]] = tonumber(args[3]) or 1
        elseif tag ~= "init" and i > 4 then
            table.insert(res.tags,tag)
        end
    end
    return res
end
function NTP.PillConfigFromPill(pillitem)
    return NTP.TagsToPillconfig(HF.SplitString(pillitem.Tags,","))
end
function NTP.PillConfigToTags(config)
    local res = {"init"}

    -- yield
    table.insert(res,"yld/"..tostring(HF.Round(config.yield)))
    -- capacity
    table.insert(res,"cap/"..tostring(HF.Round(config.capacity)))

    -- description
    if config.description ~= nil then
        table.insert(res,"des/"..config.description) end

    -- color
    if config.color ~= nil then 
        table.insert(res,"col/"
        ..tostring(HF.Round(config.color[1])).."/"
        ..tostring(HF.Round(config.color[2])).."/"
        ..tostring(HF.Round(config.color[3]))) end

    -- ingredients
    for id,amount in pairs(config.ingredients) do
        table.insert(res,"ing/"..id.."/"..tostring(amount))
    end

    -- afflictions
    for effectid, effectstrength in pairs(config.fx) do
        table.insert(res,"fx/"..effectid.."/"..tostring(HF.Round(effectstrength)))
    end

    -- tags
    for tag in config.tags do
        table.insert(res,tag)
    end

    
    return res
end
function NTP.PillConfigFromItems(components,skill,descriptionOverride,user)
    skill = skill or 30

    local res = {fx={},capacity=0,yield=2,tags={},
    ingredients={},color=nil,description=nil,
    sprite=nil}

    local potencymult = 1
    local basepotencymult = 1
    local binderpotencymult = 1
    local activepotencymult = 1
    local fillerpotencymult = 1
    local yieldmult = 1
    local yield = 2
    local capacity=0
    local color = nil

    -- build ingredients
    for id in components do
        res.ingredients[id] = (res.ingredients[id] or 0) + 1
    end

    -- fetch item success
    local success = {}
    for i, itemidentifier in ipairs(components) do
        local s = true
        if NTP.PillData.items[itemidentifier] ~= nil then
            s = math.random() < 
                skill/(NTP.PillData.items[itemidentifier].skillrequirement or 30)
        end
        success[i] = s
    end

    -- fetch multipliers
    for i, itemidentifier in ipairs(components) do
        if NTP.PillData.items[itemidentifier] ~= nil then
            local effects = NTP.PillData.items[itemidentifier].effects or {}
            if not success[i] then effects = NTP.PillData.items[itemidentifier].faileffects or effects end
        
            for effect in effects do
                if effect.type == "potencymult" then potencymult=potencymult*effect.value
                elseif effect.type == "basepotencymult" then basepotencymult=basepotencymult*effect.value
                elseif effect.type == "binderpotencymult" then binderpotencymult=binderpotencymult*effect.value
                elseif effect.type == "activepotencymult" then activepotencymult=activepotencymult*effect.value
                elseif effect.type == "fillerpotencymult" then fillerpotencymult=fillerpotencymult*effect.value
                elseif effect.type == "yieldmult" then yieldmult=yieldmult*effect.value
                elseif effect.type == "yield" then yield=yield+effect.value
                elseif effect.type == "capacity" then capacity=capacity+effect.value
                elseif effect.type == "sprite" then res.sprite=effect.value
                end
            end
        end
    end

    res.capacity = capacity

    -- check for combos
    local activecombo = nil
    for comboidentifier, combo in pairs(NTP.PillData.combos) do
        local viable = true
        -- required items
        if combo.requireditems~=nil then
            for requirement in combo.requireditems do
                if
                    res.ingredients[requirement.id] == nil or
                    res.ingredients[requirement.id] < (requirement.amount or 1)
                then
                    viable=false
                    break
                end
            end
        end
        -- forbidden items
        if viable and combo.forbiddenitems~=nil then
            for forbidden in combo.forbiddenitems do
                if res.ingredients[forbidden] ~= nil then
                    viable=false
                    break
                end
            end
        end

        if viable then activecombo = combo break end
    end

    -- apply effects
    if activecombo ~= nil and activecombo.effectoverride ~= nil then
        local s = math.random() < 
            skill/(activecombo.effectoverride.skillrequirement or 30)
        local effects = nil
        if s or activecombo.effectoverride.faileffects == nil then
            effects = activecombo.effectoverride.effects
        else effects = activecombo.effectoverride.faileffects end

        if effects ~= nil then
            for effect in effects do
                if effect.type == "addeffect" and (effect.chance == nil or HF.Chance(effect.chance)) then

                    local strength = effect.amount * potencymult

                    -- add strength to existing effect
                    if res.fx[effect.identifier]~=nil then strength=strength+res.fx[effect.identifier] end
                    -- set effect
                    res.fx[effect.identifier] = strength
                elseif effect.type=="addtag" then
                    table.insert(res.tags,effect.tag)
                end
            end
        end
    else
        for i, itemidentifier in ipairs(components) do
            if NTP.PillData.items[itemidentifier] ~= nil then
                local effects = NTP.PillData.items[itemidentifier].effects or {}
                if not success[i] then effects = NTP.PillData.items[itemidentifier].faileffects or effects end
            
                local itemType = NTP.PillData.items[itemidentifier].types[1] or ""
    
                for effect in effects do
                    if effect.type == "addeffect" and (effect.chance == nil or HF.Chance(effect.chance)) then
                        local strengthmult=1
    
                        if itemType == "base" then strengthmult=basepotencymult
                        elseif itemType == "binder" then strengthmult=binderpotencymult
                        elseif itemType == "active" then strengthmult=activepotencymult
                        elseif itemType == "filler" then strengthmult=fillerpotencymult
                        end
    
                        local strength = effect.amount * strengthmult * potencymult
    
                        -- add strength to existing effect
                        if res.fx[effect.identifier]~=nil then strength=strength+res.fx[effect.identifier] end
                        -- set effect
                        res.fx[effect.identifier] = strength
                    elseif effect.type=="addtag" then
                        table.insert(res.tags,effect.tag)
                    elseif effect.type=="color" then
                        if color == nil then
                            color = {effect.r,effect.g,effect.b}
                        else
                            color = {
                                HF.Lerp(color[1],effect.r,0.5),
                                HF.Lerp(color[2],effect.g,0.5),
                                HF.Lerp(color[3],effect.b,0.5)
                            }
                        end
                    end
                end
            end
        end
    end

    -- combo stuff
    if activecombo ~= nil then
        if activecombo.coloroverride~=nil then 
            color = {activecombo.coloroverride[1],activecombo.coloroverride[2],activecombo.coloroverride[3]}
        end
        if activecombo.descriptionoverride~=nil then 
            descriptionOverride =
                TextManager.Get("pillcombo."..activecombo.descriptionoverride).Value
                ..(descriptionOverride or "")
        end
    end

    res.color = color
    res.yield = HF.Round(yield*yieldmult)
    res.description = descriptionOverride

    return res
end

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Item"], "set_InventoryIconColor")

function NTP.SetPillFromConfig(item,config)
    local tags = NTP.PillConfigToTags(config)
    local tagstring = ""
    for index, value in ipairs(tags) do
        tagstring = tagstring..value
        if index < #tags then tagstring=tagstring.."," end
    end

    item.Tags = tagstring

    if config.description~=nil then
        item.Description = config.description
    end

    if config.color ~=nil then
        local col = Color(config.color[1],config.color[2],config.color[3])
        item.SpriteColor = col
        item.set_InventoryIconColor(col)
        if SERVER then
            local property = item.SerializableProperties[Identifier("InventoryIconColor")]
            Networking.CreateEntityEvent(item, Item.ChangePropertyEventData.__new(property,item))
            property = item.SerializableProperties[Identifier("SpriteColor")]
            Networking.CreateEntityEvent(item, Item.ChangePropertyEventData.__new(property,item))
        end
    end

    
end
local function GetRandomPillConfig()
    local components = {}

    local baseIdentifiers = {}
    local fillerIdentifiers = {}
    local binderIdentifiers = {}
    local activeIdentifiers = {}
    local dyeIdentifiers = {}

    local basesWeightSum = 0
    local bindersWeightSum = 0
    local activesWeightSum = 0
    local fillersWeightSum = 0
    local dyesWeightSum = 0

    for id, dat in pairs(NTP.PillData.items) do
        -- makes sure the item actually exists
        local prefab = ItemPrefab.GetItemPrefab(id)
        if prefab ~= nil then
            if dat.types[1]=="base" then
                table.insert(baseIdentifiers,id)
                basesWeightSum = basesWeightSum + (dat.weight or 1)
            elseif dat.types[1]=="binder" then
                table.insert(binderIdentifiers,id)
                bindersWeightSum = bindersWeightSum + (dat.weight or 1)
            elseif dat.types[1]=="filler" then
                table.insert(fillerIdentifiers,id)
                fillersWeightSum = fillersWeightSum + (dat.weight or 1)
            elseif dat.types[1]=="active" then
                table.insert(activeIdentifiers,id)
                activesWeightSum = activesWeightSum + (dat.weight or 1)
            elseif dat.types[1]=="dye" then
                table.insert(dyeIdentifiers,id)
                dyesWeightSum = dyesWeightSum + (dat.weight or 1)
            end
        end
    end

    local bases = 1
    local binders = 1
    local actives = math.random(1,3)
    local fillers = math.random(-1,1)
    local dyes = math.random(-1,3)

    while bases > 0 do
        local weightpick = math.random()*basesWeightSum
        local currentWeight = 0
        for id in baseIdentifiers do
            local dat = NTP.PillData.items[id]
            currentWeight = currentWeight + (dat.weight or 1)
            if currentWeight > weightpick then
                table.insert(components,id)
                break
            end
        end
        bases = bases - 1
    end

    while binders > 0 do
        local weightpick = math.random()*bindersWeightSum
        local currentWeight = 0
        for id in binderIdentifiers do
            local dat = NTP.PillData.items[id]
            currentWeight = currentWeight + (dat.weight or 1)
            if currentWeight > weightpick then
                table.insert(components,id)
                break
            end
        end
        binders = binders - 1
    end

    while fillers > 0 do
        local weightpick = math.random()*fillersWeightSum
        local currentWeight = 0
        for id in fillerIdentifiers do
            local dat = NTP.PillData.items[id]
            currentWeight = currentWeight + (dat.weight or 1)
            if currentWeight > weightpick then
                table.insert(components,id)
                break
            end
        end
        fillers = fillers - 1
    end

    while actives > 0 do
        local weightpick = math.random()*activesWeightSum
        local currentWeight = 0
        for id in activeIdentifiers do
            local dat = NTP.PillData.items[id]
            currentWeight = currentWeight + (dat.weight or 1)
            if currentWeight > weightpick then
                table.insert(components,id)
                break
            end
        end
        actives = actives - 1
    end

    while dyes > 0 do
        local weightpick = math.random()*dyesWeightSum
        local currentWeight = 0
        for id in dyeIdentifiers do
            local dat = NTP.PillData.items[id]
            currentWeight = currentWeight + (dat.weight or 1)
            if currentWeight > weightpick then
                table.insert(components,id)
                break
            end
        end
        dyes = dyes - 1
    end

    
    local config = NTP.PillConfigFromItems(components)

    return config
end
local function RandomizePill(item)
    NTP.SetPillFromConfig(item,GetRandomPillConfig())
end
function NTP.RefreshPillDescription(item)
    -- if not HF.ItemHasTag(item,"init") then return end

    local config = NTP.TagsToPillconfig(HF.SplitString(item.Tags,","))
    if config.description == nil then return end

    local identifier = item.Prefab.Identifier.Value
    if config.sprite~=nil then identifier="custompill_"..config.sprite end
    local itemposition = item.worldPosition
    local targetinventory = item.ParentInventory
    local targetslot = 0
    if targetinventory ~= nil then targetslot = targetinventory.FindIndex(item) end

    HF.RemoveItem(item)
    HF.SpawnItemPlusFunction(identifier,function(params)
        params.item.Description = config.description
        NTP.SetPillFromConfig(params.item,config)
    end,nil,targetinventory,targetslot,itemposition)
end

Hook.Add("NTP.OnPillSpawned", "NTP.OnPillSpawned", function (effect, deltaTime, item, targets, worldPosition)
    if item == nil then return end

    -- instant explosion
    if item.HasTag("instantexplode") then
        HF.Explode(item,100,100,20,20,20)
        HF.RemoveItem(item)
        return
    end

    if item.HasTag("init") then return end
    -- the item still exists and hasnt been initiated, randomize!

    local config = GetRandomPillConfig()

    local identifier = item.Prefab.Identifier.Value
    local itemposition = item.worldPosition
    if config.sprite~=nil then identifier="custompill_"..config.sprite end
    local prefab = ItemPrefab.GetItemPrefab(identifier)
    local targetinventory = item.ParentInventory
    HF.RemoveItem(item)
    HF.SpawnItemPlusFunction(identifier,function(params)
        NTP.SetPillFromConfig(params.item,config)
        if targetinventory~=nil then
            targetinventory.TryPutItem(params.item, nil, {InvSlotType.Any})
        end
    end,nil,nil,nil,itemposition)
    
end)

Hook.Add("roundStart", "NTP.RoundStart", function()
    Timer.Wait(function()
        NTP.RefreshAllPills()
    end,10000) -- maybe 10 seconds is enough?
    
end)

function NTP.RefreshAllPills()
    -- descriptions dont get serialized, so i have to respawn
    -- every pill item every round to keep their descriptions (big oof)

    -- fetch pill items
    --local pillItems = {}
    --for item in Item.ItemList do
    --    if HF.StartsWith(item.Prefab.Identifier.Value,"custompill") then
    --        table.insert(pillItems,item)
    --    end
    --end
    ---- refresh pill items
    --for pillItem in pillItems do
    --    NTP.RefreshPillDescription(pillItem)
    --end

    -- clear chem craft alls
    NTP.ActiveChemCraftalls = {}
end
Timer.Wait(function()
NTP.RefreshAllPills() end,50)
