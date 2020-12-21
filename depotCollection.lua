-- mRail Collection Depot
-- (C) 2020 Sam Lane

os.loadAPI("mRail.lua")


-- Configuration
local config = {}
-- Default config values:
config.id = 0
config.name = "Depot"
config.modem_side = "top"

config_name = ".config"

local function putAway(lowerSlot, upperSlot)
	local success = 0
	local i = lowerSlot
	while success == 0 do
		success = cart_chest.pullItems("back",1,1,i)
		print("Slot " .. tostring(i) .. " " .. success)
		i = i + 1
		if i == upperSlot then
			success = true
		end
	end
end

local function trainAway(index)
	print("Putting train away into slot " .. index)
	loco_chest.pullItems("back",1,1,index)
end

local function cartAway(amount)
	for j = 1, amount do
		print("Putting cart " .. j .. " away")
		putAway(1,18)
	end
end

local function anchorAway(amount)
	for j = 1, amount do
		print("Putting anchor away")
		putAway(19,27)
	end
end

local function collectTrain(serviceID)
	for i = 1,3 do
		while dispenser.pushItems("back",i,1,1) == 1 do
			info = sorter.analyze()
			print("Amount: " .. info.amount)
			if info.name == mRail.item_names["train"] or info.name == mRail.item_names["e_train"] then
				print("Found train")
				trainID = mRail.color_to_number(info.nbt.secondaryColor)
				trainAway(trainID)
				print("TrainID: " .. trainID)
				print("ServiceID: " .. serviceID)
				mRail.detection_broadcast(modem, config.id, serviceID, trainID, "In " .. mRail.location_name[tonumber(config.id)])
			elseif info.name == mRail.item_names["cart"] then
				print("Found cart")
				cartAway(info.amount)
			elseif info.name == mRail.item_names["anchor"] then
				print("Found anchor")
				anchorAway(info.amount)
			else
				-- Error, not a sortable item!!!
			end
		end
	end
end

-- Main program

sorter = peripheral.wrap("back")
modem = peripheral.wrap("top")

loco_chest = peripheral.wrap("right")
cart_chest = peripheral.wrap("left")
dispenser = peripheral.wrap("bottom")

mRail.loadConfig(modem,config_name,config)


term.clear()
while true do
	term.clear()
	term.setCursorPos(1,1)
	print("Current Configuration")
	print("System ID: 	" .. config.id)
	print("Name:		" .. config.name)
	print("Modem Side:	" .. config.modem_side)
	print("")
	print("")
	
	
	print("Waiting for train")
	event, side, loco, locoName, primary, secondary, destination = os.pullEvent("minecart")
	print("Service " .. destination .. " detected")
	sleep(7)
	print("Collecting")
	collectTrain(destination)
end