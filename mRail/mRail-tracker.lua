-- mRail Train Tracker and Display
-- (C) 2020-21 Sam Lane

-- TODO - Add support for more trains (not sure how yet!)

-- TODO - Get next station information from dispatch (add channel to request this and recieve update)
--      - Will need to go out to mRail for this

-- TODO - Support for scrolling and variable size displays

-- Load APIs
mRail = require("./mRail/mRail-api")
json = require("./mRail/json")
log = require("./mRail/log")

local config = {}

local monitor
local modem

local trainDataFile = "./mRail/program-state/trainData"

local struct = {
	trainID = 1,
	serviceID = 2,
	currentLocationID = 3,
	nextStationID = 4,
	msg = 5
}

local xPos = {
	trainID = 4,
	serviceID = 8,
	currentLocationID = 22,
	nextStationID = 39,
	msg = 50
}


local trainData = {}


-- Fills the data array with default values 
-- Used on first run of the program
local function setupDataArray()
  for i = 1, config.numberTrains do
    trainData[i] = {i,0,0,0,""}
  end
end

local function stringify(inputString)
  if inputString == 0 or inputString == nil then
    return ""
  end
  return tostring(inputString)
end

-- Writes to display (7x3)
local function updateDisplay()
	monitor.clear()
	
	monitor.setCursorPos(1, 1)
	monitor.write("Train:")
	
	monitor.setCursorPos(xPos.serviceID, 1)
	monitor.write("Service:")
	
	monitor.setCursorPos(xPos.currentLocationID, 1)
	monitor.write("Current:")
	
	monitor.setCursorPos(xPos.nextStationID, 1)
	monitor.write("Next Station:")
	
	monitor.setCursorPos(xPos.msg, 1)
	
	
	for i = 1, config.numberTrains do
		monitor.setCursorPos(1,i+1)
		monitor.setBackgroundColor(math.pow(2,i - 1))
		monitor.write("  ")
		monitor.setBackgroundColor(32768)
		
		monitor.setCursorPos(xPos.trainID, i+1)
		local messageString = ""
		idTrain = trainData[i][struct.trainID]
		
		if idTrain < 10 then
			messageString = "0" .. tostring(idTrain)
		else
			messageString = tostring(idTrain)
		end
		monitor.write(messageString)
		
		monitor.setCursorPos(xPos.serviceID, i+1)
		monitor.write(stringify(trainData[i][struct.serviceID]))
		
		monitor.setCursorPos(xPos.currentLocationID, i+1)
		monitor.write(stringify(mRail.location_name[trainData[i][struct.currentLocationID]]))
		
		monitor.setCursorPos(xPos.nextStationID, i+1)
		monitor.write(stringify(mRail.station_name[trainData[i][struct.nextStationID]]))
		
		monitor.setCursorPos(xPos.msg, i+1)
		monitor.write(stringify(trainData[i][struct.msg]))
	end
	
	monitor.setCursorBlink(false)
	monitor.setCursorPos(1,1)
end


-- From which all other programs are derived...
local program = {}

-- Program Functions
function program.setup(config_)
  config = config_
  
  modem = peripheral.wrap(config.modemSide)
  monitor = peripheral.wrap(config.monitor)
  
  --Open modem to comms channels

  -- TODO - Check why we are opening two channels!
  modem.open(mRail.channels.detect_channel)
  modem.open(mRail.channels.next_station_update)
  modem.open(mRail.channels.ping_request_channel)
  
  setupDataArray()
  trainData = mRail.loadData(trainDataFile, trainData)
  updateDisplay()
end

function program.onLoop()
	updateDisplay()
end


-- Modem Messages
function program.detect_channel(decodedMessage)
  -- Handle messages on the detection channel
  local msgDetectorID = tonumber(decodedMessage.detectorID)
	local msgTrainID = tonumber(decodedMessage.trainID)
	local msgServiceID = tostring(decodedMessage.serviceID)
	local msgMsg = tostring(decodedMessage.textMessage)
	
	trainData[msgTrainID][2] = msgServiceID
	trainData[msgTrainID][3] = msgDetectorID
	trainData[msgTrainID][5] = msgMsg
	
	-- save to file:close
	mRail.saveData(trainDataFile, trainData)
end

function program.next_station_update(decodedMessage)
  -- Handle messsages on the next station update channel
  local msgTrainID = tonumber(decodedMessage.trainID)
  
  trainData[msgTrainID][4] = tonumber(decodedMessage.nextStationID)
  
  -- save to file:close
	mRail.saveData(trainDataFile, trainData)
end

function program.handleRedstone()
  -- Left blank, but must have this function in case
  -- the redstone is altered around this computer
end

return program