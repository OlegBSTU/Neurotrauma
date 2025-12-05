local Api = require("ConsentRequiredExtended.Api")

local function isItemAffected(identifier)
    return Api.IsItemAffected(identifier)
end


local function onHandleProjectileCollision(projectile, ptable)
    if not ptable.ReturnValue then return end
    if not NTConfig.Get("NTCRE_ConsentRequiredExtra", true) then return  end
    if not isItemAffected(projectile.Item.Prefab.Identifier.Value) then return end
    if projectile.User == nil then return end

    local target = ptable["target"]
    if target.Body == nil or target.Body.UserData == nil then return end
    local targetUserData = target.Body.UserData

    local targetUser = nil
    if LuaUserData.IsTargetType(targetUserData, "Barotrauma.Limb") then
        targetUser = targetUserData.character
    elseif LuaUserData.IsTargetType(targetUserData, "Barotrauma.Character") then
        targetUser = targetUserData
    end

    if targetUser ~= nil then
        Api.onAffectedItemApplied(projectile.User, targetUser)
    end
end

return onHandleProjectileCollision