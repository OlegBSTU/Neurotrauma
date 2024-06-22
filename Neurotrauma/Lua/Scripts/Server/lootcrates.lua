
Hook.Add("NT.medstartercrate.spawn", "NT.medstartercrate.spawn", function(effect, deltaTime, item, targets, worldPosition)
    if item == nil then return end

    -- check if the item already got populated before

    local populated = item.HasTag("used")
    if populated then return end

    -- add used tag

    local tags = HF.SplitString(item.Tags,",")
    table.insert(tags,"used")
    local tagstring = ""
    for index, value in ipairs(tags) do
        tagstring = tagstring..value
        if index < #tags then tagstring=tagstring.."," end
    end
    item.Tags = tagstring

    -- populate with goodies!!

    HF.SpawnItemPlusFunction("medtoolbox",function(params)
        HF.SpawnItemPlusFunction("defibrillator",nil,nil,params.item.OwnInventory,0)
        HF.SpawnItemPlusFunction("autocpr",nil,nil,params.item.OwnInventory,1)
        for i = 1,2,1 do HF.SpawnItemPlusFunction("tourniquet",nil,nil,params.item.OwnInventory,2) end
        for i = 1,2,1 do HF.SpawnItemPlusFunction("ringerssolution",nil,nil,params.item.OwnInventory,3) end
        HF.SpawnItemPlusFunction("surgicaldrill",nil,nil,params.item.OwnInventory,4)
        HF.SpawnItemPlusFunction("surgerysaw",nil,nil,params.item.OwnInventory,5)
    end,nil,item.OwnInventory,0)

    HF.SpawnItemPlusFunction("medtoolbox",function(params)
        HF.SpawnItemPlusFunction("antibleeding1",nil,nil,params.item.OwnInventory,0)
        HF.SpawnItemPlusFunction("gypsum",nil,nil,params.item.OwnInventory,1)
        HF.SpawnItemPlusFunction("opium",nil,nil,params.item.OwnInventory,2)
        HF.SpawnItemPlusFunction("antibiotics",nil,nil,params.item.OwnInventory,3)
        HF.SpawnItemPlusFunction("ointment",nil,nil,params.item.OwnInventory,4)
        HF.SpawnItemPlusFunction("antisepticspray",function(params2)
            HF.SpawnItemPlusFunction("antiseptic",nil,nil,params2.item.OwnInventory,0)
        end,nil,params.item.OwnInventory,5)
        HF.SpawnItemPlusFunction("needle",nil,nil,params.item.OwnInventory,5)
    end,nil,item.OwnInventory,1)

    HF.SpawnItemPlusFunction("surgerytoolbox",function(params)
        HF.SpawnItemPlusFunction("advscalpel",nil,nil,params.item.OwnInventory,0)
        HF.SpawnItemPlusFunction("advhemostat",nil,nil,params.item.OwnInventory,1)
        HF.SpawnItemPlusFunction("advretractors",nil,nil,params.item.OwnInventory,2)
        for i = 1,16,1 do HF.SpawnItemPlusFunction("suture",nil,nil,params.item.OwnInventory,3) end
        HF.SpawnItemPlusFunction("tweezers",nil,nil,params.item.OwnInventory,4)
        HF.SpawnItemPlusFunction("traumashears",nil,nil,params.item.OwnInventory,5)
        HF.SpawnItemPlusFunction("drainage",nil,nil,params.item.OwnInventory,6)
        HF.SpawnItemPlusFunction("organscalpel_kidneys",nil,nil,params.item.OwnInventory,7)
        HF.SpawnItemPlusFunction("organscalpel_liver",nil,nil,params.item.OwnInventory,8)
        HF.SpawnItemPlusFunction("organscalpel_lungs",nil,nil,params.item.OwnInventory,9)
        HF.SpawnItemPlusFunction("organscalpel_heart",nil,nil,params.item.OwnInventory,10)
    end,nil,item.OwnInventory,3)

    HF.SpawnItemPlusFunction("bloodanalyzer",nil,nil,item.OwnInventory,6)
    HF.SpawnItemPlusFunction("healthscanner",nil,nil,item.OwnInventory,7)
    
end)

-- Hooks XML Lua event "NT.medtoolset.spawn" to create medtoolset items and put them inside it
Hook.Add("NT.medtoolset.spawn", "NT.medtoolset.spawn", function(effect, deltaTime, item, targets, worldPosition)
    if item == nil then return end

    -- populate with goodies!!
    -- recipe = 2 steel 2 plastic 2 aluminum 2 fpga
    HF.SpawnItemPlusFunction("defibrillator",nil,nil,item.OwnInventory,0) -- 0.5 aluminum 0.5 plastic 1 fpga
    HF.SpawnItemPlusFunction("autocpr",nil,nil,item.OwnInventory,1) -- 0.5 steel 0.5 plastic 1 fpga
    HF.SpawnItemPlusFunction("surgicaldrill",nil,nil,item.OwnInventory,4) -- 0.5 steel 0.5 zinc 1 fpga
    HF.SpawnItemPlusFunction("surgerysaw",nil,nil,item.OwnInventory,5) -- 0.5 tialloy
    HF.SpawnItemPlusFunction("bvm",nil,nil,item.OwnInventory,6) -- 1 plastic
    HF.SpawnItemPlusFunction("traumashears",nil,nil,item.OwnInventory,7) -- 0.25 steel 0.25 plastic
    HF.SpawnItemPlusFunction("bloodanalyzer",nil,nil,item.OwnInventory,8) -- 1 plastic 1 silicon 1 fpga circuit
    HF.SpawnItemPlusFunction("healthscanner",nil,nil,item.OwnInventory,9) -- 1 fpga 1 aluminum
end)

-- Hooks XML Lua event "NT.medtoolset.spawn" to create medtoolset items and put them inside it
Hook.Add("NT.firstaidset.spawn", "NT.firstaidset.spawn", function(effect, deltaTime, item, targets, worldPosition)
    if item == nil then return end

    -- populate with goodies!!
    -- recipe = 2 organic fiber 2 calcium 1 aluminum 1 plastic
    HF.SpawnItemPlusFunction("tourniquet",nil,nil,item.OwnInventory,0) -- 1 organic fiber
    for i = 1,3,1 do HF.SpawnItemPlusFunction("bandage",nil,nil,item.OwnInventory,1) end -- 1 organic fiber
    for i = 1,2,1 do HF.SpawnItemPlusFunction("gypsum",nil,nil,item.OwnInventory,2) end -- 2 calcium
    HF.SpawnItemPlusFunction("traumashears",nil,nil,item.OwnInventory,3) -- 0.25 steel 0.25 plastic
    HF.SpawnItemPlusFunction("needle",nil,nil,item.OwnInventory,4) -- 1 plastic 0.25 aluminum
    for i = 1,8,1 do HF.SpawnItemPlusFunction("suture",nil,nil,item.OwnInventory,5) end -- 1 organic fiber 0.25 aluminum
end)

-- Hooks XML Lua event "NT.surgerytoolset.spawn" to create surgerytoolset items and put them inside it
Hook.Add("NT.surgerytoolset.spawn", "NT.surgerytoolset.spawn", function(effect, deltaTime, item, targets, worldPosition)
    if item == nil then return end

    -- populate with goodies!!
    -- 2 steel 2 zinc 2 organic fiber 2 plastic
    HF.SpawnItemPlusFunction("advscalpel",nil,nil,params.item.OwnInventory,0) -- 0.25 steel 0.25 zinc
    HF.SpawnItemPlusFunction("advhemostat",nil,nil,params.item.OwnInventory,1) -- 0.25 steel 0.25 zinc
    HF.SpawnItemPlusFunction("advretractors",nil,nil,params.item.OwnInventory,2) -- 0.25 steel 0.25 zinc
    for i = 1,16,1 do HF.SpawnItemPlusFunction("suture",nil,nil,params.item.OwnInventory,3) end -- 2 organic fiber 0.5 aluminum
    HF.SpawnItemPlusFunction("tweezers",nil,nil,params.item.OwnInventory,4) -- 0.25 steel 0.25 zinc
    HF.SpawnItemPlusFunction("traumashears",nil,nil,params.item.OwnInventory,5) -- 0.25 steel 0.25 plastic
    HF.SpawnItemPlusFunction("drainage",nil,nil,params.item.OwnInventory,6) -- 1 plastic
    HF.SpawnItemPlusFunction("organscalpel_kidneys",nil,nil,params.item.OwnInventory,7) -- 0.25 steel 0.25 zinc
    HF.SpawnItemPlusFunction("organscalpel_liver",nil,nil,params.item.OwnInventory,8) -- 0.25 steel 0.25 zinc
    HF.SpawnItemPlusFunction("organscalpel_lungs",nil,nil,params.item.OwnInventory,9) -- 0.25 steel 0.25 zinc
    HF.SpawnItemPlusFunction("organscalpel_heart",nil,nil,params.item.OwnInventory,10) -- 0.25 steel 0.25 zinc

end)
