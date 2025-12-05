-- Do not take my blood or organs without my consent, thanks.
-- Causes AI to get angry at you if you use certain medical items on them.
-- These items are those related to organ and blood removal.
-- This mod is meant to be accompanied by Neurotrauma, and aims to
-- resolve the issue of being freely able to steal blood/organs from
-- neutral NPCs (e.g. outposts, VIPs) without them getting mad at you.
local Api = require("ConsentRequiredExtended.Api")
local OnItemApplied = require("ConsentRequiredExtended.OnItemApplied")
local onMeleeWeaponHandleImpact = require("ConsentRequiredExtended.onMeleeWeaponHandleImpact")
local onHandleProjectileCollision = require("ConsentRequiredExtended.onHandleProjectileCollision")
local Config = require("ConsentRequiredExtended.Config")

local LUA_EVENT_ITEM_APPLYTREATMENT = "item.ApplyTreatment"
local HOOK_NAME_ITEM_APPLYTREATMENT = "ConsentRequiredExtended.onItemApplyTreatment"

local LUA_EVENT_MELEEWEAPON_HANDLEIMPACT = "meleeWeapon.handleImpact"
local HOOK_NAME_MELEEWEAPON_HANDLEIMPACT = "ConsentRequiredExtended.onMeleeWeaponHandleImpact"

local LUA_EVENT_ROUNDSTART = "roundStart"
local HOOK_NAME_UPDATE_RESCUETARGETS = "ConsentRequiredExtended.onUpdateRescueTargets"

-- Set up affected items from config.
for _, affectedItem in pairs(Config.AffectedItems) do
	Api.AddAffectedItem(affectedItem)
end

Hook.Add(LUA_EVENT_ITEM_APPLYTREATMENT, HOOK_NAME_ITEM_APPLYTREATMENT, OnItemApplied)

-- damn meleeWeapon
Hook.Add(LUA_EVENT_MELEEWEAPON_HANDLEIMPACT, HOOK_NAME_MELEEWEAPON_HANDLEIMPACT, onMeleeWeaponHandleImpact)

Hook.Add(LUA_EVENT_ROUNDSTART, HOOK_NAME_UPDATE_RESCUETARGETS, Api.UpdateRescueTargets)

Hook.Patch('ConsentRequiredExtended.onandleProjectileCollision','Barotrauma.Items.Components.Projectile', 'HandleProjectileCollision', onHandleProjectileCollision, Hook.HookMethodType.After)