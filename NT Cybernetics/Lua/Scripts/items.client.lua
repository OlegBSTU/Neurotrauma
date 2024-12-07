-- Allow the removal of cybernetics (limbs via crowbar, organs via surgery) from dead bodies (and other repair related tools needed for intact extraction)
NTCyb.AllowedNecromancyItems = {
	-- tools needed for cyberlimb repair and removal
	weldingtool = 1,
	steel = 1,
	fpgacircuit = 1,
	repairpack = 1,
	halligantool = 1,
	weldingtorch = 1,
	ekutility_metalfoam_gun = 1,
	ekutility_hullrepairkit = 1,
	ekutility_arcwelder = 1,
	tadementoniteweldingtool = 1,
	-- tools needed for cyberorgan removal
	advscalpel = 1,
	advhemostat = 1, -- optional (no blood to clamp!) but many will have muscle memory for it
	advretractors = 1,
	multiscalpel = 1,
	healthscanner = 1,
	-- Immersive Handcuffs compatibility
	handcuffkey = 1,
}
NTCyb.AllowedNecromancyItemsStartsWith = {
	crowbar = 1,
	screwdriver = 1,
	organscalpel = 1,
}

local function itemAllowsNecromancy(item)
	local identifier = item.Prefab.Identifier.Value
	if NTCyb.AllowedNecromancyItems[identifier] ~= nil then
		return true
	else
		for key,_ in pairs(NTCyb.AllowedNecromancyItemsStartsWith) do
			if HF.StartsWith(identifier,key) then
				return true
			end
		end
	end
	return false
end

LuaUserData.RegisterType('Barotrauma.Item+TreatmentEventData')
local TreatmentEventData = LuaUserData.CreateStatic('Barotrauma.Item+TreatmentEventData', true)
LuaUserData.MakeFieldAccessible(Descriptors['Barotrauma.CharacterHealth'], "selectedLimbIndex")

-- In vanilla, Dead characters cannot be interacted with in the Health UI.
-- This patch re-implements OnItemDropped() and its resulting call to item.ApplyTreatment(), which ultimately sends a TreatmentEventData to the server.
Hook.Patch("Barotrauma.CharacterHealth", "OnItemDropped", function (instance, ptable)
	if not instance.Character.IsDead then return end -- no necromancy required
	if ptable.ReturnValue == false then return end -- dropped outside of the health UI

	if not itemAllowsNecromancy(ptable["item"]) then return end

	local targetLimb = instance.Character.AnimController.MainLimb
	for _,v in pairs (instance.Character.AnimController.Limbs) do
		if v.HealthIndex == instance.selectedLimbIndex then
			targetLimb = v
			break
		end
	end
	Networking.CreateEntityEvent(ptable['item'], TreatmentEventData.__new(instance.Character, targetLimb))
end, Hook.HookMethodType.After)
