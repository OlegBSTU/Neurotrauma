if Hook ~= nil and Hook.Remove ~= nil then
	pcall(function() Hook.Remove("think", "NT.BotInitiative.Think") end)
	pcall(function() Hook.Remove("roundStart", "NT.BotInitiative.RoundStart") end)
end

NT.BotInitiative = { State = { cooldowns = {}, claims = {}, handling = {} } }

local BI = NT.BotInitiative
BI.Settings = {
	intervalTicks = 60,
	cooldownTicks = 180,
	claimTicks = 420,
	handlingGraceTicks = 480,
	criticalHandlingGraceTicks = 120,
	criticalRetryCooldownTicks = 120,
	fractureBandageThreshold = 35,
	highMedicalSkill = 45,
	criticalScore = 25,
	selfCareMinimumScore = 16,
}

local limbTypes = {
	LimbType.Torso,
	LimbType.Head,
	LimbType.LeftArm,
	LimbType.RightArm,
	LimbType.LeftLeg,
	LimbType.RightLeg,
}

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

local function MedicalSkill(character)
	if HF ~= nil and HF.GetSkillLevel ~= nil then return HF.GetSkillLevel(character, "medical") end
	return IsMedicalJob(character) and 50 or 10
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

local function Clamp(value, minimum, maximum)
	if value < minimum then return minimum end
	if value > maximum then return maximum end
	return value
end

local function LimbIsExtremity(limbType)
	if HF ~= nil and HF.LimbIsExtremity ~= nil then return HF.LimbIsExtremity(limbType) end
	return limbType == LimbType.LeftArm
		or limbType == LimbType.RightArm
		or limbType == LimbType.LeftLeg
		or limbType == LimbType.RightLeg
end

local function LimbIsBroken(character, limbType)
	if NT ~= nil and NT.LimbIsBroken ~= nil then return NT.LimbIsBroken(character, limbType) end
	return false
end

local function LimbIsDislocated(character, limbType)
	if NT ~= nil and NT.LimbIsDislocated ~= nil then return NT.LimbIsDislocated(character, limbType) end
	return false
end

local function CharacterKey(character)
	return tostring(character ~= nil and (character.ID or character.Name) or "nil")
end

local function CooldownKey(character, suffix)
	return CharacterKey(character) .. ":" .. tostring(suffix)
end

local function TickCooldowns()
	for key, value in pairs(BI.State.cooldowns) do
		value = value - BI.Settings.intervalTicks
		if value <= 0 then
			BI.State.cooldowns[key] = nil
		else
			BI.State.cooldowns[key] = value
		end
	end
	for key, value in pairs(BI.State.claims) do
		value.ticks = value.ticks - BI.Settings.intervalTicks
		if value.ticks <= 0 then
			BI.State.claims[key] = nil
		end
	end
end

local function HasCooldown(key)
	return BI.State.cooldowns[key] ~= nil and BI.State.cooldowns[key] > 0
end

local function SetCooldown(key)
	BI.State.cooldowns[key] = BI.Settings.cooldownTicks
end

local function SetCooldownTicks(key, ticks)
	BI.State.cooldowns[key] = ticks
end

local function PatientKey(patient)
	return CharacterKey(patient)
end

local function ClaimPatient(helper, patient)
	if helper == nil or patient == nil then return end
	BI.State.claims[PatientKey(patient)] = {
		helper = CharacterKey(helper),
		ticks = BI.Settings.claimTicks,
	}
end

local function IsClaimedByOther(helper, patient)
	local claim = BI.State.claims[PatientKey(patient)]
	if claim == nil then return false end
	return claim.helper ~= CharacterKey(helper)
end

local function PatientFunctionalBoneScore(patient)
	local score = 0
	local affectedLimbs = 0
	for _, limbType in ipairs(limbTypes) do
		if LimbIsExtremity(limbType) then
			local limbAffected = false
			if LimbIsBroken(patient, limbType) and GetAfflictionLimb(patient, limbType, "gypsumcast", 0) <= 0.1 then
				score = score + 45
				limbAffected = true
			end
			if LimbIsDislocated(patient, limbType) then
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

local function IsCriticalPatient(patient)
	return patient ~= nil
		and not patient.Removed
		and not patient.IsDead
		and (GetAffliction(patient, "cardiacarrest", 0) > 0.1
			or GetAffliction(patient, "respiratoryarrest", 0) > 0.1
			or GetAffliction(patient, "oxygenlow", 0) > 40
			or GetAffliction(patient, "hypoxemia", 0) > 40)
end

local function GetTreatmentPolicy()
	return NT ~= nil and NT.BotEngagementPolicy or nil
end

local function CanTreat(helper, patient)
	local policy = GetTreatmentPolicy()
	if policy == nil or policy.GetTreatmentMode == nil then return true, "legacy" end

	local ok, allowed, mode = pcall(function()
		local canTreat, treatmentMode = policy.GetTreatmentMode(helper, patient)
		return canTreat, treatmentMode
	end)
	if not ok then return true, "legacy_error" end
	return allowed == true, mode
end

local function IsFollowLocked(patient)
	local policy = GetTreatmentPolicy()
	if policy == nil or policy.GetDutyState == nil then return false end

	local ok, state = pcall(function() return policy.GetDutyState(patient) end)
	return ok and state ~= nil and state.follow == true
end

local function IsFetchingMedicalItem(bot)
	return NT ~= nil
		and NT.BotFirstAid ~= nil
		and NT.BotFirstAid.IsFetchingMedicalItem ~= nil
		and NT.BotFirstAid.IsFetchingMedicalItem(bot) == true
end

local function DeselectCharacter(bot)
	pcall(function() bot.DeselectCharacter() end)
	pcall(function() bot.SelectedCharacter = nil end)
end

local function InjuryScore(character)
	local score = GetAffliction(character, "cardiacarrest", 0) * 100
		+ GetAffliction(character, "respiratoryarrest", 0) * 90
		+ GetAffliction(character, "oxygenlow", 0)
		+ GetAffliction(character, "hypoxemia", 0)
		+ GetAffliction(character, "bloodloss", 0)
		+ GetAffliction(character, "internalbleeding", 0) * 2
	local functionalBoneScore = PatientFunctionalBoneScore(character)
	if functionalBoneScore >= 70 then
		score = score + 18
	elseif functionalBoneScore > 0 then
		score = score + 8
	end

	for _, limbType in ipairs(limbTypes) do
		local bleeding = GetAfflictionLimb(character, limbType, "bleeding", 0)
		local nonstop = GetAfflictionLimb(character, limbType, "bleedingnonstop", 0)
		local bandaged = GetAfflictionLimb(character, limbType, "bandaged", 0)
		local sutured = GetAfflictionLimb(character, limbType, "suturedw", 0)
		local dirtyBandage = GetAfflictionLimb(character, limbType, "dirtybandage", 0)
		local tourniquet = GetAfflictionLimb(character, limbType, "arteriesclamp", 0)
		local foreignBody = GetAfflictionLimb(character, limbType, "foreignbody", 0)
		local woundScore = GetAfflictionLimb(character, limbType, "lacerations", 0)
			+ GetAfflictionLimb(character, limbType, "bitewounds", 0)
			+ GetAfflictionLimb(character, limbType, "gunshotwound", 0)
			+ GetAfflictionLimb(character, limbType, "explosiondamage", 0)
		if bleeding <= 0.1 and nonstop <= 0.1 and (bandaged > 0.1 or sutured > 0.1) then
			woundScore = 0
		end

		score = score
			+ bleeding
			+ nonstop * 30
			+ woundScore
			+ GetAfflictionLimb(character, limbType, "burn", 0)
			+ Clamp(dirtyBandage - 5, 0, 40)
			+ Clamp(foreignBody - 5, 0, 45)

		if dirtyBandage >= 10 then score = score + 20 end
		if foreignBody >= 15 then score = score + 25 end
		if tourniquet > 0.1 then score = score + 25 end

		if LimbIsExtremity(limbType) then
			if LimbIsBroken(character, limbType) and GetAfflictionLimb(character, limbType, "gypsumcast", 0) <= 0.1 then
				score = score + 35
				if GetAfflictionLimb(character, limbType, "bandaged", 0) >= BI.Settings.fractureBandageThreshold then
					score = score + 12
				end
			end
			if LimbIsDislocated(character, limbType) then
				score = score + 28
			end
		end
	end

	return score
end

local function HasOtherCriticalPatient(helper, selected)
	if Character == nil or Character.CharacterList == nil then return false end

	for _, patient in pairs(Character.CharacterList) do
		if patient ~= selected
			and IsCrewHuman(patient)
			and patient.TeamID == helper.TeamID
			and patient ~= helper
			and IsCriticalPatient(patient)
			and not IsClaimedByOther(helper, patient)
		then
			return true
		end
	end

	return false
end

local function IsHandlingSelectedPatient(helper)
	local selected = SafeProperty(helper, "SelectedCharacter", nil)
	if selected == nil or not IsCrewHuman(selected) or selected.TeamID ~= helper.TeamID then
		BI.State.handling[CharacterKey(helper)] = nil
		return false
	end

	local selectedScore = InjuryScore(selected)
	if selectedScore <= 0.1 then
		BI.State.handling[CharacterKey(helper)] = nil
		return false
	end
	if IsFollowLocked(selected) then
		BI.State.handling[CharacterKey(helper)] = nil
		DeselectCharacter(helper)
		return false
	end
	local canTreatSelected = CanTreat(helper, selected)
	if not canTreatSelected then
		BI.State.handling[CharacterKey(helper)] = nil
		DeselectCharacter(helper)
		return false
	end

	ClaimPatient(helper, selected)

	local helperKey = CharacterKey(helper)
	local state = BI.State.handling[helperKey]
	if state == nil or state.patient ~= CharacterKey(selected) then
		state = { patient = CharacterKey(selected), ticks = 0 }
		BI.State.handling[helperKey] = state
	end

	if not IsCriticalPatient(selected) and HasOtherCriticalPatient(helper, selected) then
		BI.State.handling[helperKey] = nil
		return false
	end

	if IsCriticalPatient(selected) then
		if IsMedicalJob(helper)
			or MedicalSkill(helper) >= BI.Settings.highMedicalSkill
			or GetAffliction(selected, "cpr_buff", 0) > 0.1
			or GetAffliction(selected, "cpr_fracturebuff", 0) > 0.1
			or (NT ~= nil
				and NT.BotFirstAid ~= nil
				and NT.BotFirstAid.IsSustainingCPR ~= nil
				and NT.BotFirstAid.IsSustainingCPR(helper, selected))
		then
			state.ticks = 0
			SetCooldownTicks(CooldownKey(helper, "others"), BI.Settings.criticalRetryCooldownTicks)
			return true
		end

		BI.State.handling[helperKey] = nil
		state.ticks = 0
		return false
	end

	state.ticks = 0
	SetCooldownTicks(CooldownKey(helper, "others"), BI.Settings.cooldownTicks)
	return true
end

local function FindBestPatientFor(helper)
	local bestPatient = nil
	local bestScore = 0
	if Character == nil or Character.CharacterList == nil then return nil, 0 end

	for _, patient in pairs(Character.CharacterList) do
		if IsCrewHuman(patient) and patient.TeamID == helper.TeamID and patient ~= helper and not IsClaimedByOther(helper, patient) then
			local score = InjuryScore(patient)
			local canTreat = CanTreat(helper, patient)
			if canTreat and score > bestScore then
				bestPatient = patient
				bestScore = score
			end
		end
	end

	return bestPatient, bestScore
end

local function HasActiveNonMedicalObjective(character)
	local ai = SafeProperty(character, "AIController", nil)
	local manager = ai ~= nil and SafeProperty(ai, "ObjectiveManager", nil) or nil
	if manager == nil then return false end
	local ok, result = pcall(function() return manager.HasActiveObjective() end)
	return ok and result == true
end

local function AddRescueAll(bot)
	if NT ~= nil
		and NT.BotFirstAid ~= nil
		and NT.BotFirstAid.EnsureSelfCareObjective ~= nil
		and NT.BotFirstAid.EnsureSelfCareObjective(bot, 1.25)
	then
		return true
	end

	local ai = SafeProperty(bot, "AIController", nil)
	local manager = ai ~= nil and SafeProperty(ai, "ObjectiveManager", nil) or nil
	if manager == nil or AIObjectiveRescueAll == nil then return false end

	local ok, objective = pcall(function()
		return AIObjectiveRescueAll(bot, manager, 1.25)
	end)
	if not ok or objective == nil then
		ok, objective = pcall(function()
			return AIObjectiveRescueAll.__new(bot, manager, 1.25)
		end)
	end
	if not ok or objective == nil then return false end

	pcall(function()
		objective.ForceHighestPriority = true
		objective.OverridePriority = 80
		objective.SpeakIfFails = false
	end)

	local added = pcall(function() manager.AddObjective(objective) end)
	return added == true
end

local function AddRescueTarget(helper, patient)
	local ai = SafeProperty(helper, "AIController", nil)
	local manager = ai ~= nil and SafeProperty(ai, "ObjectiveManager", nil) or nil
	if manager == nil or AIObjectiveRescue == nil or patient == nil then return false end

	local ok, objective = pcall(function()
		return AIObjectiveRescue(helper, patient, manager, 1.25)
	end)
	if not ok or objective == nil then
		ok, objective = pcall(function()
			return AIObjectiveRescue.__new(helper, patient, manager, 1.25)
		end)
	end
	if not ok or objective == nil then return false end

	pcall(function()
		objective.ForceHighestPriority = true
		objective.OverridePriority = IsCriticalPatient(patient) and 100 or 85
		objective.SpeakIfFails = false
	end)

	local added = pcall(function() manager.AddObjective(objective) end)
	return added == true
end

local function ReleaseDeadSelectedTarget(bot)
	local selected = SafeProperty(bot, "SelectedCharacter", nil)
	if selected ~= nil and (selected.IsDead or selected.Removed) then
		pcall(function() bot.DeselectCharacter() end)
		pcall(function() bot.SelectedCharacter = nil end)
	end
end

local function RunInitiative()
	if Game ~= nil and not Game.RoundStarted then return end
	if Character == nil or Character.CharacterList == nil then return end

	TickCooldowns()

	for _, bot in pairs(Character.CharacterList) do
		if IsCrewHuman(bot) and IsBot(bot) then
			ReleaseDeadSelectedTarget(bot)
			if IsFetchingMedicalItem(bot) then
				BI.State.handling[CharacterKey(bot)] = nil
				SetCooldownTicks(CooldownKey(bot, "others"), BI.Settings.criticalRetryCooldownTicks)
			else
				if not IsHandlingSelectedPatient(bot) then
					local ownScore = InjuryScore(bot)
					local canSelfTreat, selfMode = CanTreat(bot, bot)
					if canSelfTreat and selfMode ~= "quick" and ownScore >= BI.Settings.selfCareMinimumScore and not HasCooldown(CooldownKey(bot, "self")) then
						if AddRescueAll(bot) then SetCooldown(CooldownKey(bot, "self")) end
					end

					local isMedic = IsMedicalJob(bot)
					local highSkill = MedicalSkill(bot) >= BI.Settings.highMedicalSkill
					local policy = GetTreatmentPolicy()
					local duty = nil
					if policy ~= nil and policy.GetDutyState ~= nil then
						pcall(function() duty = policy.GetDutyState(bot) end)
					end
					local rescueAssigned = duty ~= nil and duty.rescueDominant == true
					if (isMedic or highSkill or rescueAssigned) and not HasCooldown(CooldownKey(bot, "others")) then
						local patient, patientScore = FindBestPatientFor(bot)
						if patient ~= nil and patientScore >= BI.Settings.criticalScore then
							local cooldownTicks = IsCriticalPatient(patient) and BI.Settings.criticalRetryCooldownTicks or BI.Settings.cooldownTicks
							local canTreatPatient = CanTreat(bot, patient)
							if canTreatPatient and (isMedic or rescueAssigned) then
								if AddRescueTarget(bot, patient) then
									ClaimPatient(bot, patient)
									SetCooldownTicks(CooldownKey(bot, "others"), cooldownTicks)
								end
							elseif canTreatPatient and highSkill and (duty == nil or not duty.activeHighFocus) then
								if AddRescueTarget(bot, patient) then
									ClaimPatient(bot, patient)
									SetCooldownTicks(CooldownKey(bot, "others"), cooldownTicks)
								end
							end
						end
					end
				end
			end
		end
	end
end

BI.ThinkCooldown = BI.Settings.intervalTicks
Hook.Add("think", "NT.BotInitiative.Think", function()
	BI.ThinkCooldown = BI.ThinkCooldown - 1
	if BI.ThinkCooldown <= 0 then
		BI.ThinkCooldown = BI.Settings.intervalTicks
		pcall(RunInitiative)
	end
end)

Hook.Add("roundStart", "NT.BotInitiative.RoundStart", function()
	BI.State.cooldowns = {}
	BI.State.claims = {}
	BI.State.handling = {}
end)
