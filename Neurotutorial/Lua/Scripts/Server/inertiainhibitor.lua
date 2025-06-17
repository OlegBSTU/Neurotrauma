NTTut.inhibitors = {}
NTTut.signalReceivedMethods.mb_inertiainhibitor = function(signal,connection)

    -- register inhibitor
    if NTTut.inhibitors[connection.Item] == nil then
        NTTut.inhibitors[connection.Item] = connection.Item
    end

    if connection.Name == "set_state" then
        local LightComponent = connection.Item.GetComponent(Components.LightComponent)
        LightComponent.IsOn = (tonumber(signal.value) or 0) > 0
    end
end

Hook.Add("think", "mb_inertiainhibitor", function ()
    if HF.GameIsPaused() then return end

    for item in NTTut.inhibitors do
        if item ~= nil and item.Submarine ~= nil and item.Submarine.PhysicsBody ~= nil then

            local PoweredComponent = item.GetComponent(Components.Powered)
            local LightComponent = item.GetComponent(Components.LightComponent)

            PoweredComponent.IsActive = LightComponent.IsOn

            if (PoweredComponent.IsActive and PoweredComponent.Voltage >= PoweredComponent.MinVoltage) then
                item.Submarine.Velocity = Vector2(0,0)

                local memComponents = NTTut.HF.EnumerableToTable(item.GetComponents(Components.MemoryComponent))
                local desiredposX = tonumber(memComponents[1].Value)
                local desiredposY = tonumber(memComponents[2].Value)
                if desiredposX~=nil and desiredposY~=nil then
                    -- determine distance to desired position
                    local xDiff = math.abs(item.Submarine.PhysicsBody.FarseerBody.Position.X-desiredposX)
                    local yDiff = math.abs(item.Submarine.PhysicsBody.FarseerBody.Position.Y-desiredposY)
                    local distance = math.sqrt(xDiff^2 + yDiff^2)

                    if distance < 15 then
                        -- snap submarine to the desired position
                        -- this *could* cause some phasing bullshit to happen with things that are outside
                        item.Submarine.PhysicsBody.FarseerBody.Position = Vector2(desiredposX,desiredposY)
                    else
                        -- we're too far away to snap back, set current position to the desired one
                        memComponents[1].Value = tostring(item.Submarine.PhysicsBody.FarseerBody.Position.X)
                        memComponents[2].Value = tostring(item.Submarine.PhysicsBody.FarseerBody.Position.Y)
                    end
                else
                    -- no valid position in memory, assign the current one
                    memComponents[1].Value = tostring(item.Submarine.PhysicsBody.FarseerBody.Position.X)
                    memComponents[2].Value = tostring(item.Submarine.PhysicsBody.FarseerBody.Position.Y)
                end
            end
        end
    end
end)
