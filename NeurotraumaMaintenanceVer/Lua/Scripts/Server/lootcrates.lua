
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
    end,nil,item.OwnInventory,1)

    HF.SpawnItemPlusFunction("surgerytoolbox",function(params)
        HF.SpawnItemPlusFunction("advscalpel",nil,nil,params.item.OwnInventory,0)
        HF.SpawnItemPlusFunction("advhemostat",nil,nil,params.item.OwnInventory,1)
        HF.SpawnItemPlusFunction("advretractors",nil,nil,params.item.OwnInventory,2)
        for i = 1,16,1 do HF.SpawnItemPlusFunction("suture",nil,nil,params.item.OwnInventory,3) end
        HF.SpawnItemPlusFunction("tweezers",nil,nil,params.item.OwnInventory,4)
        HF.SpawnItemPlusFunction("traumashears",nil,nil,params.item.OwnInventory,5)
        HF.SpawnItemPlusFunction("drainage",nil,nil,params.item.OwnInventory,6)
        HF.SpawnItemPlusFunction("needle",nil,nil,params.item.OwnInventory,7)
        HF.SpawnItemPlusFunction("organscalpel_kidneys",nil,nil,params.item.OwnInventory,8)
        HF.SpawnItemPlusFunction("organscalpel_liver",nil,nil,params.item.OwnInventory,9)
        HF.SpawnItemPlusFunction("organscalpel_lungs",nil,nil,params.item.OwnInventory,10)
        HF.SpawnItemPlusFunction("organscalpel_heart",nil,nil,params.item.OwnInventory,11)
    end,nil,item.OwnInventory,3)

    HF.SpawnItemPlusFunction("bloodanalyzer",nil,nil,item.OwnInventory,6)
    HF.SpawnItemPlusFunction("healthscanner",nil,nil,item.OwnInventory,7)
    
end)
