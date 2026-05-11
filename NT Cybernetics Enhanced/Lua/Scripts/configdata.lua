NTCyb.ConfigData = {
    NTCyb_header1 = {name=NTCyb.Name,type="category"},

    NTCyb_waterDamage = {name="Cyberlimb Water Damage",default=1,range={0,5},type="float", difficultyCharacteristics={multiplier=0.5,max=2}},
    NTCyb_cyberpsychosisChance = {name="Cyberpsychosis Chance",default=1,range={0,1},type="float", difficultyCharacteristics={multiplier=0.5,max=2}},
    NTCyb_cyberarmSpeed = {name="Cyberarm Speed Increase",default=1,range={0,2},type="float", difficultyCharacteristics={multiplier=0.5,max=2}},
    NTCyb_cyberlegSpeed = {name="Cyberleg Speed Increase",default=1,range={0,2},type="float", difficultyCharacteristics={multiplier=0.5,max=2}},
}
NTConfig.AddConfigOptions(NTCyb)
