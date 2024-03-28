
NTS.HF = {}
NTS.HF.HasHusk = function(character)
    return HF.GetAfflictionStrength(character,"huskinfection") > 0.1
    --or HF.GetAfflictionStrength(character,"husksymbiosis") > 0.1
end
