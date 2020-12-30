-- mRail System Program Base
-- (C) 2020-21 Sam Lane

-- TODO - Comment everything
-- TODO - Add more error checking (i.e. if there are enough things available)
-- TODO - Add support for more train types

mRail = require("./mRail/mRail-api")
json = require("./mRail/json")
log = require("./mRail/log")

local config = {}

local modem

local loco_chest
local cart_chest
local dispenser
local track

function pushFirstItem(lowerSlot, upperSlot, destinationSlot)
	local success = 0
	local i = upperSlot
	while success == 0 do
		success = cart_chest.pushItems("bottom",i,1,destinationSlot)
		log.debug("Slot " .. tostring(i) .. " " .. success)
		i = i - 1
		if i == lowerSlot then
			success = true
		end
	end
end

function toDispenser(trainID)
	if loco_chest.pushItems("bottom",trainID,1,1) == 1 then
		pushFirstItem(1,18,2)
		pushFirstItem(1,18,2)
		pushFirstItem(19,27,3)
		return true
	else
		mRail.raise_error(modem,"Train not in depot", 3)
		return false
	end
end


function dispatchTrain(trainID, serviceID)
	if toDispenser(trainID) == true then
		track.setDestination(serviceID)
		-- release train
		redstone.setOutput("bottom",true)
		sleep(0.1)
		redstone.setOutput("bottom",false)
		return true
	else
		return false
	end
end

function checkExitst(trainID)
	if loco_chest.pushItems("bottom",trainID,1,1) == 1 then
		dispenser.pushItems("right",1,1,trainID)
		return true
	else
		dispenser.pushItems("right",1,1,trainID)
		return false
	end
end

-- From which all other programs are derived...
local program = {}

-- Program Functions
function program.setup(config_)
  config = config_
  
  modem = peripheral.wrap(config.modemSide)

  loco_chest = peripheral.wrap(config.loco)
  cart_chest = peripheral.wrap(config.cart)
  dispenser = peripheral.wrap(config.dispenser)
  
  track = peripheral.wrap(config.routingTrack)
  
  if config.monitor == nil or config.monitor == "term" then
    monitor = term
  else
    monitor = peripheral.wrap(config.monitor)
  end

  --Open modem to comms channels
  modem.open(mRail.channels.dispatch_channel)
  modem.open(mRail.channels.station_dispatch_confirm)
  
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
function program.dispatch_channel(decodedMessage)
  -- Handle messages on the dispatch channel
  if decodedMessage.recieverID == config.id then
    log.info("Dispatch has requested a release")
    -- path A: dispatch requests a release
    --TODO: NEED TO CHECK THAT THE TRAIN EXISTS
    if checkExitst(decodedMessage.trainID) == true then
      mRail.station_request_dispatch(modem, config.parentStation, decodedMessage.serviceID, decodedMessage.trainID, config.id)
      mRail.detection_broadcast(modem, config.id, decodedMessage.serviceID, decodedMessage.trainID, "Pending dispatch from " .. mRail.location_name[tonumber(config.id)])
    end
  end
end

function program.station_dispatch_confirm(decodedMessage)
  -- Handle messages on the station dispatch confirmation channel
  if decodedMessage.recieverID == config.id then
    log.info("Station has authorised the release")
    -- path B: parent station clears release
    if dispatchTrain(decodedMessage.trainID, tostring(decodedMessage.serviceID)) == true then
      mRail.detection_broadcast(modem, config.id, decodedMessage.serviceID, decodedMessage.trainID, "Dispatched from " .. mRail.location_name[tonumber(config.id)] .. " to " .. mRail.station_name[tonumber(config.parentStation)])
    end
  end
end


return program