NTConfig = {Entries={},Expansions={}} -- contains all config options, their default, type, valid ranges, difficulty influence

local configDirectoryPath = Game.SaveFolder.."/ModConfigs"
local configFilePath = configDirectoryPath.."/Neurotrauma.json"

-- this is the function that gets used in other mods to add their own settings to the config
function NTConfig.AddConfigOptions(expansion)
    table.insert(NTConfig.Expansions,expansion)

    for key,entry in pairs(expansion.ConfigData) do
        NTConfig.Entries[key] = entry
        NTConfig.Entries[key].value = entry.default
    end
end

function NTConfig.SaveConfig()
    File.CreateDirectory(configDirectoryPath)

    local tableToSave = {}
    for key,entry in pairs(NTConfig.Entries) do
        tableToSave[key] = entry.value
    end
    File.Write(configFilePath, json.serialize(tableToSave))
end

function NTConfig.ResetConfig()
    File.CreateDirectory(configDirectoryPath)
	
	local tableToSave = {}
	for key,entry in pairs(NTConfig.Entries) do
        tableToSave[key] = entry.default
        NTConfig.Entries[key] = entry
        NTConfig.Entries[key].value = entry.default
    end
	File.Write(configFilePath, json.serialize(tableToSave))
end

function NTConfig.LoadConfig()
    if not File.Exists(configFilePath) then return end

    local readConfig = json.parse(File.Read(configFilePath))

    for key,value in pairs(readConfig) do
        if NTConfig.Entries[key] then
            NTConfig.Entries[key].value = value
        end
    end
end

function NTConfig.Get(key, default)
    if NTConfig.Entries[key] then
        return NTConfig.Entries[key].value
    end
    return default
end

function NTConfig.Set(key, value)
    if NTConfig.Entries[key] then 
        NTConfig.Entries[key].value = value
    end
end

NT.ConfigData = {
    NT_header1 =                        {name="Neurotrauma",type="category"},

    NT_dislocationChance =              {name="Dislocation chance",default=1,range={0,100},type="float",                difficultyCharacteristics={max=5}},
    NT_fractureChance =                 {name="Fracture chance",default=1,range={0,100},type="float",                   difficultyCharacteristics={multiplier=2,max=5}},
    NT_pneumothoraxChance =             {name="Pneumothorax chance",default=1,range={0,100},type="float",               difficultyCharacteristics={max=5}},
    NT_tamponadeChance =                {name="Tamponade chance",default=1,range={0,100},type="float",                  difficultyCharacteristics={max=3}},
    NT_heartattackChance =              {name="Heart attack chance",default=1,range={0,100},type="float",               difficultyCharacteristics={multiplier=0.5,max=1}},
    NT_strokeChance =                   {name="Stroke chance",default=1,range={0,100},type="float",                     difficultyCharacteristics={multiplier=0.5,max=1}},
    NT_infectionRate =                  {name="Infection rate",default=1,range={0,100},type="float",                    difficultyCharacteristics={multiplier=1.5,max=5}},
    NT_CPRFractureChance =              {name="CPR fracture chance",default=1,range={0,100},type="float",               difficultyCharacteristics={multiplier=0.5,max=1}},
    NT_traumaticAmputationChance =      {name="Traumatic amputation chance",default=1,range={0,100},type="float",       difficultyCharacteristics={max=3}},
    NT_neurotraumaGain =                {name="Neurotrauma gain",default=1,range={0,100},type="float",                  difficultyCharacteristics={multiplier=3,max=10}},
    NT_organDamageGain =                {name="Organ damage gain",default=1,range={0,100},type="float",                 difficultyCharacteristics={multiplier=2,max=8}},
    NT_fibrillationSpeed =              {name="Fibrillation rate",default=1,range={0,100},type="float",                 difficultyCharacteristics={multiplier=1.5,max=8}},
    NT_gangrenespeed =                  {name="Gangrene rate",default=1,range={0,100},type="float",                     difficultyCharacteristics={multiplier=0.5,max=5}},
    NT_falldamage =                     {name="Falldamage",default=1,range={0,100},type="float",                        difficultyCharacteristics={multiplier=0.5,max=5}},
    NT_falldamageSeriousInjuryChance =  {name="Falldamage serious injury chance",default=1,range={0,100},type="float",  difficultyCharacteristics={multiplier=0.5,max=5}},

    NT_vanillaSkillCheck =              {name="Vanilla skill check formula",default=false,type="bool",description="Changes the chance to succeed a lua skillcheck from skill/requiredskill to 100-(requiredskill-skill))/100"},
    NT_disableBotAlgorithms =           {name="Disable bot treatment algorithms",default=true,type="bool",description="Prevents bots from attempting to treat afflictions.\nThis is desireable, because bots suck at treating things, and their bad attempts lag out the game immensely."},
    NT_disableConsentRequired =         {name="Disable Consent Required",default=false,type="bool",description="Disable integrated consent required mod.\n(If ticked, bots will not get aggravated by medical interactions.)"},
	NT_screams =                        {name="Screams",default=true,type="bool",description="Characters scream when in pain."},
    NT_ignoreModConflicts =             {name="Ignore mod conflicts",default=false,type="bool",description="Prevent the mod conflict affliction from showing up."},

    NT_organRejection =                 {name="Organ rejection",default=false,type="bool",          difficultyCharacteristics={multiplier=0.5},description="When transplanting an organ, there is a chance that the organ gets rejected.\nThe higher the patients immunity at the time of the transplant, the higher the chance."},
    NT_fracturesRemoveCasts =           {name="Fractures remove casts",default=true,type="bool",    difficultyCharacteristics={multiplier=0.5},description="When receiving damage that would cause a fracture, remove plaster casts on the limb"},
}
NTConfig.AddConfigOptions(NT)

-- wait a bit before loading the config so all options have had time to be added
-- do note that this unintentionally causes a couple ticks time on load during which the config is always the default
-- remember to put default values in your NTConfig.Get calls!
Timer.Wait(function()
    NTConfig.LoadConfig()

    Timer.Wait(function()
        NTConfig.SaveConfig()
    end,1000)
	
end,50)

