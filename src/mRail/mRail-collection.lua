--- Train Collection Depot
-- @module depot-collection
-- @author Sam Lane
-- @copyright 2020-21

-- Load APIs
mRail = require("./mRail/mRail-api")
json = require("./mRail/json")
log = require("./mRail/log")

-- TODO - Comment everything
-- TODO - Add more error checking
-- TODO - Add support for more train types

-- Program config
local config = {}

-- Peripherals
local monitor
local sorter
local modem
local loco_chest
local cart_chest
local dispenser

-- Loops through slots in cart_chest in range upperSlot
-- to lowerSlot to find a space to insert item
local function putAway(lowerSlot, upperSlot)
	local success = 0
	local i = lowerSlot
	while success == 0 do
		success = cart_chest.pullItems(config.sorter,1,1,i)
		log.trace("Slot " .. tostring(i) .. " " .. success)
		i = i + 1
    -- If we have reached the upper slot without managing to insert a cart
    -- then bail and throw an error
		if i == upperSlot then
      mRail.raise_error("Unable to insert cart into chest", 1)
      log.error("Unable to insert cart into chest")
			success = true
		end
	end
end

-- Puts a locomotive away into the loco chest at slot index
local function trainAway(index)
	log.trace("Putting train away into slot " .. index)
  -- Check if the insertion was sucessful
	if loco_chest.pullItems(config.sorter,1,1,index) then
    log.trace("Train away sucessfully")
  else
    -- If not then there must be another train there
    local message = "Failed to insert train into slot " .. index
    log.error(message)
    mRail.raise_error(message, 1)
  end
end

-- Puts a given number of carts away into the cart chest
local function cartAway(amount)
	for j = 1, amount do
		log.trace("Putting cart " .. j .. " away")
		putAway(1,18)
	end
end

-- Puts a given number of anchors away into the cart chest
local function anchorAway(amount)
	for j = 1, amount do
		log.trace("Putting anchor away")
		putAway(19,27)
	end
end

-- Collects a train with service ID and puts it into the two chests
-- and notifies all listening services that the train is now in the depot
local function collectTrain(serviceID)
  -- Loop over each slot in the dispenser
	for i = 1,3 do
    -- Check that there was an item in the slot by pushing it into the sorter
		while dispenser.pushItems(config.sorter,i,1,1) == 1 do
      -- Analyse the item to get metadata (needed to determine info on the train ID)
			info = sorter.analyze()
			log.debug("Amount: " .. info.amount)
      -- Check what type of item was detected
			if info.name == mRail.item_names["train"] or info.name == mRail.item_names["e_train"] then
				log.debug("Found train")
				trainID = mRail.color_to_number(info.nbt.secondaryColor)
				trainAway(trainID)
				log.debug("TrainID: " .. trainID)
				log.debug("ServiceID: " .. serviceID)
				mRail.detection_broadcast(config.id, serviceID and serviceID or "", trainID, "In " .. mRail.location_name[tonumber(config.id)])
			elseif info.name == mRail.item_names["cart"] then
				log.debug("Found cart")
				cartAway(info.amount)
			elseif info.name == mRail.item_names["anchor"] then
				log.debug("Found anchor")
				anchorAway(info.amount)
			else
        mRail.rase_error("Non-sortable item found", 1)
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
  
  -- Load peripherals
  sorter = peripheral.wrap(config.sorter)
  modem = peripheral.wrap(config.modemSide)
  modem.open(mRail.channels.ping_request_channel)

  loco_chest = peripheral.wrap(config.loco)
  cart_chest = peripheral.wrap(config.cart)
  dispenser = peripheral.wrap(config.dispenser)
  
  if config.monitor == nil or config.monitor == "term" then
    monitor = term
  else
    monitor = peripheral.wrap(config.monitor)
  end
  
  -- Setup terminal
  monitor.clear()
  monitor.setCursorPos(1,1)
  log.info("Current Configuration")
	log.info("System ID: 	" .. config.id)
	log.info("Name:		" .. config.name)
	log.info("Modem Side:	" .. config.modemSide)
end

function program.handleMinecart(side, loco, locoName, primary, secondary, destination)
  -- When a train is detected wait 7 seconds for the rest to be loaded into the dispenser
	log.info("Service " .. tostring(destination) .. " detected")
	sleep(7)
	log.debug("Collecting")
  -- then collect the train
	collectTrain(destination)
end

function program.handleRedstone()
  
end

function program.onLoop()
	
end

return program