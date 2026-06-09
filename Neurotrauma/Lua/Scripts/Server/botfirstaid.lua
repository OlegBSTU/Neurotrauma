if Hook ~= nil and Hook.Remove ~= nil then
	pcall(function() Hook.Remove("think", "NT.BotFirstAid.Triage") end)
	pcall(function() Hook.Remove("roundStart", "NT.BotFirstAid.RoundStart") end)
	pcall(function() Hook.Remove("think", "NT.BotFirstAid.Assist") end)
	pcall(function() Hook.Remove("roundStart", "NT.BotFirstAid.AssistRoundStart") end)
end

NT.BotFirstAid = { State = { actionCooldowns = {}, botCooldowns = {}, procedures = {}, itemRequests = {}, itemObjectives = {}, itemFetches = {}, selfCareObjectives = {}, stabilizedCooldowns = {}, cpr = {} } }

local BFA = NT.BotFirstAid
local HumanAIControllerStatic = nil
if LuaUserData ~= nil and LuaUserData.CreateStatic ~= nil then
	pcall(function() HumanAIControllerStatic = LuaUserData.CreateStatic("Barotrauma.HumanAIController", true) end)
end
local forbiddenComplexMedicalIdentifiers = {
	aed = true,
	autocpr = true,
	bvm = true,
	defibrillator = true,
}
local AnimControllerAnimation = nil
if LuaUserData ~= nil then
	if LuaUserData.CreateEnumTable ~= nil then
		pcall(function() AnimControllerAnimation = LuaUserData.CreateEnumTable("Barotrauma.AnimController+Animation") end)
		if AnimControllerAnimation == nil then
			pcall(function() AnimControllerAnimation = LuaUserData.CreateEnumTable("Barotrauma.AnimController/Animation") end)
		end
	end
	if AnimControllerAnimation == nil and LuaUserData.CreateStatic ~= nil then
		pcall(function() AnimControllerAnimation = LuaUserData.CreateStatic("Barotrauma.AnimController+Animation", true) end)
	end
end
BFA.Settings = {
	assistIntervalTicks = 60,
	maxActionsPerTick = 3,
	maxOtherTreatmentDistance = 170,
	maxItemPickupDistance = 120,
	-- Slightly above one assist interval: smooths bot medical actions without
	-- slowing life-saving CPR, which explicitly bypasses these cooldowns.
	actionCooldownTicks = 90,
	botCooldownTicks = 90,
	selfBleedingThreshold = 2,
	selfWoundThreshold = 4,
	otherBleedingThreshold = 4,
	otherWoundThreshold = 6,
	fractureBandageThreshold = 35,
	dirtyBandageCleanupThreshold = 10,
	foreignBodyRemovalThreshold = 8,
	foreignBodyUrgentThreshold = 15,
	selfCareMinimumScore = 16,
	selfCareSevereScore = 45,
	otherCareMinimumScore = 25,
	nonMedicHelperMinimumScore = 60,
	quickCareMinimumScore = 45,
	highSkillMedicalThreshold = 45,
	missingResourceCooldownTicks = 1800,
	itemRequestCooldownTicks = 120,
	itemFetchTimeoutTicks = 5400,
	itemFetchTargetTimeoutTicks = 1800,
	stabilizedCooldownTicks = 900,
}

local function Log(message)
	if NT ~= nil and NT.TestingEnabled == true then print("[NT BotAid] " .. tostring(message)) end
end

local function TickCooldowns(tableRef)
	for key, value in pairs(tableRef) do
		value = value - BFA.Settings.assistIntervalTicks
		if value <= 0 then
			tableRef[key] = nil
		else
			tableRef[key] = value
		end
	end
end

local function CharacterKey(character)
	if character == nil then return "nil" end
	return tostring(character.ID or character.Name or character)
end

local function CooldownKey(character, key)
	return CharacterKey(character) .. ":" .. tostring(key)
end

local function HasCooldown(tableRef, key)
	return tableRef[key] ~= nil and tableRef[key] > 0
end

local function SetCooldown(tableRef, key, ticks)
	tableRef[key] = ticks
end

local function SafeProperty(value, propertyName, fallback)
	if value == nil then return fallback end
	local ok, result = pcall(function() return value[propertyName] end)
	if ok then return result end
	return fallback
end

local function IsBot(character)
	if character == nil then return false end
	local isBot = SafeProperty(character, "IsBot", nil)
	if isBot ~= nil then return isBot == true end
	return SafeProperty(character, "AIController", nil) ~= nil and SafeProperty(character, "IsPlayer", false) ~= true
end

local function IsCrewHuman(character)
	return character ~= nil
		and not character.Removed
		and character.IsHuman
		and not character.IsDead
		and (character.TeamID == 1 or character.TeamID == 2)
end

local function IsMedicalJob(character)
	local isMedic = SafeProperty(character, "IsMedic", nil)
	if isMedic ~= nil then return isMedic == true end

	local info = SafeProperty(character, "Info", nil)
	local job = info ~= nil and SafeProperty(info, "Job", nil) or nil
	local prefab = job ~= nil and SafeProperty(job, "Prefab", nil) or nil
	local identifier = prefab ~= nil and SafeProperty(prefab, "Identifier", nil) or nil
	local value = identifier ~= nil and SafeProperty(identifier, "Value", tostring(identifier)) or ""
	return value == "medicaldoctor" or value == "doctor" or value == "medic"
end

local function GetMedicalSkill(character)
	if HF ~= nil and HF.GetSkillLevel ~= nil then return HF.GetSkillLevel(character, "medical") end
	return IsMedicalJob(character) and 40 or 10
end

local function GetAffliction(character, identifier, fallback)
	if HF ~= nil and HF.GetAfflictionStrength ~= nil then return HF.GetAfflictionStrength(character, identifier, fallback or 0) end
	return fallback or 0
end

local function GetAfflictionLimb(character, limbType, identifier, fallback)
	if HF ~= nil and HF.GetAfflictionStrengthLimb ~= nil then
		return HF.GetAfflictionStrengthLimb(character, limbType, identifier, fallback or 0)
	end
	return fallback or 0
end

local function AddAffliction(character, identifier, amount, user)
	if HF ~= nil and HF.AddAffliction ~= nil then HF.AddAffliction(character, identifier, amount, user) end
end

local function ItemIdentifier(item)
	if item == nil or item.Prefab == nil or item.Prefab.Identifier == nil then return nil end
	return item.Prefab.Identifier.Value
end

local function ItemIdentifierString(item)
	local identifier = ItemIdentifier(item)
	if identifier ~= nil then return identifier end
	if item == nil or item.Prefab == nil or item.Prefab.Identifier == nil then return nil end
	return tostring(item.Prefab.Identifier)
end

local function IsDirectlyCarriedBy(character, item)
	if character == nil or item == nil or character.Inventory == nil then return false end
	local ok, parentInventory = pcall(function() return item.ParentInventory end)
	return ok and parentInventory == character.Inventory
end

local function ParentInventoryOwner(item)
	if item == nil then return nil end
	local ok, parentInventory = pcall(function() return item.ParentInventory end)
	if not ok or parentInventory == nil then return nil end

	local owner = nil
	pcall(function() owner = parentInventory.Owner end)
	return owner
end

local function FetchEntityWorldPosition(entity)
	if entity == nil then return nil end
	local position = SafeProperty(entity, "WorldPosition", nil)
	if position ~= nil then return position end
	return SafeProperty(entity, "worldPosition", nil)
end

local function FetchRootInventoryOwner(item)
	if item == nil then return nil end
	local owner = nil
	pcall(function() owner = item.GetRootInventoryOwner() end)
	if owner ~= nil then return owner end
	owner = ParentInventoryOwner(item)
	if owner ~= nil then return owner end
	return item
end

local function FetchEntityHull(entity)
	if entity == nil then return nil end
	return SafeProperty(entity, "CurrentHull", nil)
end

local function FetchEntitySubmarine(entity)
	if entity == nil then return nil end
	local submarine = SafeProperty(entity, "Submarine", nil)
	if submarine ~= nil then return submarine end

	local hull = FetchEntityHull(entity)
	if hull ~= nil then
		submarine = SafeProperty(hull, "Submarine", nil)
		if submarine ~= nil then return submarine end
	end

	return nil
end

local function FetchItemKey(item)
	if item == nil then return "nil" end
	local id = SafeProperty(item, "ID", nil)
	if id ~= nil then return tostring(id) end
	return tostring(item)
end

local function FetchDistanceScore(medic, target)
	local medicPos = FetchEntityWorldPosition(medic)
	local targetPos = FetchEntityWorldPosition(target)
	if medicPos == nil or targetPos == nil or Vector2 == nil then return 100000 end

	local ok, distance = pcall(function() return Vector2.Distance(medicPos, targetPos) end)
	if ok and type(distance) == "number" then return distance end
	return 100000
end

local function FetchCandidateScore(medic, item, rejectedTargets)
	if item == nil or item.Removed or item.Condition <= 0 then return nil end
	if rejectedTargets ~= nil and rejectedTargets[FetchItemKey(item)] == true then return nil end

	local owner = ParentInventoryOwner(item)
	if owner ~= nil and SafeProperty(owner, "IsHuman", false) then return nil end

	local root = FetchRootInventoryOwner(item)
	if root ~= nil and root ~= item and SafeProperty(root, "IsHuman", false) then return nil end

	local itemHull = FetchEntityHull(item)
	local rootHull = FetchEntityHull(root)
	local itemSubmarine = FetchEntitySubmarine(item)
	local rootSubmarine = FetchEntitySubmarine(root)
	local targetSubmarine = rootSubmarine or itemSubmarine

	if itemHull == nil and rootHull == nil and targetSubmarine == nil then return nil end

	if medic ~= nil then
		local medicSubmarine = FetchEntitySubmarine(medic)
		local medicHull = FetchEntityHull(medic)
		if medicSubmarine ~= nil and targetSubmarine ~= nil and targetSubmarine ~= medicSubmarine then return nil end
		if medicSubmarine ~= nil and targetSubmarine == nil and itemHull == nil and rootHull == nil then return nil end
		if medicHull ~= nil and itemHull == nil and rootHull == nil then return nil end
	end

	local score = FetchDistanceScore(medic, root or item)
	local medicHull = FetchEntityHull(medic)
	local targetHull = rootHull or itemHull
	if medicHull ~= nil and targetHull ~= nil and medicHull == targetHull then
		score = score - 5000
	elseif targetHull == nil then
		score = score + 5000
	end

	if root ~= nil and root ~= item then score = score + 150 end
	return score
end

local function FindAvailableWorldItem(identifier, medic, rejectedTargets)
	if Item == nil or Item.ItemList == nil or identifier == nil then return nil end

	local bestItem = nil
	local bestScore = nil
	for _, item in pairs(Item.ItemList) do
		if item ~= nil and not item.Removed and item.Condition > 0 and ItemIdentifierString(item) == identifier then
			local score = FetchCandidateScore(medic, item, rejectedTargets)
			if score ~= nil and (bestScore == nil or score < bestScore) then
				bestItem = item
				bestScore = score
			end
		end
	end

	return bestItem
end

local function ItemRequestKey(medic, identifiers)
	local suffix = ""
	if type(identifiers) == "table" then
		for _, identifier in ipairs(identifiers) do
			suffix = suffix .. tostring(identifier) .. "|"
		end
	else
		suffix = tostring(identifiers)
	end
	return CharacterKey(medic) .. ":getitem:" .. suffix
end

local function ClearMedicalItemFetch(fetchKey)
	local fetch = BFA.State.itemFetches[fetchKey]
	if fetch ~= nil and fetch.goTo ~= nil then
		pcall(function() fetch.goTo.Abandon = true end)
	end
	BFA.State.itemFetches[fetchKey] = nil
	BFA.State.itemObjectives[fetchKey] = nil
end

local function ClearSelfCareObjective(key)
	local objective = BFA.State.selfCareObjectives[key]
	if objective ~= nil then
		pcall(function() objective.Abandon = true end)
	end
	BFA.State.selfCareObjectives[key] = nil
end

local function ObjectiveIsUsable(objective)
	if objective == nil then return false end
	if SafeProperty(objective, "IsCompleted", false) == true then return false end
	if SafeProperty(objective, "Abandon", false) == true then return false end
	if SafeProperty(objective, "CanBeCompleted", true) == false then return false end
	return true
end

local function SelfCareObjectiveIsUsable(objective)
	if objective == nil then return false end
	if SafeProperty(objective, "IsCompleted", false) == true then return false end
	if SafeProperty(objective, "Abandon", false) == true then return false end
	return true
end

local function AddVanillaSelfCareObjective(bot, priorityModifier)
	if bot == nil or AIObjectiveRescueAll == nil then return false end
	local ai = SafeProperty(bot, "AIController", nil)
	local manager = ai ~= nil and SafeProperty(ai, "ObjectiveManager", nil) or nil
	if manager == nil then return false end
	local key = CharacterKey(bot)

	local existing = BFA.State.selfCareObjectives[key]
	if SelfCareObjectiveIsUsable(existing) then
		pcall(function()
			existing.ForceHighestPriority = true
			existing.OverridePriority = 80
			existing.SpeakIfFails = false
		end)
		return true
	end

	local ok, objective = pcall(function()
		return AIObjectiveRescueAll(bot, manager, priorityModifier or 1.25)
	end)
	if not ok or objective == nil then
		ok, objective = pcall(function()
			return AIObjectiveRescueAll.__new(bot, manager, priorityModifier or 1.25)
		end)
	end
	if not ok or objective == nil then return false end

	pcall(function()
		objective.ForceHighestPriority = true
		objective.OverridePriority = 80
		objective.SpeakIfFails = false
	end)

	local added = pcall(function() manager.AddObjective(objective) end) == true
	if added then
		BFA.State.selfCareObjectives[key] = objective
	end
	return added
end

BFA.EnsureSelfCareObjective = AddVanillaSelfCareObjective

local function RequestMedicalItem(medic, identifiers, priorityModifier, useVanillaSelfCare)
	if medic == nil or medic.Inventory == nil then return false end

	local fetchKey = CharacterKey(medic)
	if BFA.State.itemFetches[fetchKey] ~= nil then return true end

	local key = ItemRequestKey(medic, identifiers)
	SetCooldown(BFA.State.itemRequests, key, BFA.Settings.itemRequestCooldownTicks)

	if useVanillaSelfCare == true then AddVanillaSelfCareObjective(medic, 1.25) end

	local selectedIdentifier = nil
	local selectedItem = nil
	for _, identifier in ipairs(identifiers) do
		if not forbiddenComplexMedicalIdentifiers[identifier] then
			local item = FindAvailableWorldItem(identifier, medic, nil)
			if item ~= nil then
				selectedIdentifier = identifier
				selectedItem = item
				break
			end
		end
	end
	if selectedIdentifier == nil then
		Log(CharacterName(medic) .. " tried to fetch medical item, but no candidate exists on the submarine")
		return false
	end

	ClearMedicalItemFetch(fetchKey)
	pcall(function() medic.DeselectCharacter() end)
	pcall(function() medic.SelectedCharacter = nil end)
	BFA.State.itemFetches[fetchKey] = {
		identifiers = identifiers,
		selectedIdentifier = selectedIdentifier,
		targetItem = selectedItem,
		priorityModifier = priorityModifier or 8,
		selfCare = useVanillaSelfCare == true,
		timeout = BFA.Settings.itemFetchTimeoutTicks,
		targetTimeout = BFA.Settings.itemFetchTargetTimeoutTicks,
		rejectedTargets = {},
		takeFailures = 0,
	}
	Log(CharacterKey(medic) .. " started physical item fetch for " .. tostring(selectedIdentifier))
	return true
end

local function RefreshMedicalItemObjectives()
	for key, objective in pairs(BFA.State.itemObjectives) do
		if objective == nil then
			BFA.State.itemObjectives[key] = nil
		else
			local completed = SafeProperty(objective, "IsCompleted", false)
			local abandoned = SafeProperty(objective, "Abandon", false)
			local canComplete = SafeProperty(objective, "CanBeCompleted", true)
			if completed == true or abandoned == true or canComplete == false then
				BFA.State.itemObjectives[key] = nil
			else
				pcall(function() objective.ForceHighestPriority = true end)
				pcall(function() objective.Priority = 95 end)
			end
		end
	end
end

local function RefreshSelfCareObjectives()
	for key, objective in pairs(BFA.State.selfCareObjectives) do
		if not SelfCareObjectiveIsUsable(objective) then
			BFA.State.selfCareObjectives[key] = nil
		else
			pcall(function()
				objective.ForceHighestPriority = true
				objective.OverridePriority = 80
				objective.SpeakIfFails = false
			end)
		end
	end
end

local function LimbObject(character, limbType)
	if character == nil or character.AnimController == nil then return nil end
	return character.AnimController.GetLimb(limbType or LimbType.Torso)
end

local function Distance(a, b)
	if a == nil or b == nil then return 0 end
	if HF ~= nil and HF.Distance ~= nil then return HF.Distance(a, b) end
	return Vector2.Distance(a, b)
end

local limbTypes = {
	LimbType.Torso,
	LimbType.Head,
	LimbType.LeftArm,
	LimbType.RightArm,
	LimbType.LeftLeg,
	LimbType.RightLeg,
}

local function LimbKey(limbType)
	if limbType == LimbType.Torso then return "torso" end
	if limbType == LimbType.Head then return "head" end
	if limbType == LimbType.LeftArm then return "leftarm" end
	if limbType == LimbType.RightArm then return "rightarm" end
	if limbType == LimbType.LeftLeg then return "leftleg" end
	if limbType == LimbType.RightLeg then return "rightleg" end
	return tostring(limbType or "unknown")
end

local function CharacterName(character)
	return tostring(character ~= nil and (character.Name or character.DisplayName or character.ID) or "unknown")
end

local function LimbLabel(limbType)
	if limbType == LimbType.Torso then return "torso" end
	if limbType == LimbType.Head then return "head" end
	if limbType == LimbType.LeftArm then return "left arm" end
	if limbType == LimbType.RightArm then return "right arm" end
	if limbType == LimbType.LeftLeg then return "left leg" end
	if limbType == LimbType.RightLeg then return "right leg" end
	return tostring(limbType or "unknown limb")
end

local function ItemLabel(identifier)
	if identifier == "antibleeding1" or identifier == "bandage" then return "bandage" end
	if identifier == "antibleeding2" then return "plastiseal" end
	if identifier == "antibleeding3" then return "antibiotic glue" end
	if identifier == "suture" then return "suture" end
	if identifier == "gypsum" then return "cast" end
	if identifier == "tweezers" then return "tweezers" end
	if identifier == "traumashears" then return "trauma shears" end
	if identifier ~= nil and HF ~= nil and HF.StartsWith ~= nil and HF.StartsWith(identifier, "divingknife") then return "knife" end
	if identifier == "wrench" or identifier == "heavywrench" then return "wrench" end
	if identifier == "screwdriver" then return "screwdriver" end
	if identifier == "repairpack" then return "repair pack" end
	if identifier == "antibloodloss2" or identifier == "bloodpackominus" then return "blood bag O-" end
	if identifier ~= nil and HF ~= nil and HF.StartsWith ~= nil and HF.StartsWith(identifier, "bloodpack") then return "blood bag" end
	return tostring(identifier or "unknown item")
end

-- Sequential bot procedures live here. These are treatments that must preserve
-- a target and execute ordered steps, such as fracture care: bandage, then cast.
local SequentialProcedures = {}

local function ProcedureKey(medic, patient, procedureName)
	return CharacterKey(medic) .. ":" .. CharacterKey(patient) .. ":" .. tostring(procedureName)
end

local function GetProcedureState(medic, patient, procedureName)
	local key = ProcedureKey(medic, patient, procedureName)
	local state = BFA.State.procedures[key]
	if state == nil then
		state = {}
		BFA.State.procedures[key] = state
	end
	return state
end

local function ClearProcedureState(medic, patient, procedureName)
	BFA.State.procedures[ProcedureKey(medic, patient, procedureName)] = nil
end

local function MissingResourceKey(patient, procedureName, limbType, itemIdentifier)
	return CharacterKey(patient)
		.. ":missing:"
		.. tostring(procedureName)
		.. ":"
		.. LimbKey(limbType)
		.. ":"
		.. tostring(itemIdentifier)
end

local function HasMissingResource(patient, procedureName, limbType, itemIdentifier)
	return HasCooldown(BFA.State.actionCooldowns, MissingResourceKey(patient, procedureName, limbType, itemIdentifier))
end

local function MarkMissingResource(patient, procedureName, limbType, itemIdentifier)
	SetCooldown(
		BFA.State.actionCooldowns,
		MissingResourceKey(patient, procedureName, limbType, itemIdentifier),
		BFA.Settings.missingResourceCooldownTicks
	)
end

local BloodLossValue
local NeedsResuscitation

local function LimbIsExtremity(limbType)
	if HF ~= nil and HF.LimbIsExtremity ~= nil then return HF.LimbIsExtremity(limbType) end
	return limbType == LimbType.LeftArm
		or limbType == LimbType.RightArm
		or limbType == LimbType.LeftLeg
		or limbType == LimbType.RightLeg
end

local function LimbIsBroken(patient, limbType)
	if NT ~= nil and NT.LimbIsBroken ~= nil then return NT.LimbIsBroken(patient, limbType) end
	return false
end

local function LimbIsDislocated(patient, limbType)
	if NT ~= nil and NT.LimbIsDislocated ~= nil then return NT.LimbIsDislocated(patient, limbType) end
	return false
end

local function DislocationIdentifier(limbType)
	if limbType == LimbType.RightLeg then return "dislocation1" end
	if limbType == LimbType.LeftLeg then return "dislocation2" end
	if limbType == LimbType.RightArm then return "dislocation3" end
	if limbType == LimbType.LeftArm then return "dislocation4" end
	return nil
end

local function ArterialCutIdentifier(limbType)
	if limbType == LimbType.Torso then return "t_arterialcut" end
	if limbType == LimbType.Head then return "h_arterialcut" end
	if limbType == LimbType.LeftArm then return "la_arterialcut" end
	if limbType == LimbType.RightArm then return "ra_arterialcut" end
	if limbType == LimbType.LeftLeg then return "ll_arterialcut" end
	if limbType == LimbType.RightLeg then return "rl_arterialcut" end
	return nil
end

local function GetArterialCut(patient, limbType)
	local identifier = ArterialCutIdentifier(limbType)
	if identifier == nil then return 0 end

	local limbValue = GetAfflictionLimb(patient, limbType, identifier, 0)
	local bodyValue = GetAffliction(patient, identifier, 0)
	return math.max(limbValue, bodyValue)
end

local function GetSurgerySkill(medic)
	if HF ~= nil and HF.GetSurgerySkill ~= nil then
		local ok, result = pcall(function() return HF.GetSurgerySkill(medic) end)
		if ok and result ~= nil then return result end
	end
	return GetMedicalSkill(medic)
end

local function HasSurgerySkill(medic, required)
	if HF ~= nil and HF.GetSurgerySkillRequirementMet ~= nil then
		local ok, result = pcall(function() return HF.GetSurgerySkillRequirementMet(medic, required) end)
		if ok then return result == true end
	end
	return GetSurgerySkill(medic) >= required
end

local function DislocationSkillRequired(patient)
	if GetAffliction(patient, "analgesia", 0) > 0.5 or GetAffliction(patient, "afadrenaline", 0) > 0.5 then
		return 30
	end
	return 60
end

local function BotCanRelocateDislocation(medic, patient)
	local medicalSkill = GetMedicalSkill(medic)
	if IsMedicalJob(medic) then return true end
	if medicalSkill >= DislocationSkillRequired(patient) then return true end
	return false
end

local function FindDislocatedLimb(patient)
	local bestLimbType = nil
	local bestScore = 0
	for _, limbType in ipairs(limbTypes) do
		if LimbIsExtremity(limbType)
			and LimbIsDislocated(patient, limbType)
			and not HasMissingResource(patient, "dislocation", limbType, "relocator")
		then
			local score = 100
				+ GetAfflictionLimb(patient, limbType, "blunttrauma", 0)
				+ GetAfflictionLimb(patient, limbType, "pain", 0)
			if score > bestScore then
				bestScore = score
				bestLimbType = limbType
			end
		end
	end

	if bestLimbType == nil then return nil, nil end
	return LimbObject(patient, bestLimbType), bestLimbType
end

local function FindFractureLimb(patient, needsBandage, preferredLimbKey)
	local bestLimbType = nil
	local bestScore = 0
	for _, limbType in ipairs(limbTypes) do
		if LimbIsExtremity(limbType)
			and LimbIsBroken(patient, limbType)
			and GetAfflictionLimb(patient, limbType, "gypsumcast", 0) <= 0.1
			and GetAfflictionLimb(patient, limbType, "surgeryincision", 0) <= 1
			and not HasMissingResource(patient, "fracture_cast", limbType, "gypsum")
		then
			local bandaged = GetAfflictionLimb(patient, limbType, "bandaged", 0)
			local prepared = bandaged >= BFA.Settings.fractureBandageThreshold
			if prepared ~= needsBandage then
				local score = 100
					+ GetAfflictionLimb(patient, limbType, "blunttrauma", 0)
					+ bandaged
				if preferredLimbKey ~= nil and LimbKey(limbType) == preferredLimbKey then
					score = score + 10000
				end
				if score > bestScore then
					bestScore = score
					bestLimbType = limbType
				end
			end
		end
	end

	if bestLimbType == nil then return nil, nil end
	return LimbObject(patient, bestLimbType), bestLimbType
end

local function FindInventoryItem(character, identifiers)
	if character == nil or character.Inventory == nil or character.Inventory.AllItems == nil or identifiers == nil then return nil end
	for item in character.Inventory.AllItems do
		local identifier = ItemIdentifier(item)
		if item ~= nil and not item.Removed and item.Condition > 0 and IsDirectlyCarriedBy(character, item) then
			for _, candidate in ipairs(identifiers) do
				if identifier == candidate then return item end
			end
		end
	end
	return nil
end

local function FindRequestedInventoryItem(character, identifiers)
	return FindInventoryItem(character, identifiers)
end

local function IsFetchTargetValid(item)
	if item == nil or item.Removed or item.Condition <= 0 then return false end
	local owner = ParentInventoryOwner(item)
	if owner ~= nil and SafeProperty(owner, "IsHuman", false) then return false end
	return true
end

local function RejectFetchTarget(fetch, item, reason)
	if fetch == nil or item == nil then return end
	fetch.rejectedTargets = fetch.rejectedTargets or {}
	fetch.rejectedTargets[FetchItemKey(item)] = true
	fetch.targetItem = nil
	fetch.goTo = nil
	fetch.takeFailures = 0
	fetch.targetTimeout = BFA.Settings.itemFetchTargetTimeoutTicks
	Log("rejecting fetch target (" .. tostring(reason or "no reason") .. "): " .. ItemLabel(fetch.selectedIdentifier))
end

local function RefreshFetchTarget(fetch, medic)
	if fetch == nil or fetch.identifiers == nil then return nil, nil end
	if IsFetchTargetValid(fetch.targetItem)
		and FetchCandidateScore(medic, fetch.targetItem, fetch.rejectedTargets) ~= nil
	then
		return fetch.targetItem, fetch.selectedIdentifier
	end

	for _, identifier in ipairs(fetch.identifiers) do
		local item = FindAvailableWorldItem(identifier, medic, fetch.rejectedTargets)
		if item ~= nil then
			fetch.targetItem = item
			fetch.selectedIdentifier = identifier
			fetch.goTo = nil
			fetch.takeFailures = 0
			fetch.targetTimeout = BFA.Settings.itemFetchTargetTimeoutTicks
			return item, identifier
		end
	end

	return nil, nil
end

local function FetchTargetSameHull(medic, item, moveTarget)
	local medicHull = SafeProperty(medic, "CurrentHull", nil)
	if medicHull == nil then return true end

	local moveHull = SafeProperty(moveTarget, "CurrentHull", nil)
	if moveHull ~= nil then return moveHull == medicHull end

	local itemHull = SafeProperty(item, "CurrentHull", nil)
	if itemHull ~= nil then return itemHull == medicHull end

	return true
end

local function IsFetchTargetCloseEnough(medic, item, moveTarget)
	if medic == nil or item == nil then return false end
	local medicPos = FetchEntityWorldPosition(medic)
	local targetPos = FetchEntityWorldPosition(moveTarget) or FetchEntityWorldPosition(item)
	if medicPos == nil or targetPos == nil then return false end
	if Distance(medicPos, targetPos) > BFA.Settings.maxItemPickupDistance then return false end
	return FetchTargetSameHull(medic, item, moveTarget)
end

local function CanInteractWithFetchTarget(medic, item)
	local moveTarget = FetchRootInventoryOwner(item)
	if moveTarget == nil then return false, nil end
	if not IsFetchTargetCloseEnough(medic, item, moveTarget) then return false, moveTarget end

	local canInteract = false
	if moveTarget == medic then
		canInteract = true
	elseif SafeProperty(moveTarget, "IsHuman", false) then
		pcall(function()
			medic.SelectCharacter(moveTarget)
			canInteract = medic.CanInteractWith(moveTarget)
			medic.DeselectCharacter()
		end)
	else
		pcall(function() canInteract = medic.CanInteractWith(moveTarget, false) end)
	end

	if not canInteract and moveTarget ~= item then
		pcall(function() canInteract = medic.CanInteractWith(item, false) end)
	end

	return canInteract == true, moveTarget
end

local function TryTakeNearbyItem(medic, item)
	if medic == nil or medic.Inventory == nil or item == nil then return false end

	local takeItem = nil
	if HumanAIControllerStatic ~= nil then
		pcall(function() takeItem = HumanAIControllerStatic.TakeItem end)
	end
	if takeItem ~= nil then
		-- equip into hands
		local ok, taken = pcall(function()
			return takeItem(item, medic.Inventory, true, false, true)
		end)
		if ok and taken == true then return true end

		-- store without equipping, hands-only slot still
		ok, taken = pcall(function()
			return takeItem(item, medic.Inventory, false, false, true)
		end)
		if ok and taken == true then return true end

		-- any slot, not hands-only (helps when hands are occupied)
		ok, taken = pcall(function()
			return takeItem(item, medic.Inventory, false, false, false)
		end)
		if ok and taken == true then return true end
	end

	local ok, taken = pcall(function()
		return medic.Inventory.TryPutItem(item, nil, { InvSlotType.Any }, true, true, medic, true, true)
	end)
	if ok and taken == true then return true end

	ok, taken = pcall(function()
		return medic.Inventory.TryPutItem(item, nil, { InvSlotType.Any })
	end)
	if ok and taken == true then return true end

	-- Last resort: force-remove the item from its container then retry.
	-- This generalises the wrench-specific workaround to all medical items that
	-- may be stuck in a locked container slot (e.g. surgery cabinet, med bag).
	local parentInventory = nil
	pcall(function() parentInventory = item.ParentInventory end)
	if parentInventory ~= nil and parentInventory ~= medic.Inventory then
		local slot = nil
		pcall(function() slot = parentInventory.FindIndex(item) end)
		if slot ~= nil and slot >= 0 then
			local removed = false
			pcall(function()
				parentInventory.ForceRemoveFromSlot(item, slot)
				removed = true
			end)
			if removed then
				ok, taken = pcall(function()
					return medic.Inventory.TryPutItem(item, nil, { InvSlotType.Any }, true, true, medic, true, true)
				end)
				if ok and taken == true then return true end
				ok, taken = pcall(function()
					return medic.Inventory.TryPutItem(item, nil, { InvSlotType.Any })
				end)
				if ok and taken == true then return true end
				-- Failed even after force-remove — put back where it was
				pcall(function() parentInventory.TryPutItem(item, nil, { slot }, true, true) end)
			end
		end
	end

	return false
end

local function EnsureFetchGoToObjective(medic, fetch, moveTarget)
	if medic == nil or fetch == nil or moveTarget == nil or AIObjectiveGoTo == nil then return false end
	local ai = SafeProperty(medic, "AIController", nil)
	local manager = ai ~= nil and SafeProperty(ai, "ObjectiveManager", nil) or nil
	if manager == nil then return false end

	local objective = fetch.goTo
	if objective ~= nil then
		local completed = SafeProperty(objective, "IsCompleted", false)
		local abandoned = SafeProperty(objective, "Abandon", false)
		local canComplete = SafeProperty(objective, "CanBeCompleted", true)
		if completed == true or abandoned == true or canComplete == false then
			fetch.goTo = nil
		else
			pcall(function() objective.ForceHighestPriority = true end)
			pcall(function() objective.OverridePriority = fetch.selfCare and 85 or 95 end)
			return true
		end
	end

	local priorityModifier = fetch.priorityModifier or 8
	local ok, newObjective = pcall(function()
		return AIObjectiveGoTo(moveTarget, medic, manager, false, true, priorityModifier, 95)
	end)
	if not ok or newObjective == nil then
		ok, newObjective = pcall(function()
			return AIObjectiveGoTo.__new(moveTarget, medic, manager, false, true, priorityModifier, 95)
		end)
	end
	if not ok or newObjective == nil then return false end

	pcall(function()
		newObjective.ForceHighestPriority = true
		newObjective.OverridePriority = fetch.selfCare and 85 or 95
		newObjective.SpeakIfFails = false
		newObjective.DebugLogWhenFails = false
	end)

	local added = pcall(function() manager.AddObjective(newObjective) end)
	if added then
		fetch.goTo = newObjective
		BFA.State.itemObjectives[CharacterKey(medic)] = newObjective
	end
	return added == true
end

local function ProcessMedicalItemFetch(medic)
	if medic == nil or medic.Inventory == nil then return false end

	local fetchKey = CharacterKey(medic)
	local fetch = BFA.State.itemFetches[fetchKey]
	if fetch == nil then return false end

	-- Medics and high-skill bots abort non-self-care fetches when any teammate
	-- is in cardiac or respiratory arrest — resuscitation takes absolute priority.
	if not fetch.selfCare
		and (IsMedicalJob(medic) or GetMedicalSkill(medic) >= BFA.Settings.highSkillMedicalThreshold)
		and Character ~= nil and Character.CharacterList ~= nil
	then
		for _, candidate in pairs(Character.CharacterList) do
			if IsCrewHuman(candidate)
				and candidate.TeamID == medic.TeamID
				and NeedsResuscitation(candidate)
			then
				Log(CharacterName(medic) .. " aborted item fetch: cardiac/respiratory arrest on team")
				ClearMedicalItemFetch(fetchKey)
				return false
			end
		end
	end

	fetch.timeout = (fetch.timeout or BFA.Settings.itemFetchTimeoutTicks) - BFA.Settings.assistIntervalTicks
	if fetch.timeout <= 0 then
		Log(CharacterName(medic) .. " gave up fetching " .. ItemLabel(fetch.selectedIdentifier) .. ": timed out")
		ClearMedicalItemFetch(fetchKey)
		return false
	end

	fetch.targetTimeout = (fetch.targetTimeout or BFA.Settings.itemFetchTargetTimeoutTicks) - BFA.Settings.assistIntervalTicks
	if fetch.targetTimeout <= 0 and fetch.targetItem ~= nil then
		RejectFetchTarget(fetch, fetch.targetItem, "target stalled")
	end

	if FindRequestedInventoryItem(medic, fetch.identifiers) ~= nil then
		Log(CharacterName(medic) .. " already has " .. ItemLabel(fetch.selectedIdentifier) .. " in inventory; ending fetch")
		ClearMedicalItemFetch(fetchKey)
		return false
	end

	local item, identifier = RefreshFetchTarget(fetch, medic)
	if item == nil then
		Log(CharacterName(medic) .. " gave up fetching medical item: target no longer exists")
		ClearMedicalItemFetch(fetchKey)
		return false
	end

	local canInteract, moveTarget = CanInteractWithFetchTarget(medic, item)
	if canInteract then
		if TryTakeNearbyItem(medic, item) then
			Log(CharacterName(medic) .. " physically took " .. ItemLabel(identifier))
			ClearMedicalItemFetch(fetchKey)
			return false
		end
		fetch.takeFailures = (fetch.takeFailures or 0) + 1
		if fetch.takeFailures >= 3 then
			RejectFetchTarget(fetch, item, "take failed")
		else
			-- Keep the bot anchored at the container while retrying. Without this,
			-- vanilla objectives walk the bot back to the patient and create a
			-- cabinet ↔ patient loop on every tick.
			EnsureFetchGoToObjective(medic, fetch, moveTarget)
		end
		return true
	end

	if EnsureFetchGoToObjective(medic, fetch, moveTarget) then return true end
	RejectFetchTarget(fetch, item, "no path")
	local nextItem = RefreshFetchTarget(fetch, medic)
	if nextItem == nil then
		Log(CharacterName(medic) .. " found no path to any accessible " .. ItemLabel(identifier))
		ClearMedicalItemFetch(fetchKey)
		return false
	end
	Log(CharacterName(medic) .. " switched fetch target to another " .. ItemLabel(identifier))
	return true
end

function BFA.IsFetchingMedicalItem(medic)
	return medic ~= nil and BFA.State.itemFetches[CharacterKey(medic)] ~= nil
end

local function IsBandageItem(item)
	local identifier = ItemIdentifier(item)
	return identifier == "antibleeding1"
		or identifier == "bandage"
		or identifier == "antibleeding2"
		or identifier == "antibleeding3"
end

local function IsBotMedicalHeldItem(item)
	local identifier = ItemIdentifier(item)
	if identifier == nil then return false end
	return IsBandageItem(item)
		or identifier == "suture"
		or identifier == "gypsum"
		or identifier == "wrench"
		or identifier == "heavywrench"
		or identifier == "repairpack"
		or identifier == "screwdriver"
		or identifier == "antibloodloss2"
		or identifier == "bloodpackominus"
		or identifier == "tweezers"
		or identifier == "traumashears"
		or identifier == "divingknife"
		or identifier == "aed"
		or identifier == "autocpr"
		or identifier == "bvm"
		or identifier == "defibrillator"
		or (HF ~= nil and HF.StartsWith ~= nil and HF.StartsWith(identifier, "bloodpack"))
		or (HF ~= nil and HF.StartsWith ~= nil and HF.StartsWith(identifier, "divingknife"))
end

local complexMedicalEquipment = forbiddenComplexMedicalIdentifiers

local function IsComplexMedicalEquipment(item)
	local identifier = ItemIdentifier(item)
	return identifier ~= nil and complexMedicalEquipment[identifier] == true
end

local function BotCanUseComplexMedicalEquipment(medic, patient, item)
	if not IsComplexMedicalEquipment(item) then return true end
	return false
end

local function StowForbiddenComplexMedicalEquipment(bot)
	if bot == nil or bot.Inventory == nil then return end
	if HF == nil or HF.GetItemInRightHand == nil or HF.GetItemInLeftHand == nil then return end

	local heldItems = { HF.GetItemInRightHand(bot), HF.GetItemInLeftHand(bot) }
	for index = 1, 2 do
		local item = heldItems[index]
		if item ~= nil and IsComplexMedicalEquipment(item) and IsDirectlyCarriedBy(bot, item) then
			local stowed = false
			pcall(function() stowed = bot.Inventory.TryPutItem(item, nil, { InvSlotType.Any }) end)
			if not stowed then
				pcall(function() item.Drop(bot, true) end)
			end
		end
	end
end

-- Tools that non-medics borrow temporarily and should drop after use.
-- Consumables (bandage, suture, gypsum, blood packs) and repair-multipurpose
-- tools (wrench) are excluded — they are either spent or legitimately kept.
local borrowedSpecialtyTools = {
	tweezers = true,
	traumashears = true,
}

local function ReturnBorrowedSpecialtyTools(bot)
	if bot == nil or bot.Inventory == nil or bot.Inventory.AllItems == nil then return end
	if IsMedicalJob(bot) then return end
	for item in bot.Inventory.AllItems do
		if item ~= nil and not item.Removed and item.Condition > 0 and IsDirectlyCarriedBy(bot, item) then
			if borrowedSpecialtyTools[ItemIdentifier(item) or ""] == true then
				pcall(function() item.Drop(bot, true) end)
				Log(CharacterName(bot) .. " returned " .. ItemLabel(ItemIdentifier(item)))
			end
		end
	end
end

local function StowHeldMedicalItems(medic)
	if medic == nil or medic.Inventory == nil then return end
	if HF == nil or HF.GetItemInRightHand == nil or HF.GetItemInLeftHand == nil then return end

	local rightHand = HF.GetItemInRightHand(medic)
	local leftHand = HF.GetItemInLeftHand(medic)
	local heldItems = { rightHand, leftHand }
	for index = 1, 2 do
		local item = heldItems[index]
		if item ~= nil and IsBotMedicalHeldItem(item) and IsDirectlyCarriedBy(medic, item) then
			local stowed = false
			pcall(function() stowed = medic.Inventory.TryPutItem(item, nil, { InvSlotType.Any }) end)
			if not stowed then
				pcall(function() item.Drop(medic, true) end)
			end
		end
	end
end

local function ApplyItem(item, medic, patient, limb)
	if item == nil or medic == nil or patient == nil or limb == nil or NT == nil then return false end
	if IsBot(medic) and not BotCanUseComplexMedicalEquipment(medic, patient, item) then return false end
	local identifier = ItemIdentifier(item)
	if identifier == nil then return false end
	local limbType = HF ~= nil and HF.NormalizeLimbType ~= nil and HF.NormalizeLimbType(limb.type) or limb.type
	local actionDescription = CharacterName(medic)
		.. " used "
		.. ItemLabel(identifier)
		.. " on "
		.. CharacterName(patient)
		.. " ("
		.. LimbLabel(limbType)
		.. ")"

	if NT.ItemMethods ~= nil and NT.ItemMethods[identifier] ~= nil then
		local ok, result = pcall(function()
			return NT.ItemMethods[identifier](item, medic, patient, limb)
		end)
		if ok and result ~= false and identifier == "suture" and HF ~= nil and HF.RemoveItem ~= nil then
			HF.RemoveItem(item)
		end
		Log(actionDescription .. (ok and result ~= false and " [ok]" or " [failed]"))
		return ok and result ~= false
	end

	if NT.ItemStartsWithMethods ~= nil then
		for prefix, method in pairs(NT.ItemStartsWithMethods) do
			if HF ~= nil and HF.StartsWith ~= nil and HF.StartsWith(identifier, prefix) then
				local ok, result = pcall(function()
					return method(item, medic, patient, limb)
				end)
				Log(actionDescription .. (ok and result ~= false and " [ok]" or " [failed]"))
				return ok and result ~= false
			end
		end
	end

	Log(actionDescription .. " [no Lua method]")
	return false
end

local function LimbInjuryScore(patient, limbType)
	local bleeding = GetAfflictionLimb(patient, limbType, "bleeding", 0)
	local nonstop = GetAfflictionLimb(patient, limbType, "bleedingnonstop", 0)
	local bandaged = GetAfflictionLimb(patient, limbType, "bandaged", 0)
	local sutured = GetAfflictionLimb(patient, limbType, "suturedw", 0)
	local dirtyBandage = GetAfflictionLimb(patient, limbType, "dirtybandage", 0)
	local tourniquet = GetAfflictionLimb(patient, limbType, "arteriesclamp", 0)
	local foreignBody = GetAfflictionLimb(patient, limbType, "foreignbody", 0)

	if nonstop <= 0.1 and bandaged >= 50 and bleeding <= 5 then
		bleeding = 0
	elseif nonstop <= 0.1 and bandaged >= 25 and bleeding <= 2 then
		bleeding = 0
	end

	local woundScore = GetAfflictionLimb(patient, limbType, "gunshotwound", 0) * 4
		+ GetAfflictionLimb(patient, limbType, "lacerations", 0) * 3
		+ GetAfflictionLimb(patient, limbType, "bitewounds", 0) * 3
		+ GetAfflictionLimb(patient, limbType, "explosiondamage", 0) * 3

	if bleeding <= 0.1 and nonstop <= 0.1 and (bandaged > 0.1 or sutured > 0.1) then
		woundScore = 0
	end

	local maintenanceScore = 0
	if dirtyBandage >= BFA.Settings.dirtyBandageCleanupThreshold and bleeding <= 5 and nonstop <= 0.1 then
		maintenanceScore = maintenanceScore + 18 + dirtyBandage
	end
	if tourniquet > 0.1 and GetArterialCut(patient, limbType) <= 0.1 and bleeding <= 5 and nonstop <= 0.1 then
		maintenanceScore = maintenanceScore + 35
	end
	if foreignBody >= BFA.Settings.foreignBodyRemovalThreshold then
		local woundOpen = GetAfflictionLimb(patient, limbType, "gunshotwound", 0) >= 1
			or GetAfflictionLimb(patient, limbType, "explosiondamage", 0) >= 1
			or GetAfflictionLimb(patient, limbType, "retractedskin", 0) >= 99
		if woundOpen and nonstop <= 0.1 and bleeding <= 15 then
			maintenanceScore = maintenanceScore + 12 + foreignBody * 2
			if foreignBody >= BFA.Settings.foreignBodyUrgentThreshold then
				maintenanceScore = maintenanceScore + 20
			end
		end
	end

	local boneScore = 0
	if LimbIsExtremity(limbType) then
		if LimbIsBroken(patient, limbType)
			and GetAfflictionLimb(patient, limbType, "gypsumcast", 0) <= 0.1
			and not HasMissingResource(patient, "fracture_cast", limbType, "gypsum")
		then
			boneScore = boneScore + 35
			if GetAfflictionLimb(patient, limbType, "bandaged", 0) >= BFA.Settings.fractureBandageThreshold then
				boneScore = boneScore + 12
			end
		end
		if LimbIsDislocated(patient, limbType) and not HasMissingResource(patient, "dislocation", limbType, "relocator") then
			boneScore = boneScore + 28
		end
	end

	return nonstop * 50 + bleeding * 3 + woundScore + boneScore + maintenanceScore
end

local function FindWorstTreatableLimb(patient)
	local bestLimbType = nil
	local bestScore = 0
	for _, limbType in ipairs(limbTypes) do
		local score = LimbInjuryScore(patient, limbType)
		if score > bestScore then
			bestScore = score
			bestLimbType = limbType
		end
	end

	if bestLimbType == nil or bestScore <= 0 then return nil, 0 end
	return LimbObject(patient, bestLimbType), bestScore
end

local function PatientTreatmentScore(character)
	if character == nil then return 0 end
	local score = GetAffliction(character, "bloodloss", 0)
		+ GetAffliction(character, "oxygenlow", 0)
		+ GetAffliction(character, "hypoxemia", 0)
		+ GetAffliction(character, "cardiacarrest", 0) * 100
		+ GetAffliction(character, "respiratoryarrest", 0) * 90

	for _, limbType in ipairs(limbTypes) do
		score = score + LimbInjuryScore(character, limbType)
	end

	return score
end

local function PatientIsIncapacitated(character)
	if character == nil then return false end
	if SafeProperty(character, "IsIncapacitated", false) == true then return true end
	if SafeProperty(character, "IsUnconscious", false) == true then return true end
	return GetAffliction(character, "sym_unconsciousness", 0) > 0.1
		or GetAffliction(character, "stun", 0) > 1
end

local function NeedsWoundClosure(patient, limbType)
	if GetAfflictionLimb(patient, limbType, "suturedw", 0) > 0.1 then return false end
	return GetAfflictionLimb(patient, limbType, "gunshotwound", 0) > 0.1
		or GetAfflictionLimb(patient, limbType, "lacerations", 0) > 0.1
		or GetAfflictionLimb(patient, limbType, "bitewounds", 0) > 0.1
		or GetAfflictionLimb(patient, limbType, "explosiondamage", 0) > 0.1
		or GetAfflictionLimb(patient, limbType, "bleedingnonstop", 0) > 0.1
end

local function NeedsBleedingControl(patient, limbType)
	local bleeding = GetAfflictionLimb(patient, limbType, "bleeding", 0)
	local nonstop = GetAfflictionLimb(patient, limbType, "bleedingnonstop", 0)
	local bandaged = GetAfflictionLimb(patient, limbType, "bandaged", 0)

	-- At 50 %+ coverage with no continuous bleed the wound is managed; remaining
	-- bleeding will decay on its own. Previously required bleeding <= 5 here,
	-- which caused bots to stack bandages when bleeding was still 6-15 post-wrap.
	if bandaged >= 50 and nonstop <= 0.1 then return false end
	if bandaged >= 25 and bleeding <= 5 and nonstop <= 0.1 then return false end
	if bandaged > 0.1 and bleeding <= 0.1 and nonstop <= 0.1 then return false end

	return bleeding > 0.1 or nonstop > 0.1
end

local function PatientNeedsBandage(patient)
	for _, limbType in ipairs(limbTypes) do
		if NeedsBleedingControl(patient, limbType) then return true end
		if LimbIsExtremity(limbType)
			and LimbIsBroken(patient, limbType)
			and GetAfflictionLimb(patient, limbType, "gypsumcast", 0) <= 0.1
			and GetAfflictionLimb(patient, limbType, "surgeryincision", 0) <= 1
			and not HasMissingResource(patient, "fracture_cast", limbType, "gypsum")
			and GetAfflictionLimb(patient, limbType, "bandaged", 0) < BFA.Settings.fractureBandageThreshold
		then
			return true
		end
	end
	return false
end

local function PatientHasPendingBoneCare(patient)
	for _, limbType in ipairs(limbTypes) do
		if LimbIsExtremity(limbType) then
			if LimbIsDislocated(patient, limbType) then return true end
			if LimbIsBroken(patient, limbType)
				and GetAfflictionLimb(patient, limbType, "gypsumcast", 0) <= 0.1
				and not HasMissingResource(patient, "fracture_cast", limbType, "gypsum")
			then
				return true
			end
		end
	end
	return false
end

local function PatientFunctionalBoneScore(patient)
	local score = 0
	local affectedLimbs = 0
	for _, limbType in ipairs(limbTypes) do
		if LimbIsExtremity(limbType) then
			local limbAffected = false
			if LimbIsBroken(patient, limbType)
				and GetAfflictionLimb(patient, limbType, "gypsumcast", 0) <= 0.1
				and not HasMissingResource(patient, "fracture_cast", limbType, "gypsum")
			then
				score = score + 45
				limbAffected = true
			end
			if LimbIsDislocated(patient, limbType)
				and not HasMissingResource(patient, "dislocation", limbType, "relocator")
			then
				score = score + 35
				limbAffected = true
			end
			if limbAffected then affectedLimbs = affectedLimbs + 1 end
		end
	end

	if affectedLimbs >= 2 then score = score + 35 end
	if affectedLimbs >= 3 then score = score + 35 end
	return score
end

local function PatientNeedsFunctionalBoneCare(patient)
	return PatientFunctionalBoneScore(patient) > 0
end

local function StowStaleHeldBandage(medic, patient)
	if medic == nil or patient == nil or medic.Inventory == nil then return end
	if PatientNeedsBandage(patient) then return end
	if HF == nil or HF.GetItemInRightHand == nil or HF.GetItemInLeftHand == nil then return end

	local rightHand = HF.GetItemInRightHand(medic)
	local leftHand = HF.GetItemInLeftHand(medic)
	local heldItems = { rightHand, leftHand }
	for index = 1, 2 do
		local item = heldItems[index]
		if item ~= nil and IsBandageItem(item) and IsDirectlyCarriedBy(medic, item) then
			pcall(function() medic.Inventory.TryPutItem(item, nil, { InvSlotType.Any }) end)
		end
	end
end

local function NeedsFractureSplint(patient, limbType)
	if not LimbIsExtremity(limbType) or not LimbIsBroken(patient, limbType) then return false end
	if GetAfflictionLimb(patient, limbType, "gypsumcast", 0) > 0.1 then return false end
	if GetAfflictionLimb(patient, limbType, "surgeryincision", 0) > 1 then return false end
	if HasMissingResource(patient, "fracture_cast", limbType, "gypsum") then return false end
	return true
end

local function PatientNeedsFractureCast(patient)
	for _, limbType in ipairs(limbTypes) do
		if NeedsFractureSplint(patient, limbType) then return true end
	end
	return false
end

local function SelectFractureItem(medic, patient, limbType)
	if not NeedsFractureSplint(patient, limbType) then return nil end

	if GetAfflictionLimb(patient, limbType, "bandaged", 0) < BFA.Settings.fractureBandageThreshold then
		return FindInventoryItem(medic, { "antibleeding1", "antibleeding2" })
	end

	return FindInventoryItem(medic, { "gypsum" })
end

local function ApplyGypsumCastForBot(gypsum, medic, patient, limb, limbType)
	if gypsum == nil or limb == nil or limbType == nil then return false end
	if not NeedsFractureSplint(patient, limbType) then return false end
	if GetAfflictionLimb(patient, limbType, "bandaged", 0) <= 0.1 then return false end

	local before = GetAfflictionLimb(patient, limbType, "gypsumcast", 0)
	if not ApplyItem(gypsum, medic, patient, limb) then return false end

	return GetAfflictionLimb(patient, limbType, "gypsumcast", 0) > before
end

local function TryPreparedFractureTreatment(medic, patient)
	local state = GetProcedureState(medic, patient, "fracture_cast")

	local limb, limbType = FindFractureLimb(patient, false, state.limb)
	if limb == nil or limbType == nil then return false end
	state.limb = LimbKey(limbType)
	state.step = "cast"

	local gypsum = FindInventoryItem(medic, { "gypsum" })
	if gypsum == nil then
		if FindAvailableWorldItem("gypsum", medic, nil) ~= nil then
			Log(CharacterName(medic) .. " wants to cast " .. CharacterName(patient) .. " (" .. LimbLabel(limbType) .. "), but needs to fetch cast")
			RequestMedicalItem(medic, { "gypsum" }, 8, medic == patient)
		else
			Log(CharacterName(medic) .. " wants to cast " .. CharacterName(patient) .. " (" .. LimbLabel(limbType) .. "), but no cast available")
			MarkMissingResource(patient, "fracture_cast", limbType, "gypsum")
			ClearProcedureState(medic, patient, "fracture_cast")
		end
		return false
	end

	if ApplyGypsumCastForBot(gypsum, medic, patient, limb, limbType) then
		Log(CharacterName(medic) .. " applied cast to " .. CharacterName(patient) .. " (" .. LimbLabel(limbType) .. ")")
		ClearProcedureState(medic, patient, "fracture_cast")
		return true
	end

	Log(CharacterName(medic) .. " tried to cast " .. CharacterName(patient) .. " (" .. LimbLabel(limbType) .. "), but cast did not apply")
	return false
end

local function TryUnpreparedFractureTreatment(medic, patient)
	local state = GetProcedureState(medic, patient, "fracture_cast")

	local limb, limbType = FindFractureLimb(patient, true, state.limb)
	if limb == nil or limbType == nil then return false end
	state.limb = LimbKey(limbType)
	state.step = "bandage"

	local bandage = FindInventoryItem(medic, { "antibleeding1", "antibleeding2" })
	if bandage == nil then
		Log(CharacterName(medic) .. " wants to prep fracture on " .. CharacterName(patient) .. " (" .. LimbLabel(limbType) .. "), but no bandage in inventory")
		return false
	end

	return ApplyItem(bandage, medic, patient, limb)
end

local function TryFractureTreatment(medic, patient)
	if not PatientNeedsFractureCast(patient) then
		ClearProcedureState(medic, patient, "fracture_cast")
		return false
	end

	if TryPreparedFractureTreatment(medic, patient) then return true end
	return TryUnpreparedFractureTreatment(medic, patient)
end

SequentialProcedures.fracture_cast = TryFractureTreatment

local function PatientHasUnstableEmergency(patient)
	if NeedsResuscitation(patient) or BloodLossValue(patient) >= 45 then return true end

	for _, limbType in ipairs(limbTypes) do
		local bleeding = GetAfflictionLimb(patient, limbType, "bleeding", 0)
		local nonstop = GetAfflictionLimb(patient, limbType, "bleedingnonstop", 0)
		local unclampedArtery = GetArterialCut(patient, limbType) > 0.1
			and GetAfflictionLimb(patient, limbType, "arteriesclamp", 0) <= 0.1
		if nonstop > 0.1 or bleeding > 20 or unclampedArtery then return true end
	end

	return false
end

local function LimbHasOpenForeignBodyAccess(patient, limbType)
	return GetAfflictionLimb(patient, limbType, "gunshotwound", 0) >= 1
		or GetAfflictionLimb(patient, limbType, "explosiondamage", 0) >= 1
		or GetAfflictionLimb(patient, limbType, "retractedskin", 0) >= 99
end

local function NeedsForeignBodyRemoval(patient, limbType)
	if GetAfflictionLimb(patient, limbType, "foreignbody", 0) < BFA.Settings.foreignBodyRemovalThreshold then return false end
	if not LimbHasOpenForeignBodyAccess(patient, limbType) then return false end
	if GetAfflictionLimb(patient, limbType, "bleedingnonstop", 0) > 0.1 then return false end
	if GetAfflictionLimb(patient, limbType, "bleeding", 0) > 15 then return false end
	if HasMissingResource(patient, "foreign_body", limbType, "tweezers") then return false end
	return true
end

local function BotCanRemoveForeignBody(medic)
	return HasSurgerySkill(medic, 30) or GetSurgerySkill(medic) >= 30
end

local function FindForeignBodyLimb(patient)
	local bestLimbType = nil
	local bestScore = 0
	for _, limbType in ipairs(limbTypes) do
		if NeedsForeignBodyRemoval(patient, limbType) then
			local foreignBody = GetAfflictionLimb(patient, limbType, "foreignbody", 0)
			local score = foreignBody
				+ GetAfflictionLimb(patient, limbType, "gunshotwound", 0)
				+ GetAfflictionLimb(patient, limbType, "explosiondamage", 0)
			if foreignBody >= BFA.Settings.foreignBodyUrgentThreshold then score = score + 100 end
			if score > bestScore then
				bestScore = score
				bestLimbType = limbType
			end
		end
	end

	if bestLimbType == nil then return nil, nil end
	return LimbObject(patient, bestLimbType), bestLimbType
end

local function TryForeignBodyRemoval(medic, patient)
	if PatientHasUnstableEmergency(patient) or not BotCanRemoveForeignBody(medic) then return false end

	local limb, limbType = FindForeignBodyLimb(patient)
	if limb == nil or limbType == nil then return false end

	local tweezers = FindInventoryItem(medic, { "tweezers" })
	if tweezers == nil then
		if FindAvailableWorldItem("tweezers", medic, nil) == nil then
			MarkMissingResource(patient, "foreign_body", limbType, "tweezers")
			Log(CharacterName(medic) .. " wants to remove foreign body from " .. CharacterName(patient) .. " (" .. LimbLabel(limbType) .. "), but no tweezers available")
		else
			Log(CharacterName(medic) .. " wants to remove foreign body from " .. CharacterName(patient) .. " (" .. LimbLabel(limbType) .. "), but needs to fetch tweezers")
			RequestMedicalItem(medic, { "tweezers" }, 8, medic == patient)
		end
		return false
	end

	local before = GetAfflictionLimb(patient, limbType, "foreignbody", 0)
	if not ApplyItem(tweezers, medic, patient, limb) then return false end

	local after = GetAfflictionLimb(patient, limbType, "foreignbody", 0)
	if after < before then
		Log(CharacterName(medic) .. " removed part of foreign body from " .. CharacterName(patient) .. " (" .. LimbLabel(limbType) .. ")")
		return true
	end

	return false
end

local function NeedsDirtyBandageRemoval(patient, limbType)
	if GetAfflictionLimb(patient, limbType, "dirtybandage", 0) < BFA.Settings.dirtyBandageCleanupThreshold then return false end
	if GetAfflictionLimb(patient, limbType, "bleedingnonstop", 0) > 0.1 then return false end
	if GetAfflictionLimb(patient, limbType, "bleeding", 0) > 5 then return false end
	return true
end

local function NeedsTourniquetRemoval(patient, limbType)
	if GetAfflictionLimb(patient, limbType, "arteriesclamp", 0) <= 0.1 then return false end
	if GetArterialCut(patient, limbType) > 0.1 then return false end
	if GetAfflictionLimb(patient, limbType, "bleedingnonstop", 0) > 0.1 then return false end
	if GetAfflictionLimb(patient, limbType, "bleeding", 0) > 5 then return false end
	return true
end

local function FindCleanupLimb(patient)
	local bestLimbType = nil
	local bestScore = 0
	for _, limbType in ipairs(limbTypes) do
		if not HasMissingResource(patient, "cleanup", limbType, "cutter") then
			local score = 0
			if NeedsTourniquetRemoval(patient, limbType) then score = score + 100 end
			if NeedsDirtyBandageRemoval(patient, limbType) then
				score = score + 40 + GetAfflictionLimb(patient, limbType, "dirtybandage", 0)
			end
			if score > bestScore then
				bestScore = score
				bestLimbType = limbType
			end
		end
	end

	if bestLimbType == nil then return nil, nil end
	return LimbObject(patient, bestLimbType), bestLimbType
end

local function FindSafeCuttingItem(medic, patient, limbType)
	local gypsumCast = GetAfflictionLimb(patient, limbType, "gypsumcast", 0)

	if gypsumCast <= 0.1 then
		local shears = FindInventoryItem(medic, { "traumashears" })
		if shears ~= nil then return shears end
	end

	if GetMedicalSkill(medic) >= 30 then
		local knife = FindInventoryItem(medic, { "divingknife" })
		if knife ~= nil then return knife end
	end

	return nil
end

local function TryCleanupTemporaryTreatment(medic, patient)
	if PatientHasUnstableEmergency(patient) then return false end

	local limb, limbType = FindCleanupLimb(patient)
	if limb == nil or limbType == nil then return false end

	local item = FindSafeCuttingItem(medic, patient, limbType)
	if item == nil then
		local canUseKnife = GetMedicalSkill(medic) >= 30
		local shearsAvailable = FindAvailableWorldItem("traumashears", medic, nil) ~= nil
		local knifeAvailable = FindAvailableWorldItem("divingknife", medic, nil) ~= nil
		if not shearsAvailable and (not canUseKnife or not knifeAvailable) then
			MarkMissingResource(patient, "cleanup", limbType, "cutter")
			Log(CharacterName(medic) .. " wants to remove bandage/tourniquet from " .. CharacterName(patient) .. " (" .. LimbLabel(limbType) .. "), but no safe cutter available")
		else
			Log(CharacterName(medic) .. " wants to remove bandage/tourniquet from " .. CharacterName(patient) .. " (" .. LimbLabel(limbType) .. "), but needs to fetch cutter")
			if GetAfflictionLimb(patient, limbType, "gypsumcast", 0) <= 0.1 then
				if canUseKnife then
					RequestMedicalItem(medic, { "traumashears", "divingknife" }, 8, medic == patient)
				else
					RequestMedicalItem(medic, { "traumashears" }, 8, medic == patient)
				end
			elseif shearsAvailable then
				RequestMedicalItem(medic, { "traumashears" }, 8, medic == patient)
			end
		end
		return false
	end

	local dirtyBefore = GetAfflictionLimb(patient, limbType, "dirtybandage", 0)
	local clampBefore = GetAfflictionLimb(patient, limbType, "arteriesclamp", 0)
	if not ApplyItem(item, medic, patient, limb) then return false end

	local dirtyAfter = GetAfflictionLimb(patient, limbType, "dirtybandage", 0)
	local clampAfter = GetAfflictionLimb(patient, limbType, "arteriesclamp", 0)
	return dirtyAfter < dirtyBefore or clampAfter < clampBefore
end

local function TrySequentialProcedure(medic, patient, procedureName)
	local procedure = SequentialProcedures[procedureName]
	if procedure == nil then return false end
	return procedure(medic, patient) == true
end

local function PatientHasActionableHigherPriorityThanBoneCare(medic, patient, allowRequest)
	if NeedsResuscitation(patient) then return true, "resuscitation" end

	local bloodCandidates = {
		"antibloodloss2",
		"bloodpackominus",
		"bloodpackoplus",
		"bloodpackaminus",
		"bloodpackaplus",
		"bloodpackbminus",
		"bloodpackbplus",
		"bloodpackabminus",
		"bloodpackabplus",
	}

	if BloodLossValue(patient) >= 45
		and FindInventoryItem(medic, bloodCandidates) ~= nil
	then
		return true, "blood loss"
	end
	if BloodLossValue(patient) >= 45 and allowRequest == true then
		for _, identifier in ipairs(bloodCandidates) do
			if FindAvailableWorldItem(identifier, medic, nil) ~= nil then
				RequestMedicalItem(medic, bloodCandidates, 8, medic == patient)
				return true, "fetching blood loss treatment"
			end
		end
	end

	for _, limbType in ipairs(limbTypes) do
		local bleedingCandidates = { "antibleeding3", "antibleeding2", "antibleeding1", "bandage" }
		if NeedsBleedingControl(patient, limbType)
			and FindInventoryItem(medic, bleedingCandidates) ~= nil
		then
			return true, "bleeding on " .. LimbLabel(limbType)
		end
		if NeedsBleedingControl(patient, limbType) and allowRequest == true then
			for _, identifier in ipairs(bleedingCandidates) do
				if FindAvailableWorldItem(identifier, medic, nil) ~= nil then
					RequestMedicalItem(medic, { "antibleeding1", "bandage", "antibleeding2", "antibleeding3" }, 8, medic == patient)
					return true, "fetching bandage for " .. LimbLabel(limbType)
				end
			end
		end

		local bleeding = GetAfflictionLimb(patient, limbType, "bleeding", 0)
		local nonstop = GetAfflictionLimb(patient, limbType, "bleedingnonstop", 0)
		local sutured = GetAfflictionLimb(patient, limbType, "suturedw", 0)
		if NeedsWoundClosure(patient, limbType)
			and sutured <= 0.1
			and (nonstop > 0.1 or bleeding > 1)
			and GetMedicalSkill(medic) >= 30
			and FindInventoryItem(medic, { "suture" }) ~= nil
		then
			return true, "suture on " .. LimbLabel(limbType)
		end
		if NeedsWoundClosure(patient, limbType)
			and sutured <= 0.1
			and (nonstop > 0.1 or bleeding > 1)
			and GetMedicalSkill(medic) >= 30
			and allowRequest == true
			and FindAvailableWorldItem("suture", medic, nil) ~= nil
		then
			RequestMedicalItem(medic, { "suture" }, 8, medic == patient)
			return true, "fetching suture for " .. LimbLabel(limbType)
		end
	end

	return false, nil
end

local function SelectDislocationItem(medic, patient, limbType)
	if not LimbIsExtremity(limbType) or not LimbIsDislocated(patient, limbType) then return nil end

	if not BotCanRelocateDislocation(medic, patient) then return nil end

	return FindInventoryItem(medic, { "wrench", "repairpack" })
end

local function ApplyDislocationRelocation(item, medic, patient, limbType)
	if item == nil or medic == nil or patient == nil or limbType == nil then return false end
	if NT == nil or NT.DislocateLimb == nil or not LimbIsDislocated(patient, limbType) then return false end

	local identifier = DislocationIdentifier(limbType)
	local before = identifier ~= nil and GetAffliction(patient, identifier, 0) or 0

	if identifier ~= nil and HF ~= nil and HF.SetAffliction ~= nil then
		pcall(function() HF.SetAffliction(patient, identifier, 0, medic, before) end)
	else
		NT.DislocateLimb(patient, limbType, -1000)
	end

	if HF ~= nil then
		if HF.GiveSkillScaled ~= nil then HF.GiveSkillScaled(medic, "medical", 4000) end
		if HF.GiveItem ~= nil then pcall(function() HF.GiveItem(patient, "ntsfx_velcro") end) end
		if HF.HasAffliction ~= nil and HF.AddAffliction ~= nil and not HF.HasAffliction(patient, "analgesia", 0.5) then
			HF.AddAffliction(patient, "severepain", 5, medic)
		end
	end

	local fixed = not LimbIsDislocated(patient, limbType)
	Log(CharacterName(medic) .. (fixed and " relocated " or " tried to relocate ")
		.. CharacterName(patient)
		.. " ("
		.. LimbLabel(limbType)
		.. ", before="
		.. tostring(before)
		.. ")")
	return fixed
end

local function TryDislocationTreatment(medic, patient)
	local limb, limbType = FindDislocatedLimb(patient)
	if limb == nil or limbType == nil then return false end

	if not BotCanRelocateDislocation(medic, patient) then
		Log(CharacterName(medic) .. " cannot relocate dislocation on " .. CharacterName(patient) .. ": missing permission/skill")
		StowHeldMedicalItems(medic)
		return false
	end
	local hasHigherPriority, higherPriorityReason = PatientHasActionableHigherPriorityThanBoneCare(medic, patient, true)
	if hasHigherPriority then
		if BFA.State.itemFetches[CharacterKey(medic)] == nil then
			Log(CharacterName(medic) .. " deferred relocation of " .. CharacterName(patient) .. ": higher priority actionable (" .. tostring(higherPriorityReason) .. ")")
		end
		return false
	end

	local item = SelectDislocationItem(medic, patient, limbType)
	if item == nil then
		local requestStarted = false
		local wrenchAvailable = FindAvailableWorldItem("wrench", medic, nil) ~= nil
		if wrenchAvailable then
			Log(CharacterName(medic) .. " wants to relocate " .. CharacterName(patient) .. " (" .. LimbLabel(limbType) .. "), but needs to fetch tool")
			requestStarted = RequestMedicalItem(medic, { "wrench" }, 6, medic == patient)
		else
			Log(CharacterName(medic) .. " wants to relocate " .. CharacterName(patient) .. " (" .. LimbLabel(limbType) .. "), but no tool available")
			MarkMissingResource(patient, "dislocation", limbType, "relocator")
		end
		StowHeldMedicalItems(medic)
		pcall(function() medic.DeselectCharacter() end)
		pcall(function() medic.SelectedCharacter = nil end)
		return requestStarted or wrenchAvailable
	end

	local fixed = ApplyDislocationRelocation(item, medic, patient, limbType)
	if not fixed then
		StowHeldMedicalItems(medic)
		pcall(function() medic.DeselectCharacter() end)
		pcall(function() medic.SelectedCharacter = nil end)
	end
	return true
end

local function StowStaleHeldBoneItems(medic, patient)
	if medic == nil or medic.Inventory == nil then return end
	if HF == nil or HF.GetItemInRightHand == nil or HF.GetItemInLeftHand == nil then return end
	local hasHigherPriority = PatientHasActionableHigherPriorityThanBoneCare(medic, patient, false)
	if PatientHasPendingBoneCare(patient) and not hasHigherPriority then return end

	local heldItems = { HF.GetItemInRightHand(medic), HF.GetItemInLeftHand(medic) }
	for index = 1, 2 do
		local item = heldItems[index]
		local identifier = ItemIdentifier(item)
		if item ~= nil
			and IsDirectlyCarriedBy(medic, item)
			and (identifier == "wrench" or identifier == "heavywrench" or identifier == "repairpack" or identifier == "screwdriver" or identifier == "gypsum")
		then
			pcall(function() medic.Inventory.TryPutItem(item, nil, { InvSlotType.Any }) end)
		end
	end
end

local function SelectFallbackItem(medic, patient, limbType)
	if NeedsWoundClosure(patient, limbType) then
		local suture = FindInventoryItem(medic, { "suture" })
		if suture ~= nil then return suture end
	end

	if NeedsBleedingControl(patient, limbType) then
		local nonstop = GetAfflictionLimb(patient, limbType, "bleedingnonstop", 0)
		local bandaged = GetAfflictionLimb(patient, limbType, "bandaged", 0)
		-- Non-medics stop stacking bandages at 30 % coverage (unless nonstop bleed).
		-- Medics tolerate up to 50 % (already handled in NeedsBleedingControl).
		local softCap = IsMedicalJob(medic) and 50 or 30
		if bandaged < softCap or nonstop > 0.1 then
			local bandage = FindInventoryItem(medic, { "antibleeding3", "antibleeding2", "antibleeding1", "bandage" })
			if bandage ~= nil then return bandage end
		end
	end

	local fractureItem = SelectFractureItem(medic, patient, limbType)
	if fractureItem ~= nil then return fractureItem end

	return nil
end

local function BloodPackType(item)
	local identifier = ItemIdentifier(item)
	if identifier == nil then return nil end
	if identifier == "antibloodloss2" or identifier == "bloodpackominus" then return "ominus" end
	if HF ~= nil and HF.StartsWith ~= nil and HF.StartsWith(identifier, "bloodpack") then
		return string.sub(identifier, string.len("bloodpack") + 1)
	end
	return nil
end

local function IsCompatibleBloodPack(item, patient)
	if NT == nil or NT.GetBloodtype == nil then return false end
	local packtype = BloodPackType(item)
	if packtype == nil then return false end

	local targettype = NT.GetBloodtype(patient)
	if targettype == nil then return packtype == "ominus" end

	local packhasA = string.find(packtype, "a") ~= nil
	local packhasB = string.find(packtype, "b") ~= nil
	local packhasRh = string.find(packtype, "plus") ~= nil
	local targethasA = string.find(targettype, "a") ~= nil
	local targethasB = string.find(targettype, "b") ~= nil
	local targethasRh = string.find(targettype, "plus") ~= nil

	return (targethasRh or not packhasRh)
		and (targethasA or not packhasA)
		and (targethasB or not packhasB)
end

local function IsUsableBloodPack(item, patient)
	if item == nil or item.Removed or item.Condition <= 0 then return false end
	local identifier = ItemIdentifier(item)
	if identifier == "antibloodloss2" or identifier == "bloodpackominus" then return true end
	return BloodPackType(item) ~= nil and IsCompatibleBloodPack(item, patient)
end

BloodLossValue = function(patient)
	local afflictionBloodloss = GetAffliction(patient, "bloodloss", 0)
	local characterBloodloss = SafeProperty(patient, "Bloodloss", 0) or 0
	if characterBloodloss > afflictionBloodloss then return characterBloodloss end
	return afflictionBloodloss
end

local function PatientNeedsBloodPack(patient)
	local bloodpressure = GetAffliction(patient, "bloodpressure", 0)
	return BloodLossValue(patient) >= 35
		or (bloodpressure > 0 and bloodpressure < 60)
end

local function PatientCanUseHeldBloodPack(patient)
	local bloodpressure = GetAffliction(patient, "bloodpressure", 0)
	return BloodLossValue(patient) >= 20
		or (bloodpressure > 0 and bloodpressure < 70)
end

local bloodPackIdentifiers = {
	"antibloodloss2",
	"bloodpackominus",
	"bloodpackoplus",
	"bloodpackaminus",
	"bloodpackaplus",
	"bloodpackbminus",
	"bloodpackbplus",
	"bloodpackabminus",
	"bloodpackabplus",
}

local function FindCompatibleBloodPack(medic, patient)
	if medic == nil or medic.Inventory == nil or medic.Inventory.AllItems == nil then return nil end

	if HF ~= nil and HF.GetItemInRightHand ~= nil and HF.GetItemInLeftHand ~= nil then
		local rightHand = HF.GetItemInRightHand(medic)
		local leftHand = HF.GetItemInLeftHand(medic)
		local heldItems = { rightHand, leftHand }
		for index = 1, 2 do
			local item = heldItems[index]
			if IsUsableBloodPack(item, patient) and IsDirectlyCarriedBy(medic, item) then return item end
		end
	end

	local fallback = nil
	for item in medic.Inventory.AllItems do
		if item ~= nil and not item.Removed and item.Condition > 0 and IsDirectlyCarriedBy(medic, item) then
			local identifier = ItemIdentifier(item)
			for _, candidate in ipairs(bloodPackIdentifiers) do
				if identifier == candidate then
					if IsUsableBloodPack(item, patient) then
						if identifier == "antibloodloss2" or identifier == "bloodpackominus" then return item end
						fallback = item
					end
				end
			end
		end
	end
	return fallback
end

local function FindHeldCompatibleBloodPack(medic, patient)
	if HF == nil or HF.GetItemInRightHand == nil or HF.GetItemInLeftHand == nil then return nil end

	local rightHand = HF.GetItemInRightHand(medic)
	local leftHand = HF.GetItemInLeftHand(medic)
	local heldItems = { rightHand, leftHand }
	for index = 1, 2 do
		local item = heldItems[index]
		if IsUsableBloodPack(item, patient) and IsDirectlyCarriedBy(medic, item) then return item end
	end

	return nil
end

local function SelectSystemicFallbackItem(medic, patient)
	local bloodloss = BloodLossValue(patient)
	if bloodloss >= 45 then
		local bloodPack = FindCompatibleBloodPack(medic, patient)
		if bloodPack ~= nil then return bloodPack end
	end

	return nil
end

local function CloseEnoughToTreat(medic, patient)
	if medic == patient then return true end
	local medicPos = SafeProperty(medic, "WorldPosition", nil)
	local patientPos = SafeProperty(patient, "WorldPosition", nil)
	if medicPos == nil or patientPos == nil then return false end
	return Distance(medicPos, patientPos) <= BFA.Settings.maxOtherTreatmentDistance
end

local function IsSelectedPatient(medic, patient)
	return SafeProperty(medic, "SelectedCharacter", nil) == patient
end

NeedsResuscitation = function(patient)
	return GetAffliction(patient, "cardiacarrest", 0) > 0.1
		or GetAffliction(patient, "respiratoryarrest", 0) > 0.1
end

local function CPRAnimationValue()
	if AnimControllerAnimation == nil then return nil end

	local value = nil
	pcall(function() value = AnimControllerAnimation.CPR end)
	if value == nil then
		pcall(function() value = AnimControllerAnimation["CPR"] end)
	end
	return value
end

local function StartCPRAnimation(medic)
	local animController = SafeProperty(medic, "AnimController", nil)
	local cprAnimation = CPRAnimationValue()
	if animController == nil or cprAnimation == nil then return false end

	local ok = pcall(function() animController.StartAnimation(cprAnimation) end)
	if ok then return true end

	ok = pcall(function() animController.Anim = cprAnimation end)
	return ok == true
end

local function StopCPRAnimation(medic)
	local animController = SafeProperty(medic, "AnimController", nil)
	local cprAnimation = CPRAnimationValue()
	if animController == nil or cprAnimation == nil then return end

	pcall(function() animController.StopAnimation(cprAnimation) end)
end

local function ClearBotCPRState(medicKey)
	local state = BFA.State.cpr[medicKey]
	if state ~= nil then
		StopCPRAnimation(state.medic)
		if state.medic ~= nil and state.patient ~= nil and IsSelectedPatient(state.medic, state.patient) then
			pcall(function() state.medic.DeselectCharacter() end)
			pcall(function() state.medic.SelectedCharacter = nil end)
		end
	end
	BFA.State.cpr[medicKey] = nil
end

local function RefreshBotCPRBuffs(medic, patient)
	if HF ~= nil and HF.HasAffliction ~= nil and HF.SetAffliction ~= nil then
		pcall(function()
			if not HF.HasAffliction(patient, "luabotomy") then HF.SetAffliction(patient, "luabotomy", 1) end
		end)
	end

	if GetAffliction(patient, "cpr_buff", 0) < 3 then AddAffliction(patient, "cpr_buff", 2, medic) end
	if GetAffliction(patient, "cpr_fracturebuff", 0) < 3 then AddAffliction(patient, "cpr_fracturebuff", 2, medic) end
end

local function CleanupBotCPRStates()
	for medicKey, state in pairs(BFA.State.cpr) do
		local medic = state ~= nil and state.medic or nil
		local patient = state ~= nil and state.patient or nil
		if not IsCrewHuman(medic)
			or not IsCrewHuman(patient)
			or patient.TeamID ~= medic.TeamID
			or patient.IsDead
			or patient.Removed
			or not NeedsResuscitation(patient)
		then
			ClearBotCPRState(medicKey)
		end
	end
end

local function MaintainBotCPRStates()
	for medicKey, state in pairs(BFA.State.cpr) do
		local medic = state ~= nil and state.medic or nil
		local patient = state ~= nil and state.patient or nil
		if IsCrewHuman(medic)
			and IsCrewHuman(patient)
			and patient.TeamID == medic.TeamID
			and NeedsResuscitation(patient)
			and CloseEnoughToTreat(medic, patient)
		then
			StowHeldMedicalItems(medic)
			pcall(function() medic.SelectedCharacter = patient end)
			StartCPRAnimation(medic)
		else
			ClearBotCPRState(medicKey)
		end
	end
end

function BFA.IsSustainingCPR(medic, patient)
	if medic == nil then return false end
	local state = BFA.State.cpr[CharacterKey(medic)]
	if state == nil then return false end
	if patient ~= nil and state.patient ~= patient then return false end
	return IsCrewHuman(state.patient) and NeedsResuscitation(state.patient)
end

local Policy = {}
NT.BotEngagementPolicy = Policy

local followOrders = { follow = true }
local rescueOrders = { rescue = true, requestfirstaid = true }
local weaponOrders = { operateweapons = true }
local combatOrders = { fightintruders = true, assaultenemy = true, findweapon = true }
local repairOrders = {
	fixleaks = true,
	repairsystems = true,
	repairmechanical = true,
	repairelectrical = true,
	extinguishfires = true,
	pumpwater = true,
}
local focusOrders = {
	operateweapons = true,
	steer = true,
	fightintruders = true,
	assaultenemy = true,
	findweapon = true,
	fixleaks = true,
	repairsystems = true,
	repairmechanical = true,
	repairelectrical = true,
	extinguishfires = true,
	pumpwater = true,
}

local function IdentifierText(value)
	if value == nil then return nil end
	local innerValue = SafeProperty(value, "Value", nil)
	if innerValue ~= nil then return string.lower(tostring(innerValue)) end
	return string.lower(tostring(value))
end

local function ObjectiveIdentifier(objective)
	return IdentifierText(SafeProperty(objective, "Identifier", nil))
end

local function OrderIdentifier(order)
	local identifier = IdentifierText(SafeProperty(order, "Identifier", nil))
	if identifier ~= nil and identifier ~= "" then return identifier end

	local objective = SafeProperty(order, "Objective", nil)
	return ObjectiveIdentifier(objective)
end

local function TypeName(value)
	if value == nil then return "" end
	local typeName = ""
	pcall(function() typeName = tostring(value.GetType().Name) end)
	return string.lower(typeName)
end

local function ObjectiveText(objective)
	if objective == nil then return "" end
	local text = TypeName(objective)
	local identifier = ObjectiveIdentifier(objective)
	if identifier ~= nil then text = text .. " " .. identifier end
	local debugTag = SafeProperty(objective, "DebugTag", nil)
	if debugTag ~= nil then text = text .. " " .. string.lower(tostring(debugTag)) end
	return text
end

local function ObjectiveMatches(objective, identifiers, patterns)
	local identifier = ObjectiveIdentifier(objective)
	if identifier ~= nil and identifiers ~= nil and identifiers[identifier] then return true end

	if patterns ~= nil then
		local text = ObjectiveText(objective)
		for _, pattern in ipairs(patterns) do
			if string.find(text, pattern, 1, true) ~= nil then return true end
		end
	end

	return false
end

local function ObjectivePriority(objective)
	local priority = SafeProperty(objective, "Priority", nil)
	if type(priority) == "number" then return priority end
	return 0
end

local function GetObjectiveManager(character)
	local ai = SafeProperty(character, "AIController", nil)
	return ai ~= nil and SafeProperty(ai, "ObjectiveManager", nil) or nil
end

local function ForEachCurrentOrder(character, callback)
	local manager = GetObjectiveManager(character)
	local orders = manager ~= nil and SafeProperty(manager, "CurrentOrders", nil) or nil
	if orders == nil then return false end

	local stopped = false
	local ok = pcall(function()
		for order in orders do
			if callback(order) == true then
				stopped = true
				break
			end
		end
	end)
	if ok then return stopped end

	pcall(function()
		for _, order in pairs(orders) do
			if callback(order) == true then
				stopped = true
				break
			end
		end
	end)
	return stopped
end

function Policy.HasOrder(character, identifiers)
	return ForEachCurrentOrder(character, function(order)
		local identifier = OrderIdentifier(order)
		return identifier ~= nil and identifiers[identifier] == true
	end)
end

local function HighestOrderPriority(character, identifiers)
	local highest = nil
	ForEachCurrentOrder(character, function(order)
		local identifier = OrderIdentifier(order)
		if identifier ~= nil and identifiers[identifier] == true then
			local priority = SafeProperty(order, "ManualPriority", nil)
			if type(priority) ~= "number" then
				priority = ObjectivePriority(SafeProperty(order, "Objective", nil))
			end
			if highest == nil or priority > highest then highest = priority end
		end
		return false
	end)
	return highest
end

local function CurrentObjective(character)
	local manager = GetObjectiveManager(character)
	if manager == nil then return nil end

	local objective = nil
	pcall(function() objective = manager.GetActiveObjective() end)
	if objective ~= nil then return objective end

	objective = SafeProperty(manager, "CurrentObjective", nil)
	if objective ~= nil then return objective end

	return SafeProperty(manager, "CurrentOrder", nil)
end

local function CurrentOrderObjective(character)
	local manager = GetObjectiveManager(character)
	if manager == nil then return nil end
	return SafeProperty(manager, "CurrentOrder", nil)
end

local function ActiveMatches(character, identifiers, patterns)
	local objective = CurrentObjective(character)
	if ObjectiveMatches(objective, identifiers, patterns) then return true end

	local orderObjective = CurrentOrderObjective(character)
	return ObjectiveMatches(orderObjective, identifiers, patterns)
end

function Policy.GetDutyState(character)
	local manager = GetObjectiveManager(character)
	local activeObjective = CurrentObjective(character)
	local currentOrder = CurrentOrderObjective(character)
	local managerPriority = 0
	if manager ~= nil then
		pcall(function() managerPriority = manager.GetCurrentPriority() end)
	end
	local activePriority = math.max(ObjectivePriority(activeObjective), ObjectivePriority(currentOrder), managerPriority or 0)
	local activeWeapon = ActiveMatches(character, weaponOrders, { "operateweapons", "turret" })
	local activeCombat = ActiveMatches(character, combatOrders, { "combat", "fightintruders", "assaultenemy" })
	local activeRepair = ActiveMatches(character, repairOrders, { "fixleaks", "repair", "extinguish", "pumpwater" })
	local activeImportant = activePriority <= 0 or activePriority >= 30
	local rescuePriority = HighestOrderPriority(character, rescueOrders)
	local focusPriority = HighestOrderPriority(character, focusOrders)
	local rescueActive = ActiveMatches(character, rescueOrders, { "rescue", "firstaid" })
	local hasRescue = rescuePriority ~= nil

	return {
		follow = Policy.HasOrder(character, followOrders),
		hasRescue = hasRescue,
		rescueDominant = rescueActive or (hasRescue and (focusPriority == nil or rescuePriority >= focusPriority)),
		activeWeapon = activeWeapon and activeImportant,
		activeCombat = activeCombat and activeImportant,
		activeRepair = activeRepair and activeImportant,
		activeHighFocus = (activeWeapon or activeCombat or activeRepair) and activeImportant,
		activePriority = activePriority,
	}
end

function Policy.IsCriticalPatient(patient)
	if patient == nil then return false end
	if NeedsResuscitation(patient) then return true end
	if PatientIsIncapacitated(patient) then return true end
	if BloodLossValue(patient) >= 45 then return true end
	return PatientTreatmentScore(patient) >= BFA.Settings.selfCareSevereScore
end

function Policy.HasCarriedQuickTreatment(medic, patient)
	if medic == nil or medic.Inventory == nil then return false end
	if PatientNeedsBloodPack(patient) and FindCompatibleBloodPack(medic, patient) ~= nil then return true end

	local limb, score = FindWorstTreatableLimb(patient)
	if limb == nil or score <= 0 then return false end
	local limbType = HF ~= nil and HF.NormalizeLimbType ~= nil and HF.NormalizeLimbType(limb.type) or limb.type

	if NeedsWoundClosure(patient, limbType) and GetMedicalSkill(medic) >= 30 and FindInventoryItem(medic, { "suture" }) ~= nil then
		return true
	end
	if NeedsBleedingControl(patient, limbType) and FindInventoryItem(medic, { "antibleeding3", "antibleeding2", "antibleeding1", "bandage" }) ~= nil then
		return true
	end
	return false
end

function Policy.GetTreatmentMode(medic, patient)
	if not IsCrewHuman(medic) or not IsBot(medic) or not IsCrewHuman(patient) then return false, "none" end
	if patient.IsDead or patient.Removed then return false, "none" end
	if PatientIsIncapacitated(medic) then return false, "unconscious" end
	local patientDuty = Policy.GetDutyState(patient)
	if patientDuty.follow then return false, "follow_lock" end
	if medic ~= patient and patientDuty.activeCombat then return false, "patient_combat" end

	local score = PatientTreatmentScore(patient)
	local critical = Policy.IsCriticalPatient(patient)
	local medicDuty = Policy.GetDutyState(medic)
	local isMedic = IsMedicalJob(medic)
	local highSkill = GetMedicalSkill(medic) >= BFA.Settings.highSkillMedicalThreshold
	if medicDuty.follow then return false, "helper_follow" end

	if medic == patient then
		if medicDuty.activeCombat then return false, "combat" end

		-- Actively manning weapons or repairing: only use items already in hand.
		if medicDuty.activeWeapon or medicDuty.activeRepair then
			if critical and score >= BFA.Settings.quickCareMinimumScore and Policy.HasCarriedQuickTreatment(medic, patient) then
				return true, "quick"
			end
			return false, "high_focus"
		end

		if isMedic or medicDuty.rescueDominant then
			return score > 0.1, "full"
		end

		-- The bot has a focus-type order (repair, weapons, combat) but is momentarily
		-- between sub-tasks. Respect the order intent: only use items already carried
		-- for minor injuries; allow basic self-care only when the injury is severe.
		if Policy.HasOrder(medic, focusOrders) then
			if score >= BFA.Settings.selfCareMinimumScore and Policy.HasCarriedQuickTreatment(medic, patient) then
				return true, "quick"
			end
			if score >= BFA.Settings.selfCareSevereScore then
				return true, "basic"
			end
			return false, "focus_order_self"
		end

		if score >= BFA.Settings.selfCareMinimumScore then
			return true, "basic"
		end
		return false, "minor_self"
	end

	if medicDuty.activeCombat and not medicDuty.rescueDominant then return false, "helper_combat" end
	if medicDuty.activeHighFocus and not medicDuty.rescueDominant then return false, "helper_high_focus" end

	if isMedic then
		if medicDuty.rescueDominant
			or critical
			or score >= BFA.Settings.otherCareMinimumScore
			or PatientNeedsFunctionalBoneCare(patient)
		then
			return true, "full"
		end
		return false, "minor_other"
	end

	if medicDuty.rescueDominant and (score >= BFA.Settings.otherCareMinimumScore or PatientNeedsFunctionalBoneCare(patient)) then
		return true, "basic"
	end

	if highSkill and not medicDuty.activeHighFocus and (critical or PatientIsIncapacitated(patient) or score >= BFA.Settings.nonMedicHelperMinimumScore) then
		return true, "basic"
	end

	return false, "not_medic"
end

local function TryBotCPR(medic, patient)
	if medic == patient or not NeedsResuscitation(patient) then return false end
	local medicKey = CharacterKey(medic)
	if patient.IsDead or patient.Removed then
		ClearBotCPRState(medicKey)
		return false
	end

	local state = BFA.State.cpr[medicKey]
	if state == nil or state.patient ~= patient then
		ClearBotCPRState(medicKey)
		state = {
			medic = medic,
			patient = patient,
			patientKey = CharacterKey(patient),
			ticks = 0,
		}
		BFA.State.cpr[medicKey] = state
		StowHeldMedicalItems(medic)
		Log(CharacterName(medic) .. " started CPR on " .. CharacterName(patient))
	end

	pcall(function() medic.SelectedCharacter = patient end)
	StartCPRAnimation(medic)
	RefreshBotCPRBuffs(medic, patient)

	state.ticks = state.ticks + BFA.Settings.assistIntervalTicks
	return true
end

local function SelectBasicFallbackItem(medic, patient, limbType)
	if NeedsWoundClosure(patient, limbType) and GetMedicalSkill(medic) >= 30 then
		local suture = FindInventoryItem(medic, { "suture" })
		if suture ~= nil then return suture end
	end

	if NeedsBleedingControl(patient, limbType) then
		local nonstop = GetAfflictionLimb(patient, limbType, "bleedingnonstop", 0)
		local bandaged = GetAfflictionLimb(patient, limbType, "bandaged", 0)
		local softCap = IsMedicalJob(medic) and 50 or 30
		if bandaged < softCap or nonstop > 0.1 then
			local bandage = FindInventoryItem(medic, { "antibleeding3", "antibleeding2", "antibleeding1", "bandage" })
			if bandage ~= nil then return bandage end
		end
	end

	return nil
end

local function TryCarriedCleanupTemporaryTreatment(medic, patient)
	local limb, limbType = FindCleanupLimb(patient)
	if limb == nil or limbType == nil then return false end

	local item = nil
	if GetAfflictionLimb(patient, limbType, "gypsumcast", 0) <= 0.1 then
		item = FindInventoryItem(medic, { "traumashears" })
	end
	if item == nil and GetMedicalSkill(medic) >= 30 then
		item = FindInventoryItem(medic, { "divingknife" })
	end
	if item == nil then return false end

	return ApplyItem(item, medic, patient, limb)
end

local function TryBasicCarriedTreatment(medic, patient, allowCleanup)
	local bloodPack = FindCompatibleBloodPack(medic, patient)
	if bloodPack ~= nil and PatientNeedsBloodPack(patient) then
		local torso = LimbObject(patient, LimbType.Torso)
		if torso ~= nil then return ApplyItem(bloodPack, medic, patient, torso) end
	end

	local limb, score = FindWorstTreatableLimb(patient)
	if limb ~= nil and score > 0 then
		local limbType = HF ~= nil and HF.NormalizeLimbType ~= nil and HF.NormalizeLimbType(limb.type) or limb.type
		local item = SelectBasicFallbackItem(medic, patient, limbType)
		if item ~= nil then return ApplyItem(item, medic, patient, limb) end
	end

	if allowCleanup then
		return TryCarriedCleanupTemporaryTreatment(medic, patient)
	end

	return false
end

local function TryHigherPriorityTreatmentBeforeBoneCare(medic, patient)
	if BloodLossValue(patient) >= 45 then
		local systemicItem = SelectSystemicFallbackItem(medic, patient)
		local torso = LimbObject(patient, LimbType.Torso)
		if systemicItem ~= nil and torso ~= nil then
			return ApplyItem(systemicItem, medic, patient, torso)
		end
		for _, identifier in ipairs(bloodPackIdentifiers) do
			if FindAvailableWorldItem(identifier, medic, nil) ~= nil then
				RequestMedicalItem(medic, bloodPackIdentifiers, 9, medic == patient)
				return true
			end
		end
	end

	for _, limbType in ipairs(limbTypes) do
		local limb = LimbObject(patient, limbType)
		if limb ~= nil then
			local bleeding = GetAfflictionLimb(patient, limbType, "bleeding", 0)
			local nonstop = GetAfflictionLimb(patient, limbType, "bleedingnonstop", 0)
			local sutured = GetAfflictionLimb(patient, limbType, "suturedw", 0)

			if NeedsWoundClosure(patient, limbType)
				and sutured <= 0.1
				and (nonstop > 0.1 or bleeding > 1)
				and GetMedicalSkill(medic) >= 30
			then
				local suture = FindInventoryItem(medic, { "suture" })
				if suture ~= nil then return ApplyItem(suture, medic, patient, limb) end
				if FindAvailableWorldItem("suture", medic, nil) ~= nil then
					RequestMedicalItem(medic, { "suture" }, 9, medic == patient)
					return true
				end
			end

			if NeedsBleedingControl(patient, limbType) then
				local bandage = FindInventoryItem(medic, { "antibleeding3", "antibleeding2", "antibleeding1", "bandage" })
				if bandage ~= nil then return ApplyItem(bandage, medic, patient, limb) end
				for _, identifier in ipairs({ "antibleeding1", "bandage", "antibleeding2", "antibleeding3" }) do
					if FindAvailableWorldItem(identifier, medic, nil) ~= nil then
						RequestMedicalItem(medic, { "antibleeding1", "bandage", "antibleeding2", "antibleeding3" }, 9, medic == patient)
						return true
					end
				end
			end
		end
	end

	return false
end

local function RequestSelfCareItem(medic, patient)
	if medic ~= patient then return false end
	AddVanillaSelfCareObjective(medic, 1.25)

	if PatientNeedsBloodPack(patient) and FindCompatibleBloodPack(medic, patient) == nil then
		RequestMedicalItem(medic, bloodPackIdentifiers, 6, true)
		return false
	end

	local limb, score = FindWorstTreatableLimb(patient)
	if limb ~= nil and score > 0 then
		local limbType = HF ~= nil and HF.NormalizeLimbType ~= nil and HF.NormalizeLimbType(limb.type) or limb.type
		if NeedsBleedingControl(patient, limbType)
			and FindInventoryItem(medic, { "antibleeding3", "antibleeding2", "antibleeding1", "bandage" }) == nil
		then
			RequestMedicalItem(medic, { "antibleeding1", "bandage", "antibleeding2", "antibleeding3" }, 6, true)
			return false
		end
		if NeedsWoundClosure(patient, limbType)
			and GetMedicalSkill(medic) >= 30
			and FindInventoryItem(medic, { "suture" }) == nil
		then
			RequestMedicalItem(medic, { "suture" }, 6, true)
			return false
		end
	end

	if PatientNeedsBandage(patient)
		and FindInventoryItem(medic, { "antibleeding3", "antibleeding2", "antibleeding1", "bandage" }) == nil
	then
		RequestMedicalItem(medic, { "antibleeding1", "bandage", "antibleeding2", "antibleeding3" }, 6, true)
		return false
	end

	return false
end

local function HasImmediateWoundClosureOption(medic, patient)
	if GetMedicalSkill(medic) < 30 or FindInventoryItem(medic, { "suture" }) == nil then return false end
	for _, limbType in ipairs(limbTypes) do
		if NeedsWoundClosure(patient, limbType) then return true end
	end
	return false
end

local function HasImmediateBoneCareOption(medic, patient)
	for _, limbType in ipairs(limbTypes) do
		if LimbIsExtremity(limbType) and SelectFractureItem(medic, patient, limbType) ~= nil then return true end
	end

	local hasHigherPriority = PatientHasActionableHigherPriorityThanBoneCare(medic, patient, false)
	if not hasHigherPriority and BotCanRelocateDislocation(medic, patient) then
		local _, limbType = FindDislocatedLimb(patient)
		if limbType ~= nil and SelectDislocationItem(medic, patient, limbType) ~= nil then return true end
	end

	return false
end

local function ReleasePatientIfNoImmediateCare(medic, patient)
	if medic == nil or patient == nil or medic == patient then return end
	if not IsSelectedPatient(medic, patient) then return end
	if PatientHasUnstableEmergency(patient) then return end
	if PatientNeedsBloodPack(patient) then return end
	if PatientNeedsBandage(patient) then return end
	if HasImmediateBoneCareOption(medic, patient) then return end
	if HasImmediateWoundClosureOption(medic, patient) then return end

	local cleanupLimb = FindCleanupLimb(patient)
	if cleanupLimb ~= nil then return end

	local foreignBodyLimb = FindForeignBodyLimb(patient)
	if foreignBodyLimb ~= nil then return end

	StowHeldMedicalItems(medic)
	pcall(function() medic.DeselectCharacter() end)
	pcall(function() medic.SelectedCharacter = nil end)
end

local function TryFallbackTreatment(medic, patient)
	if not IsCrewHuman(medic) or not IsBot(medic) or not IsCrewHuman(patient) then return false end
	if patient.IsDead or patient.Removed then return false end
	if medic ~= patient then
		if not CloseEnoughToTreat(medic, patient) then return false end
		if not IsSelectedPatient(medic, patient)
			and not (NeedsResuscitation(patient) and BFA.IsSustainingCPR(medic, patient))
		then
			if PatientNeedsFunctionalBoneCare(patient)
				and (IsMedicalJob(medic) or GetMedicalSkill(medic) >= BFA.Settings.highSkillMedicalThreshold)
			then
				pcall(function() medic.SelectedCharacter = patient end)
			else
				return false
			end
		end
	end

	local allowed, treatmentMode = Policy.GetTreatmentMode(medic, patient)
	if not allowed then return false end
	if medic == patient then AddVanillaSelfCareObjective(medic, 1.25) end

	if treatmentMode == "quick" then
		return TryBasicCarriedTreatment(medic, patient, false)
	end

	if treatmentMode == "basic" then
		if medic ~= patient and NeedsResuscitation(patient) then
			if IsMedicalJob(medic) or GetMedicalSkill(medic) >= BFA.Settings.highSkillMedicalThreshold then
				return TryBotCPR(medic, patient)
			end
			return false
		end
		if TryBasicCarriedTreatment(medic, patient, true) then return true end
		if medic == patient then
			if TryCleanupTemporaryTreatment(medic, patient) then return true end
			return RequestSelfCareItem(medic, patient)
		end
		return false
	end

	if medic ~= patient and NeedsResuscitation(patient) then
		return TryBotCPR(medic, patient)
	end

	local heldBloodPack = FindHeldCompatibleBloodPack(medic, patient)
	if heldBloodPack ~= nil and PatientCanUseHeldBloodPack(patient) then
		local torso = LimbObject(patient, LimbType.Torso)
		if torso ~= nil then return ApplyItem(heldBloodPack, medic, patient, torso) end
	end

	StowStaleHeldBandage(medic, patient)
	StowStaleHeldBoneItems(medic, patient)

	if BloodLossValue(patient) >= 45 then
		local systemicItem = SelectSystemicFallbackItem(medic, patient)
		local torso = LimbObject(patient, LimbType.Torso)
		if systemicItem ~= nil and torso ~= nil then
			return ApplyItem(systemicItem, medic, patient, torso)
		end
	end

	if TryForeignBodyRemoval(medic, patient) then return true end
	if TryHigherPriorityTreatmentBeforeBoneCare(medic, patient) then return true end

	local limb, score = FindWorstTreatableLimb(patient)
	local item = nil
	if limb ~= nil and score > 0 then
		local limbType = HF ~= nil and HF.NormalizeLimbType ~= nil and HF.NormalizeLimbType(limb.type) or limb.type
		item = SelectFallbackItem(medic, patient, limbType)
	end

	if item ~= nil and limb ~= nil then
		return ApplyItem(item, medic, patient, limb)
	end

	if TrySequentialProcedure(medic, patient, "fracture_cast") then return true end
	if TryDislocationTreatment(medic, patient) then return true end
	if TryCleanupTemporaryTreatment(medic, patient) then return true end

	if item == nil then
		limb = LimbObject(patient, LimbType.Torso)
		item = SelectSystemicFallbackItem(medic, patient)
	end

	if item == nil or limb == nil then
		if medic == patient and RequestSelfCareItem(medic, patient) then return true end
		ReleasePatientIfNoImmediateCare(medic, patient)
		return false
	end

	return ApplyItem(item, medic, patient, limb)
end

local function CharacterInjuryScore(character)
	return PatientTreatmentScore(character)
end

local function FindBestFallbackPatient(medic)
	local cprState = BFA.State.cpr[CharacterKey(medic)]
	if cprState ~= nil
		and IsCrewHuman(cprState.patient)
		and cprState.patient.TeamID == medic.TeamID
		and NeedsResuscitation(cprState.patient)
		and CloseEnoughToTreat(medic, cprState.patient)
	then
		local allowed = Policy.GetTreatmentMode(medic, cprState.patient)
		if allowed then return cprState.patient end
	end

	local selected = SafeProperty(medic, "SelectedCharacter", nil)
	if IsCrewHuman(selected) and selected.TeamID == medic.TeamID and CharacterInjuryScore(selected) > 0 then
		local allowed = Policy.GetTreatmentMode(medic, selected)
		if allowed then return selected end
	end

	local bestPatient = nil
	local bestScore = 0
	if Character == nil or Character.CharacterList == nil then return nil end

	local medicDuty = Policy.GetDutyState(medic)
	local canHelpOthers = IsMedicalJob(medic)
		or GetMedicalSkill(medic) >= BFA.Settings.highSkillMedicalThreshold
		or (medicDuty ~= nil and medicDuty.rescueDominant == true)
	if canHelpOthers then
		for _, patient in pairs(Character.CharacterList) do
			if IsCrewHuman(patient) and patient.TeamID == medic.TeamID and patient ~= medic then
				local score = CharacterInjuryScore(patient)
				local boneScore = PatientFunctionalBoneScore(patient)
				local allowed = Policy.GetTreatmentMode(medic, patient)
				local eligible = score >= BFA.Settings.otherCareMinimumScore
					or (boneScore > 0 and score <= BFA.Settings.otherCareMinimumScore)
				if allowed and CloseEnoughToTreat(medic, patient) and eligible then
					local selectionScore = score
					if score <= BFA.Settings.otherCareMinimumScore then
						selectionScore = selectionScore + math.min(boneScore, 20)
					end
					if selectionScore > bestScore then
						bestPatient = patient
						bestScore = selectionScore
					end
				end
			end
		end
		if bestPatient ~= nil then return bestPatient end
	end

	for _, patient in pairs(Character.CharacterList) do
		if IsCrewHuman(patient) and patient.TeamID == medic.TeamID and patient == medic then
			local score = CharacterInjuryScore(patient)
			local allowed = Policy.GetTreatmentMode(medic, patient)
			local stabilizedPause = HasCooldown(BFA.State.stabilizedCooldowns, CharacterKey(patient))
				and not PatientHasUnstableEmergency(patient)
				and score < BFA.Settings.selfCareSevereScore
			if allowed and not stabilizedPause and score > bestScore then
				bestPatient = patient
				bestScore = score
			end
		end
	end

	return bestPatient
end

local function TrySetTreatmentSuitability(itemIdentifier, afflictionIdentifier, suitability)
	if ItemPrefab == nil or Identifier == nil then return false end

	local ok, changed = pcall(function()
		local prefab = ItemPrefab.GetItemPrefab(itemIdentifier)
		if prefab == nil or prefab.TreatmentSuitabilities == nil then return false end
		prefab.TreatmentSuitabilities[Identifier(afflictionIdentifier)] = suitability
		return true
	end)
	if ok and changed then return true end

	ok, changed = pcall(function()
		local prefab = ItemPrefab.GetItemPrefab(itemIdentifier)
		if prefab == nil or prefab.TreatmentSuitabilities == nil then return false end
		prefab.TreatmentSuitabilities[afflictionIdentifier] = suitability
		return true
	end)

	return ok and changed == true
end

local treatmentVocabulary = {
	-- Bleeding and wound closure.
	suture = {
		bleeding = 35,
		bleedingnonstop = 110,
		lacerations = 135,
		bitewounds = 125,
		gunshotwound = 140,
		explosiondamage = 130,
		surgeryincision = 160,
	},
	antibleeding1 = {
		bleeding = 75,
		bleedingnonstop = 20,
		lacerations = 55,
		bitewounds = 45,
		gunshotwound = 55,
		explosiondamage = 45,
		ll_fracture = 45,
		rl_fracture = 45,
		la_fracture = 45,
		ra_fracture = 45,
	},
	bandage = {
		bleeding = 75,
		bleedingnonstop = 20,
		lacerations = 55,
		bitewounds = 45,
		gunshotwound = 55,
		explosiondamage = 45,
		ll_fracture = 45,
		rl_fracture = 45,
		la_fracture = 45,
		ra_fracture = 45,
	},
	antibleeding2 = {
		bleeding = 75,
		bleedingnonstop = 30,
		lacerations = 70,
		bitewounds = 60,
		gunshotwound = 70,
		explosiondamage = 60,
		burn = 45,
		infectedwound = 15,
	},
	antibleeding3 = {
		bleeding = 85,
		bleedingnonstop = 35,
		lacerations = 80,
		bitewounds = 70,
		gunshotwound = 80,
		explosiondamage = 70,
		burn = 60,
		infectedwound = 80,
	},
	tourniquet = {
		ll_arterialcut = 110,
		rl_arterialcut = 110,
		la_arterialcut = 110,
		ra_arterialcut = 110,
		bleedingnonstop = 70,
		h_arterialcut = -80,
		t_arterialcut = -80,
	},
	tweezers = {
		foreignbody = 85,
		gunshotwound = 15,
		explosiondamage = 15,
	},

	-- Removing temporary treatment that can become harmful later.
	traumashears = {
		dirtybandage = 120,
		arteriesclamp = 95,
		bandaged = 15,
		gypsumcast = 10,
	},
	divingknife = {
		dirtybandage = 65,
		arteriesclamp = 55,
		bandaged = 10,
	},

	-- Fractures and dislocations. Kept intentionally lower than life-saving care.
	gypsum = {
		ll_fracture = 115,
		rl_fracture = 115,
		la_fracture = 115,
		ra_fracture = 115,
	},
	wrench = {
		dislocation1 = 20,
		dislocation2 = 20,
		dislocation3 = 20,
		dislocation4 = 20,
	},
	heavywrench = {
		dislocation1 = 25,
		dislocation2 = 25,
		dislocation3 = 25,
		dislocation4 = 25,
	},
	repairpack = {
		dislocation1 = 25,
		dislocation2 = 25,
		dislocation3 = 25,
		dislocation4 = 25,
	},

	-- Circulation, oxygenation and resuscitation.
	antibloodloss1 = {
		bloodloss = 75,
		bloodpressure = 55,
	},
	ringerssolution = {
		bloodloss = 95,
		bloodpressure = 85,
		hypoxemia = 25,
		acidosis = 20,
		alkalosis = 20,
	},
	-- Blood bags are useful in severe bloodloss, but lower than Ringer/saline so bots
	-- do not waste them on mild cases.
	antibloodloss2 = {
		bloodloss = 80,
		bloodpressure = 65,
		hemotransfusionshock = -100,
	},
	bloodpackominus = {
		bloodloss = 80,
		bloodpressure = 65,
	},
	bloodpackoplus = {
		bloodloss = 55,
		bloodpressure = 45,
	},
	bloodpackaminus = {
		bloodloss = 55,
		bloodpressure = 45,
	},
	bloodpackaplus = {
		bloodloss = 55,
		bloodpressure = 45,
	},
	bloodpackbminus = {
		bloodloss = 55,
		bloodpressure = 45,
	},
	bloodpackbplus = {
		bloodloss = 55,
		bloodpressure = 45,
	},
	bloodpackabminus = {
		bloodloss = 55,
		bloodpressure = 45,
	},
	bloodpackabplus = {
		bloodloss = 55,
		bloodpressure = 45,
	},
	bvm = {
		respiration = 40,
		oxygenlow = 105,
		hypoxemia = 95,
		respiratoryarrest = 105,
		cardiacarrest = 25,
	},
	liquidoxygenite = {
		oxygenlow = 100,
		hypoxemia = 100,
		cerebralhypoxia = 35,
		respiratoryarrest = 70,
	},
	autocpr = {
		cardiacarrest = 115,
		respiratoryarrest = 85,
		oxygenlow = 40,
	},
	adrenaline = {
		cardiacarrest = 125,
		bloodpressure = 35,
		sym_unconsciousness = 15,
	},
	aed = {
		cardiacarrest = 120,
		fibrillation = 125,
		tachycardia = 60,
	},
	defibrillator = {
		cardiacarrest = 110,
		fibrillation = 115,
		tachycardia = 55,
	},

	-- Other first-aid level Neurotrauma items.
	needle = {
		pneumothorax = 100,
		tamponade = 75,
	},
	ointment = {
		burn = 70,
		burn_deg1 = 80,
		burn_deg2 = 65,
		infectedwound = 85,
	},
	gelipack = {
		blunttrauma = 65,
		inflammation = -100,
		infectedwound = -100,
	},
	antibiotics = {
		infectedwound = 70,
		sepsis = 100,
	},
	antinarc = {
		opiateoverdose = 110,
		opiateaddiction = -40,
	},
	streptokinase = {
		heartattack = 95,
		hemotransfusionshock = 40,
		stroke = -100,
	},
	stabilozine = {
		heartattack = 55,
		hemotransfusionshock = 35,
	},
	mannitol = {
		cerebralhypoxia = 45,
	},
}

local discouragedBotTreatments = {
	aed = {
		cardiacarrest = -1000,
		fibrillation = -1000,
		tachycardia = -1000,
	},
	defibrillator = {
		cardiacarrest = -1000,
		fibrillation = -1000,
		tachycardia = -1000,
	},
	autocpr = {
		cardiacarrest = -1000,
		respiratoryarrest = -1000,
		oxygenlow = -1000,
	},
	bvm = {
		cardiacarrest = -1000,
		respiratoryarrest = -1000,
		oxygenlow = -1000,
		hypoxemia = -1000,
	},
	advscalpel = { sym_unconsciousness = -100, analgesia = -100 },
	multiscalpel = { sym_unconsciousness = -100, analgesia = -100 },
	advhemostat = { bleeding = -25, bleedingnonstop = -25 },
	advretractors = { sym_unconsciousness = -100, analgesia = -100 },
	surgicaldrill = { ll_fracture = -100, rl_fracture = -100, la_fracture = -100, ra_fracture = -100 },
	surgerysaw = { ll_fracture = -100, rl_fracture = -100, la_fracture = -100, ra_fracture = -100 },
	tweezers = { bleeding = -20, dirtybandage = -20 },
	osteosynthesisimplants = { ll_fracture = -100, rl_fracture = -100, la_fracture = -100, ra_fracture = -100 },
	spinalimplant = { t_paralysis = -100 },
}

local function InstallVocabulary()
	if BFA.State.vanillaVocabularyInstalled then return end
	BFA.State.vanillaVocabularyInstalled = true

	if NTConfig ~= nil and NTConfig.Set ~= nil then
		NTConfig.Set("NT_disableBotAlgorithms", false)
	end

	local changed = 0
	for itemIdentifier, treatments in pairs(treatmentVocabulary) do
		for afflictionIdentifier, suitability in pairs(treatments) do
			if TrySetTreatmentSuitability(itemIdentifier, afflictionIdentifier, suitability) then
				changed = changed + 1
			end
		end
	end

	for itemIdentifier, treatments in pairs(discouragedBotTreatments) do
		for afflictionIdentifier, suitability in pairs(treatments) do
			if TrySetTreatmentSuitability(itemIdentifier, afflictionIdentifier, suitability) then
				changed = changed + 1
			end
		end
	end

	Log("installed vanilla bot treatment vocabulary entries: " .. tostring(changed))
end

InstallVocabulary()

BFA.ThinkCooldown = BFA.Settings.assistIntervalTicks
Hook.Add("think", "NT.BotFirstAid.Assist", function()
	if Game ~= nil and not Game.RoundStarted then return end
	if Character == nil or Character.CharacterList == nil then return end

	MaintainBotCPRStates()

	BFA.ThinkCooldown = BFA.ThinkCooldown - 1
	if BFA.ThinkCooldown > 0 then return end
	BFA.ThinkCooldown = BFA.Settings.assistIntervalTicks

	TickCooldowns(BFA.State.actionCooldowns)
	TickCooldowns(BFA.State.botCooldowns)
	TickCooldowns(BFA.State.itemRequests)
	TickCooldowns(BFA.State.stabilizedCooldowns)
	CleanupBotCPRStates()
	RefreshMedicalItemObjectives()
	RefreshSelfCareObjectives()

	local actions = 0
	for _, medic in pairs(Character.CharacterList) do
		if actions >= BFA.Settings.maxActionsPerTick then break end
		if IsCrewHuman(medic) and IsBot(medic) and not PatientIsIncapacitated(medic) then
			StowForbiddenComplexMedicalEquipment(medic)
			if ProcessMedicalItemFetch(medic) then
				actions = actions + 1
			else
				local patient = FindBestFallbackPatient(medic)
				if patient ~= nil then
					local actionKey = CooldownKey(medic, CharacterKey(patient))
					local bypassCooldown = medic ~= patient and NeedsResuscitation(patient)
					if (bypassCooldown or not HasCooldown(BFA.State.botCooldowns, CharacterKey(medic)))
						and (bypassCooldown or not HasCooldown(BFA.State.actionCooldowns, actionKey))
					then
						if TryFallbackTreatment(medic, patient) then
							SetCooldown(BFA.State.actionCooldowns, actionKey, BFA.Settings.actionCooldownTicks)
							SetCooldown(BFA.State.botCooldowns, CharacterKey(medic), BFA.Settings.botCooldownTicks)
							if medic == patient and not PatientHasUnstableEmergency(patient) then
								SetCooldown(BFA.State.stabilizedCooldowns, CharacterKey(patient), BFA.Settings.stabilizedCooldownTicks)
							end
							actions = actions + 1
						elseif not bypassCooldown then
							-- Nothing to do for this patient right now. Set a cooldown so the bot
							-- does not spin re-evaluating the same treated patient every tick
							-- (especially visible when the bot has a manual rescue order active).
							SetCooldown(BFA.State.actionCooldowns, actionKey, BFA.Settings.actionCooldownTicks)
						end
					end
				else
					ClearSelfCareObjective(CharacterKey(medic))
					ReturnBorrowedSpecialtyTools(medic)
				end
			end
		end
	end
end)

Hook.Add("roundStart", "NT.BotFirstAid.AssistRoundStart", function()
	BFA.State.actionCooldowns = {}
	BFA.State.botCooldowns = {}
	BFA.State.procedures = {}
	BFA.State.itemRequests = {}
	BFA.State.itemObjectives = {}
	BFA.State.itemFetches = {}
	BFA.State.selfCareObjectives = {}
	BFA.State.stabilizedCooldowns = {}
	BFA.State.cpr = {}
end)
