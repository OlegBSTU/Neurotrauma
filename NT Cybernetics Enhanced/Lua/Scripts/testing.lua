
-- set the below variable to true to enable debug and testing features
NTCyb.TestingEnabled = false

Hook.Add('chatMessage', 'NTC.testing', function(msg, client)
    
    if(msg=="ntcyb1") then
        if not NTCyb.TestingEnabled then return end
        -- insert testing stuff here
        
        NTCyb.CyberifyLimb(client.Character,LimbType.RightLeg,true)
        NTCyb.CyberifyLimb(client.Character,LimbType.LeftLeg,true)
        NTCyb.CyberifyLimb(client.Character,LimbType.LeftArm,true)
        NTCyb.CyberifyLimb(client.Character,LimbType.RightArm,true)

        return true
    end
end)