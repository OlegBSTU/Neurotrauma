-- NT functions for multiscalpel mode setting
-- Hooks XML Lua events defined in the multiscalpel item.xml
-- Hooks Lua event "roundStart" to RefreshAllMultiscalpels descriptions
function NT.SetMultiscalpelFunction(item, func)
	if func ~= "" then
		item.Tags = "multiscalpel_" .. func
	else
		item.Tags = ""
	end
	NT.RefreshScalpelDescription(item)
end

local function GetMultiscalpelMode(item)
	local functiontag = ""
	local tags = HF.SplitString(item.Tags, ",")
	for tag in tags do
		if HF.StartsWith(tag, "multiscalpel_") then
			functiontag = HF.SplitString(tag, "_")[2]
			break
		end
	end

	return functiontag
end

function NT.RefreshScalpelDescription(item)
	-- if not HF.ItemHasTag(item,"init") then return end
	-- hostside only
	if Game.IsMultiplayer and CLIENT then
		return
	end

	if not Entity.Spawner then
		Timer.Wait(function()
			NT.RefreshScalpelDescription(item)
		end, 35)
		return
	end

	local functiontag = GetMultiscalpelMode(item)

	local description = ""
	if functiontag ~= "" then
		description = HF.GetText("multiscalpel." .. functiontag)
	end

	if description == "" then
		return
	end

	local targetinventory = item.ParentInventory
	local targetslot = 0
	if targetinventory ~= nil then
		targetslot = targetinventory.FindIndex(item)
	end

	local function SpawnFunc(newscalpelitem, targetinventory)
		if targetinventory ~= nil then
			targetinventory.TryPutItem(newscalpelitem, targetslot, true, true, nil)
		end
		newscalpelitem.Description = description
		newscalpelitem.Tags = "multiscalpel_" .. functiontag
	end
	HF.RemoveItem(item)
	Timer.Wait(function()
		local prefab = item.Prefab
		Entity.Spawner.AddItemToSpawnQueue(prefab, item.WorldPosition, nil, nil, function(newscalpelitem)
			SpawnFunc(newscalpelitem, targetinventory)
		end)
	end, 35)
end

Hook.Add("roundStart", "NT.RoundStart.Multiscalpels", function()
	Timer.Wait(function()
		NT.RefreshAllMultiscalpels()
	end, 10000) -- maybe 10 seconds is enough?
end)

function NT.RefreshAllMultiscalpels()
	-- descriptions dont get serialized, so i have to respawn
	-- every scalpel every round to keep their descriptions (big oof)

	-- fetch scalpel items
	local scalpelItems = {}
	for item in Item.ItemList do
		if item.Prefab.Identifier.Value == "multiscalpel" then
			table.insert(scalpelItems, item)
		end
	end
	-- refresh items
	for scalpel in scalpelItems do
		NT.RefreshScalpelDescription(scalpel)
	end
end
Timer.Wait(function()
	NT.RefreshAllMultiscalpels()
end, 50)

Hook.Add(
	"NT.multiscalpel.incision",
	"NT.multiscalpel.incision",
	function(effect, deltaTime, item, targets, worldPosition)
		NT.SetMultiscalpelFunction(item, "incision")
	end
)
Hook.Add("NT.multiscalpel.kidneys", "NT.multiscalpel.kidneys", function(effect, deltaTime, item, targets, worldPosition)
	NT.SetMultiscalpelFunction(item, "kidneys")
end)
Hook.Add("NT.multiscalpel.liver", "NT.multiscalpel.liver", function(effect, deltaTime, item, targets, worldPosition)
	NT.SetMultiscalpelFunction(item, "liver")
end)
Hook.Add("NT.multiscalpel.lungs", "NT.multiscalpel.lungs", function(effect, deltaTime, item, targets, worldPosition)
	NT.SetMultiscalpelFunction(item, "lungs")
end)
Hook.Add("NT.multiscalpel.heart", "NT.multiscalpel.heart", function(effect, deltaTime, item, targets, worldPosition)
	NT.SetMultiscalpelFunction(item, "heart")
end)
Hook.Add("NT.multiscalpel.brain", "NT.multiscalpel.brain", function(effect, deltaTime, item, targets, worldPosition)
	NT.SetMultiscalpelFunction(item, "brain")
end)
Hook.Add("NT.multiscalpel.bandage", "NT.multiscalpel.bandage", function(effect, deltaTime, item, targets, worldPosition)
	NT.SetMultiscalpelFunction(item, "bandage")
end)
Hook.Add(
	"NT.multiscalpel.speedflex",
	"NT.multiscalpel.speedflex",
	function(effect, deltaTime, item, targets, worldPosition)
		NT.SetMultiscalpelFunction(item, "speedflex")
	end
)

NT.ItemMethods.multiscalpel = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	local mode = GetMultiscalpelMode(item)
	if mode == "" then
		mode = "none"
	end

	local modeFunctions = {
		none = function(item, usingCharacter, targetCharacter, limb) end,
		incision = NT.ItemMethods.advscalpel,
		kidneys = NT.ItemMethods.organscalpel_kidneys,
		liver = NT.ItemMethods.organscalpel_liver,
		lungs = NT.ItemMethods.organscalpel_lungs,
		heart = NT.ItemMethods.organscalpel_heart,
		brain = NT.ItemMethods.organscalpel_brain,
		bandage = function(item, usingCharacter, targetCharacter, limb)
			-- remove casts, bandages, and if none of those apply, cause some damage

			-- code snippet taken from NT.ItemMethods.traumashears
			-- does the target have any cuttable afflictions?
			local cuttables = HF.CombineArrays(NT.CuttableAfflictions, NT.TraumashearsAfflictions)
			local canCut = false
			for val in cuttables do
				local prefab = AfflictionPrefab.Prefabs[val]
				if prefab ~= nil then
					if prefab.LimbSpecific then
						if HF.HasAfflictionLimb(targetCharacter, val, limbtype, 0.1) then
							canCut = true
							break
						end
					elseif limbtype == prefab.IndicatorLimb then
						if HF.HasAffliction(targetCharacter, val, 0.1) then
							canCut = true
							break
						end
					end
				end
			end

			if canCut then
				NT.ItemMethods.traumashears(item, usingCharacter, targetCharacter, limb)
			else
				-- malpractice time!!!!
				local open = HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1)
				local istorso = limbtype == LimbType.Torso
				local ishead = limbtype == LimbType.Head

				if not open then
					HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 6 + math.random() * 4, usingCharacter)
					HF.AddAfflictionLimb(
						targetCharacter,
						"lacerations",
						limbtype,
						2.5 + math.random() * 5,
						usingCharacter
					)
					HF.GiveItem(targetCharacter, "ntsfx_slash")
				else
					if istorso then
						-- stabbing an open torso (not good for the organs therein!)

						HF.AddAffliction(targetCharacter, "internalbleeding", 6 + math.random() * 12, usingCharacter)
						HF.AddAfflictionLimb(
							targetCharacter,
							"lacerations",
							limbtype,
							4 + math.random() * 6,
							usingCharacter
						)
						HF.AddAfflictionLimb(
							targetCharacter,
							"internaldamage",
							limbtype,
							4 + math.random() * 6,
							usingCharacter
						)

						local case = math.random()
						local casecount = 4
						if case < 1 / casecount then
							HF.AddAffliction(targetCharacter, "kidneydamage", 10 + math.random() * 10, usingCharacter)
						elseif case < 2 / casecount then
							HF.AddAffliction(targetCharacter, "liverdamage", 10 + math.random() * 10, usingCharacter)
						elseif case < 3 / casecount then
							HF.AddAffliction(targetCharacter, "lungdamage", 10 + math.random() * 10, usingCharacter)
						elseif case < 4 / casecount then
							HF.AddAffliction(targetCharacter, "heartdamage", 10 + math.random() * 10, usingCharacter)
						end
					elseif ishead then
						-- stabbing an open head (brain surgery done right!)

						HF.AddAffliction(targetCharacter, "cerebralhypoxia", 15 + math.random() * 15, usingCharacter)
						HF.AddAfflictionLimb(
							targetCharacter,
							"internaldamage",
							limbtype,
							10 + math.random() * 10,
							usingCharacter
						)
						HF.AddAfflictionLimb(
							targetCharacter,
							"bleeding",
							limbtype,
							6 + math.random() * 12,
							usingCharacter
						)
					else
						-- stabbing an open arm or leg (how to cause fractures)

						HF.AddAfflictionLimb(
							targetCharacter,
							"bleeding",
							limbtype,
							6 + math.random() * 6,
							usingCharacter
						)
						HF.AddAfflictionLimb(
							targetCharacter,
							"lacerations",
							limbtype,
							4 + math.random() * 6,
							usingCharacter
						)
						HF.AddAfflictionLimb(
							targetCharacter,
							"internaldamage",
							limbtype,
							4 + math.random() * 6,
							usingCharacter
						)
						if HF.Chance(0.1) then
							NT.BreakLimb(targetCharacter, limbtype)
						end
					end

					HF.GiveItem(targetCharacter, "ntsfx_slash")
				end
			end
		end,
		speedflex = function(item, usingCharacter, targetCharacter, limb)
			local animcontroller = targetCharacter.AnimController
			local torsoLimb = limb
			if animcontroller ~= nil then
				torsoLimb = animcontroller.MainLimb
			end

			if limbtype == LimbType.Head then
				NT.ItemMethods.organscalpel_brain(item, usingCharacter, targetCharacter, limb)
			elseif limbtype == LimbType.LeftArm then
				NT.ItemMethods.organscalpel_kidneys(item, usingCharacter, targetCharacter, torsoLimb)
			elseif limbtype == LimbType.Torso then
				NT.ItemMethods.organscalpel_liver(item, usingCharacter, targetCharacter, torsoLimb)
			elseif limbtype == LimbType.RightArm then
				NT.ItemMethods.organscalpel_heart(item, usingCharacter, targetCharacter, torsoLimb)
			elseif limbtype == LimbType.LeftLeg then
				NT.ItemMethods.organscalpel_lungs(item, usingCharacter, targetCharacter, torsoLimb)
			end
		end,
	}

	if modeFunctions[mode] ~= nil then
		modeFunctions[mode](item, usingCharacter, targetCharacter, limb)
	end

	if mode ~= "none" then
		Timer.Wait(function()
			item.Tags = "multiscalpel_" .. mode
		end, 50)
	end
end
