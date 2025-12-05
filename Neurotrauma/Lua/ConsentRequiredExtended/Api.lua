-- Consent Required API
-- Any Lua script can access this API by adding this line:
-- local Api = require "com.github.cintique.ConsentRequired.Api"
local Environment = require("ConsentRequiredExtended.Util.Environment")
local Barotrauma = require("ConsentRequiredExtended.Util.Barotrauma")

local _ENV = Environment.PrepareEnvironment(_ENV)

-- Table of identifiers (strings) of items that when used
-- as a treatment on an NPC from a different team,
-- causes that NPC (and their allies) to become hostile
-- towards the player.
local affectedItems = {}

---Adds an item (by identifier string) to `affectedItems`.
---@param identifier string
function AddAffectedItem(identifier)
	table.insert(affectedItems, identifier)
end

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.AbandonedOutpostMission"], "requireRescue")

-- Character type doesn't have tags we can assign a custom "rescuetarget" tag to
-- So instead we just hold characters which need rescue in a table and compare their entity IDs
-- This table is only resfreshed on roundstart
local rescuetargets = {}

---Returns a boolean indicating whether a given item is affected or not.
---@param identifier string The identifier of the item that we are testing.
---@return boolean isAffected True if the item is affected, false otherwise.
function IsItemAffected(identifier)
	for _, item in pairs(affectedItems) do
		if item == identifier or HF.StartsWith(identifier, item) then
			return true
		end
	end
	return false
end

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.HumanAIController"], "RespondToAttack")

local ADD_ATTACKER_DAMAGE = 130 -- Heelge: this used to max out negative rep gain, now only around 4 negative rep, any less negative rep is too forgiving.

---@param aiChar Barotrauma_Character The AI character to be made hostile.
---@param instigator Barotrauma_Character The character to be the target of the AI's wrath.
function makeHostile(aiChar, instigator)
	--There is a bit of code which causes attackresults without afflictions to get discarded if some other affliction happens whichin a second
	--That one was "fun" to debug
	--aiChar.AIController.OnAttacked(instigator, Barotrauma.AttackResult.NewAttackResultFromDamage(ADD_ATTACKER_DAMAGE))
	Timer.Wait(function()
		aiChar.AIController.RespondToAttack(instigator, Barotrauma.AttackResult.NewAttackResultFromDamage(ADD_ATTACKER_DAMAGE))
		aiChar.AddAttacker(instigator, ADD_ATTACKER_DAMAGE)
	end, 500)
	-- as this bypasses usual npc reaction timer add a bit of delay to make it not instant
end

---@param char1 Barotrauma_Character Character one.
---@param char2 Barotrauma_Character Character two.
---@return boolean charactersAreOnSameTeam True if characters one & two are on the same team, false otherwise.
function isOnSameTeam(char1, char2)
	local team1 = char1.TeamID
	local team2 = char2.TeamID
	return team1 == team2
end

---Updates current rescue targets list, separate so we dont cycle thru all missions every time we apply item to chacter. Use IsRescueTarget(target) after this.
function UpdateRescueTargets()
	rescuetargets = {}
	for mission in Game.GameSession.Missions do
		if LuaUserData.IsTargetType(mission.Prefab.MissionClass, "Barotrauma.AbandonedOutpostMission") then
			for character in mission.requireRescue do
				rescuetargets[character.ID] = character
				--table.insert(rescuetargets, character)
			end
		end
	end
	-- print('rescue targets =')
	-- for char in rescuetargets do print(char.Name) end
end

---@param target Barotrauma_Character The character we want to confirm as being rescued
---@return boolean consent True if target is rescue mission target, false otherwise
function IsRescueTarget(target)
	-- for char in rescuetargets do
	--     if target.ID == char.ID then return true end
	-- end
	if rescuetargets[target.ID] ~= nil then
		return true
	end
	return false
end

---@param user Barotrauma_Character The character who desires consent.
---@param target Barotrauma_Character The character who gives consent
---@return boolean consent True if consent is given, false otherwise.
function hasConsent(user, target)
	return isOnSameTeam(user, target) or target.IsEscorted or IsRescueTarget(target) -- No longer needs to be shared.
end

---@param aiChar Barotrauma_Character The (AI but not necessarily) character whose sight is being tested.
---@param target Barotrauma_Character The character to be seen.
---@return boolean aiCanSeeTarget True if the AI can see the target character.
function canAiSeeTarget(aiChar, target)
	-- I'll just use what Barotrauma uses for witness line of sight
	local aiVisibleHulls = aiChar.GetVisibleHulls()
	local targetCurrentHull = target.CurrentHull
	for _, visibleHull in pairs(aiVisibleHulls) do
		if targetCurrentHull == visibleHull then
			return true
		end
	end
	return false
end

---@param user Barotrauma_Character The character of the instigator being witnessed.
---@param victim Barotrauma_Character The character of the victim of the crime being witnessed.
---@return Barotrauma_Character[] Characters that have witnessed the crime.
function getWitnessesToCrime(user, victim)
	local witnesses = {}
	for _, char in pairs(Character.CharacterList) do
		if
			not char.Removed
			and not char.IsUnconscious
			and char.IsBot
			and char.IsHuman
			and isOnSameTeam(char, victim)
		then
			local isWitnessingUser = canAiSeeTarget(char, user)
			if isWitnessingUser then
				table.insert(witnesses, char)
			end
		end
	end
	return witnesses
end

---@param user Barotrauma_Character The character that is applying the affected item.
---@param target Barotrauma_Character The character of the target of the affected item's application.
function onAffectedItemApplied(user, target)
	if not hasConsent(user, target) and target.IsBot and target.IsHuman then
		if not target.IsIncapacitated and target.Stun <= 10 then
			makeHostile(target, user)
		else
			-- Vanilla Barotrauma Human AI doesn't care what you do to their unconscious teammates, even shooting them in the head
			-- Let's fix that for this particular case of mistreatment
			local witnesses = getWitnessesToCrime(user, target)
			for _, witness in pairs(witnesses) do
				makeHostile(witness, user)
			end
		end
	end
end

return Environment.Export(_ENV)
