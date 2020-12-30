-- mRail System Program Base
-- (C) 2020-21 Sam Lane

mRail = require("./mRail/mRail-api")
json = require("./mRail/json")
log = require("./mRail/log")

-- TODO - Comment everything
-- TODO - Add more error checking
-- TODO - Add support for more train types

local config = {}

local monitor

local sorter
local modem

local loco_chest
local cart_chest
local dispenser

-- Loops through slots in cart_chest 
local function putAway(lowerSlot, upperSlot)
	local success = 0
	local i = lowerSlot
	while success == 0 do
		success = cart_chest.pullItems(config.sorter,1,1,i)
		log.trace("Slot " .. tostring(i) .. " " .. success)
		i = i + 1
		if i == upperSlot then
			success = true
		end
	end
end

local function trainAway(index)
	log.trace("Putting train away into slot " .. index)
	loco_chest.pullItems(config.sorter,1,1,index)
end

local function cartAway(amount)
	for j = 1, amount do
		log.trace("Putting cart " .. j .. " away")
		putAway(1,18)
	end
end

local function anchorAway(amount)
	for j = 1, amount do
		log.trace("Putting anchor away")
		putAway(19,27)
	end
end

local function collectTrain(serviceID)
	for i = 1,3 do
		while dispenser.pushItems(config.sorter,i,1,1) == 1 do
			info = sorter.analyze()
			log.debug("Amount: " .. info.amount)
			if info.name == mRail.item_names["train"] or info.name == mRail.item_names["e_train"] then
				log.debug("Found train")
				trainID = mRail.color_to_number(info.nbt.secondaryColor)
				trainAway(trainID)
				log.debug("TrainID: " .. trainID)
				log.debug("ServiceID: " .. serviceID)
				mRail.detection_broadcast(modem, config.id, serviceID, trainID, "In " .. mRail.location_name[tonumber(config.id)])
			elseif info.name == mRail.item_names["cart"] then
				log.debug("Found cart")
				cartAway(info.amount)
			elseif info.name == mRail.item_names["anchor"] then
				log.debug("Found anchor")
				anchorAway(info.amount)
			else
				log.error("Not a sortable item")
			end
		end
	end
end

-- From which all other programs are derived...
local program = {}

-- Program Functions
function program.setup(config_)
  config = config_
  
  sorter = peripheral.wrap(config.sorter)
  modem = peripheral.wrap(config.modemSide)

  loco_chest = peripheral.wrap(config.loco)
  cart_chest = peripheral.wrap(config.cart)
  dispenser = peripheral.wrap(config.dispenser)
  
  if config.monitor == nil or config.monitor == "term" then
    monitor = term
  else
    monitor = peripheral.wrap(config.monitor)
  end
  monitor.clear()
  monitor.setCursorPos(1,1)
  log.info("Current Configuration")
	log.info("System ID: 	" .. config.id)
	log.info("Name:		" .. config.name)
	log.info("Modem Side:	" .. config.modemSide)
end

function program.handleMinecart(destination)
	log.info("Service " .. destination .. " detected")
	sleep(7)
	log.debug("Collecting")
	collectTrain(destination)
end

function program.onLoop()
	
end

return program