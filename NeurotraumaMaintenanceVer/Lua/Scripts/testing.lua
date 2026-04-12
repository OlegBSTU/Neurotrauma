
-- set the below variable to true to enable debug and testing features
NT.TestingEnabled = false

Hook.Add('chatMessage', 'NT.testing', function(msg, client)
    
    if (msg == 'nt test') then -- a glorified suicide button

        if(client.Character == nil) then return true end

        HF.SetAfflictionLimb(client.Character,"gate_ta_ra",LimbType.RightArm,100)
        HF.SetAfflictionLimb(client.Character,"gate_ta_la",LimbType.LeftArm,100)
        HF.SetAfflictionLimb(client.Character,"gate_ta_rl",LimbType.RightLeg,100)
        HF.SetAfflictionLimb(client.Character,"gate_ta_ll",LimbType.LeftLeg,100)

        return true -- hide message
    elseif (msg == 'nt unfuck') then -- a command to remove non-sensical extremity amputations on the head and torso

        if(client.Character == nil) then return true end

        HF.SetAfflictionLimb(client.Character,"tll_amputation",LimbType.Head,0)
        HF.SetAfflictionLimb(client.Character,"trl_amputation",LimbType.Head,0)
        HF.SetAfflictionLimb(client.Character,"tla_amputation",LimbType.Head,0)
        HF.SetAfflictionLimb(client.Character,"tra_amputation",LimbType.Head,0)

        HF.SetAfflictionLimb(client.Character,"tll_amputation",LimbType.Torso,0)
        HF.SetAfflictionLimb(client.Character,"trl_amputation",LimbType.Torso,0)
        HF.SetAfflictionLimb(client.Character,"tla_amputation",LimbType.Torso,0)
        HF.SetAfflictionLimb(client.Character,"tra_amputation",LimbType.Torso,0)

        return true -- hide message
    elseif(msg=="nt1") then
        if not NT.TestingEnabled then return end
        -- insert testing stuff here
        
        local test = {val="true"}

        local function testfunc(param) param.val="false" end

        print(test.val)
        testfunc(test)
        print(test.val)

        return true
    elseif(msg=="nt2") then
        if not NT.TestingEnabled then return end
        -- insert other testing stuff here
        local crewenum = Character.GetFriendlyCrew(client.Character)
        local targetchar = nil
        local i = 0
        for char in crewenum do
            print(char.Name)
            targetchar = char
            i = i+1
            if i == 2 then break end
        end

        client.SetClientCharacter(nil)

        print(targetchar)

        Timer.Wait(function() 
            client.SetClientCharacter(targetchar)
        end,50)

        return true
    end
end)