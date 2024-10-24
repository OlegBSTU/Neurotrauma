local Api = require "ConsentRequiredExtended.Api"

local function isItemAffected(identifier)
    return Api.IsItemAffected(identifier)
end

---@param meleeweapon Weapon target
---@param target The target of the hit could be a limb or just a character.
local function onMeleeWeaponHandleImpact(meleeweapon, target)
    if not NTConfig.Get("NTCRE_ConsentRequired",true) then return end
    if meleeweapon == nil or target == nil then
        return
    end
    local itemIdentifier = meleeweapon.item.Prefab.Identifier.Value
    if isItemAffected(itemIdentifier) then
        local user = meleeweapon.picker
        if user == nil then
            return
        end
        local targetUserData = target.UserData
        if targetUserData == nil then
            return
        end
        local targetUser = nil
        if LuaUserData.IsTargetType(targetUserData, "Barotrauma.Limb") then
            targetUser = targetUserData.character
        elseif LuaUserData.IsTargetType(targetUserData, "Barotrauma.Character") then
            targetUser = targetUserData
        end
        if targetUser ~= nil then
			Api.onAffectedItemApplied(user, targetUser)
        end
    end
end

return onMeleeWeaponHandleImpact
