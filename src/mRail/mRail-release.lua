-- mRail System Program Base
-- (C) 2020-21 Sam Lane

-- TODO - Add more error checking (i.e. if there are enough things available)
-- TODO - Add support for more train types

-- Load APIs
mRail = require("./mRail/mRail-api")
json = require("./mRail/json")
log = require("./mRail/log")

-- Program config
local config = {}

local modem

local loco_chest
local cart_chest
local dispenser
local track

-- Pushes item into dispenser from first available slot
-- in given range lowerSlot to upperSlot from cart chest
function pushFirstItem(lowerSlot, upperSlot, destinationSlot)
	local success = 0
	local i = upperSlot
	while success == 0 do
		success = cart_chest.pushItems(config.dispenser,i,1,destinationSlot)
		log.debug("Slot " .. tostring(i) .. " " .. success)
		i = i - 1
		if i == lowerSlot then
			success = true
		end
	end
end

-- Pushes train from the locomotive chest to the dispenser
function toDispenser(trainID)
  -- Check the train exists (can be pushed into dispenser)
	if loco_chest.pushItems(config.dispenser,trainID,1,1) == 1 then
    -- If so then push 2 minecarts
		pushFirstItem(1,18,2)
		pushFirstItem(1,18,2)
    -- And an anchor cart
		pushFirstItem(19,27,3)
		return true
	else
		mRail.raise_error(modem,"Train not in depot", 3)
		return false
	end
end

-- Dispatches a train with given number and service ID
function dispatchTrain(trainID, serviceID)
  -- Checks the train was sucessfully moved to the dispenser
	if toDispenser(trainID) == true then
    -- If so then update the routing track with the service ID
		track.setDestination(serviceID)
		-- And toggle the redstone to release the train
		redstone.setOutput("bottom",true)
		sleep(0.1)
		redstone.setOutput("bottom",false)
		return true
	else
		return false
	end
end

-- Checks that the requested locomotive is in the loco cart
-- before sending release request to the parent station
function checkExists(trainID)
	if loco_chest.pushItems(config.dispenser,trainID,1,1) == 1 then
		dispenser.pushItems(config.loco,1,1,trainID)
		return true
	else
		dispenser.pushItems(config.loco,1,1,trainID)
		return false
	end
end

local function requestDispatch(trainID, serviceID)
  -- Check that the train exists in the chest before asking the station for a route
  if checkExists(decodedMessage.trainID) == true then
    -- Request a route from the station
    mRail.station_request_dispatch(modem, config.parentStation, decodedMessage.serviceID, decodedMessage.trainID, config.id)
    -- Update the tracker that we are waiting for permission to dispatch
    mRail.detection_broadcast(modem, config.id, decodedMessage.serviceID, decodedMessage.trainID, "Pending dispatch from " .. mRail.location_name[tonumber(config.id)])
    return {false, "Requested the dispatch of train " .. tostring(trainID)}
  end
  return {false, "Unable to dispatch train " .. tostring(trainID) .. " as it doesnt exist"}
end


local function triggerDispatchTrain(data)
  return requestDispatch(data.trainID, data.serviceID)
end

-- From which all other programs are derived...
local program = {}


program.controlTable  = {
  ["dispatchTrain"]  = triggerDispatchTrain,
}

function program.checkValidID(id)
  if id == tonumber(config.id) then
    return true
  end
  return false
end
--

-- Program Functions
function program.setup(config_)
  config = config_
  
  -- Load all peripherals as per the config
  modem = peripheral.wrap(config.modemSide)

  loco_chest = peripheral.wrap(config.loco)
  cart_chest = peripheral.wrap(config.cart)
  dispenser = peripheral.wrap(config.dispenser)
  
  track = peripheral.wrap(config.routingTrack)
  
  -- Either route output to a dedicated monitor or the terminal
  if config.monitor == nil or config.monitor == "term" then
    monitor = term
  else
    monitor = peripheral.wrap(config.monitor)
  end

  --Open modem to comms channels
  modem.open(mRail.channels.dispatch_channel) -- Used to listen to the dispatch computer
  modem.open(mRail.channels.station_dispatch_confirm) -- Used to wait for dispatch confirmation from the station
  modem.open(mRail.channels.ping_request_channel)
  modem.open(mRail.channels.control_channel)
  
  monitor.clear()
	monitor.setCursorPos(1,1)
	log.info("Current Configuration")
	log.info("System ID: 	" .. config.id)
	log.info("Name:		" .. config.name)
	log.info("Modem Side:	" .. config.modemSide)
	log.info("Track Name:	" .. config.routingTrack)
	log.info("Parent ID:	" .. config.parentStation)
	log.info("Parent Name: " .. mRail.station_name[tonumber(config.parentStation)])
end

function program.onLoop()
  
end


-- Modem Messages

-- Handle messages recieved from dispatch
function program.dispatch_channel(decodedMessage)
  -- Check that the message was intended for this computer
  if decodedMessage.recieverID == config.id then
    log.info("Dispatch has requested a release")
    requestDispatch(decodedMessage.trainID, decodedMessage.serviceID)
  end
end

-- Handles confirmation messages from the station
function program.station_dispatch_confirm(decodedMessage)
  -- Check that the messsage was intended for this computer
  if decodedMessage.recieverID == config.id then
    log.info("Station has authorised the release")
    if dispatchTrain(decodedMessage.trainID, tostring(decodedMessage.serviceID)) == true then
      mRail.detection_broadcast(modem, config.id, decodedMessage.serviceID, decodedMessage.trainID, "Dispatched from " .. mRail.location_name[tonumber(config.id)] .. " to " .. mRail.station_name[tonumber(config.parentStation)])
    else
      local message = "Dispatched failed from " .. mRail.location_name[tonumber(config.id)] .. " to " .. mRail.station_name[tonumber(config.parentStation)]
      mRail.detection_broadcast(modem, config.id, decodedMessage.serviceID, decodedMessage.trainID, message)
      mRail.raise_error(modem, message, 1)
      log.error(message)
    end
  end
end



function program.handleRedstone()
  
end

return program