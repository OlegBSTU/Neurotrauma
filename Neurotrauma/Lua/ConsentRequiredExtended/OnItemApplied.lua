local Api = require "ConsentRequiredExtended.Api"

local function isItemAffected(identifier)
    return Api.IsItemAffected(identifier)
end

---@param item Barotrauma_Item Item being applied.
---@param user Barotrauma_Character The character that is applying the item.
---@param target Barotrauma_Character The character of the target of the item's application.
local function OnItemApplied(item, user, target)
    if not NTConfig.Get("NTCRE_ConsentRequired", true) then return end
    local itemIdentifier = item.Prefab.Identifier.Value
    if isItemAffected(itemIdentifier) then
        Api.onAffectedItemApplied(user, target)
    end
end

return OnItemApplied
