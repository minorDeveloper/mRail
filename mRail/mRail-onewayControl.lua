-- mRail Block Controller
-- (C) 2020-21 Sam Lane

-- TODO - Add predictions for time spent in a block, and alarms for if that limit is exceeded by a certain percentage
--      - and then error messages...

-- TODO - If there is no onewayData file then pull info about the network's blocks from the network controller
-- TODO - Add UI to allow blocks to be edited without hindering the whole use as a oneway control system thingy
-- TODO - Add API interface to modify blocks

-- Load APIs
mRail = require("./mRail/mRail-api")
json = require("./mRail/json")
log = require("./mRail/log")

local config = {}

local filename = "./mRail/program-state/onewayData"
local requestListFile = "./mRail/program-state/requestList"

-- TRUE = OCCUPIED, FALSE = EMPTY
--Each entry represents a block:
--blockID (increasing number!), blockName, {entranceDetectors}, {exitDetectors}, occupiedState, occupyingTrainID, occupyingServiceID
local oneWayState = {
  {1, "01 North Mainline", {13,15},{14,16},false,0,""},
  {2, "02 North Mainline", {17,19},{18,20},false,0,""},
  {3, "03 Up   N Mainline",{21},{24},false,0,""},
  {4, "03 Down N Mainline",{23},{22},false,0,""},
  {5, "04 Up   N Mainline",{25},{28},false,0,""},
  {6, "04 Down N Mainline",{27},{26},false,0,""},
  {7, "05 Up   N Mainline",{29},{32},false,0,""},
  {8, "05 Down N Mainline",{31},{30},false,0,""},
  {9, "06 North Mainline", {33,35},{34,36},false,0,""},
  {10,"07 North Mainline", {37,39},{38,40},false,0,""},
  {11,"08 North Mainline", {41,43},{42,44},false,0,""},
  {12,"01 West Branch",    {51,53},{52,54},false,0,""},
  {13,"02 West Branch",    {55,57},{56,58},false,0,""},
  {14,"03 West Branch",    {59,61},{60,62},false,0,""},
  {15,"04 West Branch",    {63,65},{64,66},false,0,""},
  {16,"05 West Branch",        {67,69},{68,70},false,0,""},
  {17,"Ryan S Branch",         {89,91},{90,92},false,0,""},
  {18,"Ryan S Branch Station", {93},{94},false,0,""},
}





--

--format blockID, requesterDetectorID, trainID, serviceID
local requestList = {}

local width, height
local blankString

local function updateDisplay()
  monitor.setBackgroundColor(colors.green)
	monitor.clear()
	monitor.setCursorPos(1,1)
	for i = 1, #oneWayState do
    monitor.setBackgroundColor(colors.black)
    
    if oneWayState[i][5] == false then
			monitor.setBackgroundColor(colors.green)
		elseif oneWayState[i][5] == true then
			monitor.setBackgroundColor(colors.red)
		end
    
    for j = 1, width do
      monitor.setCursorPos(j,i)
      monitor.write(" ")
    end
    
		monitor.setCursorPos(1,i)
		monitor.write(oneWayState[i][2])
    
		monitor.setCursorPos(27,i)
    local serviceID = oneWayState[i][7]
    if serviceID == "" or serviceID == nil then
      serviceID = "No Route"
    end
    if oneWayState[i][6] ~= 0 then
      monitor.write(" ")
      monitor.write(serviceID)
      monitor.write(" ")
    end
	end
	for i = #oneWayState + 1, height do
		monitor.setCursorPos(1,i)
		monitor.setBackgroundColor(colors.black)
		monitor.write(blankString)
	end
	
  for i = 1, #requestList do
    monitor.setBackgroundColor(colors.orange)
    monitor.setCursorPos(40, requestList[i][1])
    local serviceID = requestList[i][4]
    if serviceID == "" or serviceID == nil then
      serviceID = "No Route"
    end
    monitor.write(" ")
    monitor.write(serviceID)
    monitor.write(" ")
  end
	
end

function determineBlockEntr(detectorID)
	local blockID = 0
	for i = 1, #oneWayState do
		for j = 1,#oneWayState[i][3] do
			if oneWayState[i][3][j] == detectorID then
				blockID = i
				return blockID
			end
		end
	end
	return blockID
end

function determineBlockExit(detectorID)
	local blockID = 0
	for i = 1, #oneWayState do
		for j = 1,#oneWayState[i][4] do
			if oneWayState[i][4][j] == detectorID then
				blockID = i
				return blockID
			end
		end
	end
	return blockID
end

function trainWaiting(blockID)
	local result = 0
	for i = 1, #requestList do
		if blockID == requestList[i][1] then
			result = i
			return result
		end
	end
	return result
end


-- From which all other programs are derived...
local program = {}

-- Program Functions
function program.setup(config_)
  config = config_

  modem = peripheral.wrap(config.modemSide)
  
  if config.monitor == nil or config.monitor == "term" then
    monitor = term
  else
    monitor = peripheral.wrap(config.monitor)
  end
  
  --Open modem to comms channels
  modem.open(mRail.channels.oneway_dispatch_request)
  modem.open(mRail.channels.detect_channel)
  
  width, height = monitor.getSize()
  blankString = ""
  for i = 1,width do
    blankString = blankString .. " "
  end
  
  -- run initial display update
  mRail.loadData(filename, oneWayState)
  mRail.loadData(requestListFile, requestList)
  updateDisplay()
end

function program.onLoop()
  mRail.saveData(filename, oneWayState)
	mRail.saveData(requestListFile, requestList)
	monitor.clear()
	monitor.setCursorPos(1,1)
	updateDisplay()
end


-- Modem Messages
function program.detect_channel(decodedMessage)
  -- Handle messages on the detection channel
  
  local blockID = determineBlockExit(decodedMessage.detectorID)
  print("BlockID " .. blockID)
  if blockID == 0 then
    return
  end
  
  if oneWayState[blockID][5] == true then
    -- free the block
    oneWayState[blockID][5] = false
    oneWayState[blockID][6] = 0
    oneWayState[blockID][7] = ""
    
    local trainWaitingRequestID = trainWaiting(blockID)
    
    -- check if there is a train waiting to enter the block
    if trainWaitingRequestID == 0 then
      return
    end
    oneWayState[blockID][5] = true
    oneWayState[blockID][6] = requestList[trainWaitingRequestID][3]
    oneWayState[blockID][7] = requestList[trainWaitingRequestID][4]
    local textMessage = "In block " .. oneWayState[blockID][2]
    mRail.detection_broadcast(modem, requestList[trainWaitingRequestID][2], requestList[trainWaitingRequestID][4], requestList[trainWaitingRequestID][3], textMessage)
    -- permit entry
    mRail.oneway_confirm_dispatch(modem, requestList[trainWaitingRequestID][2], requestList[trainWaitingRequestID][4], requestList[trainWaitingRequestID][3])
    -- remove from list
    table.remove(requestList,trainWaitingRequestID)
  end
end

function program.oneway_dispatch_request(decodedMessage)
  -- Handle messages on the station dispatch request channel
  
  
  -- if the event is a request
  print("Dispatch has been requested")
  -- determine which block
  local blockID = determineBlockEntr(decodedMessage.detectorID)
  print("DetectorID " .. decodedMessage.detectorID)
  -- check if the block is free
  print("BlockID " .. blockID)
  if blockID == 0 then
    return
  end
  
  if oneWayState[blockID][5] == false then
  -- if so, then make the block occupied and release the train
    oneWayState[blockID][5] = true
    oneWayState[blockID][6] = decodedMessage.trainID
    oneWayState[blockID][7] = decodedMessage.serviceID
    mRail.oneway_confirm_dispatch(modem, decodedMessage.detectorID, decodedMessage.serviceID, decodedMessage.trainID)
    local textMessage = "In block " .. oneWayState[blockID][2]
    mRail.detection_broadcast(modem, decodedMessage.detectorID, decodedMessage.serviceID, decodedMessage.trainID, textMessage)
  elseif oneWayState[blockID][5] == true then
  -- if not, add the request to the request list
    local request = {blockID, decodedMessage.detectorID, decodedMessage.trainID, decodedMessage.serviceID}
    table.insert(requestList,request)
  end
end

-- Alarms
function program.handleAlarm(alarmID)
  
end

function program.handleRedstone()
  
end

return program