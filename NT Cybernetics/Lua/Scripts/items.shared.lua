

Timer.Wait(function()
    local supersoldiersTalent = TalentPrefab.TalentPrefabs["supersoldiers"]
    if supersoldiersTalent ~= nil then
        local xmlDefinition = [[
            <overwrite>
                <AddedRecipe itemidentifier="cyberliver" />
                <AddedRecipe itemidentifier="cyberkidney" />
                <AddedRecipe itemidentifier="cyberlung" />
                <AddedRecipe itemidentifier="cyberheart" />
                <AddedRecipe itemidentifier="cyberbrain" />
            </overwrite>
        ]]
        local xml = XDocument.Parse(xmlDefinition)
        for element in xml.Root.Elements() do
            supersoldiersTalent.ConfigElement.Element.Add(element)
        end

        for descNode in supersoldiersTalent.ConfigElement.GetChildElements("Description") do
            if descNode.GetAttributeString("tag") == "talentdescription.unlockrecipe" then
                for replaceTag in descNode.Elements() do
                    replaceTag.SetAttributeValue("value", replaceTag.GetAttributeString("value") .. ",entityname.cyberliver,entityname.cyberkidney,entityname.cyberlung,entityname.cyberheart,entityname.cyberbrain")
                    break
                end
            end
        end
        while TalentPrefab.TalentPrefabs.ContainsKey("supersoldiers") do
            -- remove all existing versions of this talent (including overrides), as we're going to add a new combined one on top
            TalentPrefab.TalentPrefabs.Remove(TalentPrefab.TalentPrefabs["supersoldiers"])
        end
        TalentPrefab.TalentPrefabs.Add(TalentPrefab.__new(supersoldiersTalent.ConfigElement, supersoldiersTalent.ContentFile), false)
    end

    -- Immersive Repairs compatibility
    LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.ItemPrefab"], "set_UseInHealthInterface")
    local immersiveRepairTools = {
        "weldingtool",
        -- "weldingstinger", -- the stinger seems to heal and then hurt the limb (yet the weldingtool doesn't??), so keep it disabled for now
        "repairpack",
        "halligantool",
    }
    for _, tool in ipairs(immersiveRepairTools) do
        if ItemPrefab.Prefabs.ContainsKey(tool) then
            ItemPrefab.Prefabs[tool].set_UseInHealthInterface(true)
        end
    end
end, 1)
