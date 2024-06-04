--Has to wait to avoid data jamming. 

Hook.Add("roundStart","InitWatch",function()
if not CLIENT then return end
watchinit = {}
Timer.Wait(function()
	for _,watch in pairs (Item.ItemList) do
		if watch.Prefab.Identifier == "divingwatch" then
		watchinit[watch] = 
		{
			initseconds = 0,
			initmintues = 0
		}
		end
		
	end
end, 3000) 
end)

Hook.Add("roundEnd","ClearWatch",function()
if not CLIENT then return end
watchinit = {}
end)



Hook.Add("Watch","Watch",function(effect, deltaTime, item, targets, worldPosition)
if not CLIENT then return end
watchinit[item].initseconds = watchinit[item].initseconds + 1
if watchinit[item].initseconds == 60 then
watchinit[item].initmintues = watchinit[item].initmintues + 1
watchinit[item].initseconds = 0
end


item.Description = "Used by diviers to count time.\nTimer: "..formattime(watchinit[item].initmintues*60 + watchinit[item].initseconds)

end)


Hook.Add("ResetWatch","ResetWatch",function(effect, deltaTime, item, targets, worldPosition)
if not CLIENT then return end
watchinit[item].initseconds = 0
watchinit[item].initmintues = 0
end)
Hook.Add("AddTime","AddTime",function(effect, deltaTime, item, targets, worldPosition)
if not CLIENT then return end
watchinit[item].initseconds = watchinit[item].initseconds + 10
end)
Hook.Add("MinusTime","MinusTime",function(effect, deltaTime, item, targets, worldPosition)
if not CLIENT then return end
watchinit[item].initseconds = watchinit[item].initseconds - 10
end)

function formattime(seconds)
	local minutes = math.floor(seconds / 60)
	local seconds_remainder = seconds % 60
	return string.format("%02d:%02d", minutes, seconds_remainder)
end

function DH.distanceBetween(point1, point2)
    local xd = point1.X - point2.X
    local yd = point1.Y - point2.Y
    return math.sqrt(xd*xd + yd*yd)
end

function DH.FindDepth(item)
    if SERVER then
      return Level.Loaded.GetRealWorldDepth(item.WorldPosition.Y)
    else
      return item.WorldPosition.Y * Physics.DisplayToRealWorldRatio
    end
end

Hook.Add("WatchPanel","WatchPanel",function(effect, deltaTime, item, targets, worldPosition)
	--if item.ParentInventory == nil or item.ParentInventory.Owner == nil then return end
	if not CLIENT or not item.ParentInventory.Owner.IsLocalPlayer then return end
	
	if item.ParentInventory.Owner.CurrentHull then
	local inputString = string.lower(item.ParentInventory.Owner.CurrentHull.RoomName)
	roomNameWatch = inputString:gsub("roomname.", "")
	--local temperature = gas.GetTemperature(item.ParentInventory.Owner.CurrentHull)
	
	subDistance = "NA "
	
	waterDepth = "NA "
	
	else
	roomNameWatch = "NA "
	subDistance = string.format("%.2f", DH.distanceBetween(Submarine.MainSub.WorldPosition,item.WorldPosition)/100).."m "
	
	waterDepth = string.format("%.1f",DH.FindDepth(item)).."m "
	end
	
	local speed = string.format("%.2f", item.ParentInventory.Owner.CurrentSpeed)
	
	local frame = GUI.Frame(GUI.RectTransform(Vector2(0.3, 0.2)), nil)
		frame.CanBeFocused = false

	local display = formattime(watchinit[item].initmintues*60 + watchinit[item].initseconds)
	local text = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), frame.RectTransform), " SPD: "..speed.."m/s ".."SubDis: "..subDistance.."Depth: "..waterDepth.." Room: "..roomNameWatch..(" Timer: "..tostring(display)), nil, nil, GUI.Alignment.Center)
	--local button = GUI.Button(GUI.RectTransform(Vector2(0.2, 0.2), frame.RectTransform, GUI.Anchor.TopRight), "Custom GUI Example", GUI.Alignment.Center, "PowerButton")This is an powerbutton
	
		frame.AddToGUIUpdateList()
end)