--- Block Controller
-- @module block-controller
-- @author Sam Lane
-- @copyright 2020-21

-- TODO - Add predictions for time spent in a block, and alarms for if that limit is exceeded by a certain percentage
--      - and then error messages...
-- TODO - control functions for timing predictions

-- TODO - If there is no onewayData file then pull info about the network's blocks from the network controller
-- TODO - Add UI to allow blocks to be edited without hindering the whole use as a oneway control system thingy
-- TODO - Add API interface to modify blocks

-- TODO - Add logging to control functions
-- TODO - Unit test (ha)

-- TODO - Add successes and messages to control functions

-- Load APIs
mRail = require("./mRail/mRail-api")
json = require("./mRail/json")
log = require("./mRail/log")

local config = {}
-- From which all other programs are derived...
local program = {}

local filename = "./mRail/program-state/onewayData"
local requestListFile = "./mRail/program-state/requestList"

-- TRUE = OCCUPIED, FALSE = EMPTY
--Each entry represents a block:
--blockID (increasing number!), blockName, {entranceDetectors}, {exitDetectors}, occupiedState, occupyingTrainID, occupyingServiceID
local oneWayState = {
  {1, "01 North Mainline",     {13,15},{14,16},false,0,""},
  {2, "02 North Mainline",     {17,19},{18,20},false,0,""},
  {3, "03 Up   N Mainline",    {21},   {24},   false,0,""},
  {4, "03 Down N Mainline",    {23},   {22},   false,0,""},
  {5, "04 Up   N Mainline",    {25},   {28},   false,0,""},
  {6, "04 Down N Mainline",    {27},   {26},   false,0,""},
  {7, "05 Up   N Mainline",    {29},   {32},   false,0,""},
  {8, "05 Down N Mainline",    {31},   {30},   false,0,""},
  {9, "06 North Mainline",     {33,35},{34,36},false,0,""},
  {10,"07 North Mainline",     {37,39},{38,40},false,0,""},
  {11,"08 North Mainline",     {41,43},{42,44},false,0,""},
  {12,"01 West Branch",        {51,53},{52,54},false,0,""},
  {13,"02 West Branch",        {55,57},{56,58},false,0,""},
  {14,"03 West Branch",        {59,61},{60,62},false,0,""},
  {15,"04 West Branch",        {63,65},{64,66},false,0,""},
  {16,"05 West Branch",        {67,69},{68,70},false,0,""},
  {17,"Ryan S Branch",         {89,91},{90,92},false,0,""},
  {18,"Ryan S Branch Station", {93},   {94},   false,0,""},
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
    if oneWayState[i][6] ~= 0 or oneWayState[i][7] == "LOCKED" then
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
--

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
--

function determineBlockExit(detectorID)
	local blockID = 0
	for i = 1, #oneWayState do
		for j = 1,#oneWayState[i][4] do
			if oneWayState[i][4][j] == tonumber(detectorID) then
				blockID = i
				return blockID
			end
		end
	end
	return blockID
end
--

local function trainWaiting(blockID)
	local result = 0
	for i = 1, #requestList do
		if blockID == requestList[i][1] then
			result = i
			return result
		end
	end
	return result
end
--

local function checkForWaiting(blockID)
  log.trace("Looking for a waiting train in block " .. tostring(blockID))
  local trainWaitingRequestID = trainWaiting(blockID)
  
  -- check if there is a train waiting to enter the block
  if trainWaitingRequestID == 0 then
    return
  end
  oneWayState[blockID][5] = true
  oneWayState[blockID][6] = requestList[trainWaitingRequestID][3]
  oneWayState[blockID][7] = requestList[trainWaitingRequestID][4]
  local textMessage = "In block " .. oneWayState[blockID][2]
  mRail.detection_broadcast(requestList[trainWaitingRequestID][2], requestList[trainWaitingRequestID][4], requestList[trainWaitingRequestID][3], textMessage)
  -- permit entry
  mRail.oneway_confirm_dispatch(requestList[trainWaitingRequestID][2], requestList[trainWaitingRequestID][4], requestList[trainWaitingRequestID][3])
  -- remove from list
  table.remove(requestList,trainWaitingRequestID)
end
--

local function validBlockID(blockID)
  if blockID == nil or blockID <= 0 or blockID > #oneWayState then
    log.trace("Invalid blockID provided: " .. tostring(blockID))
    return false
  end
  return true
end
--


local function clearAllocation(blockID)
  log.trace("Clearing block " .. tostring(blockID))
  if not validBlockID(blockID) then
    return
  end
  oneWayState[blockID][5] = false
  oneWayState[blockID][6] = 0
  oneWayState[blockID][7] = ""
  checkForWaiting(blockID)
end
--

local function clearAllAllocations()
  log.trace("Clearing all allocations")
  for i = 1, #oneWayState do
    clearAllocation(i)
  end
end
--

local function clearAllocations(blockIDs)
  if blockIDs == nil then
    clearAllAllocations()
    return
  elseif type(blockIDs) ~= "table" then
    clearAllocation(tonumber(blockIDs))
    return
  end
  for i = 1, #blockIDs do
    clearAllocation(blockIDs[i])
  end
end
--


local function clearAllRequests()
  log.trace("Clearing all requests")
  requestList = {}
end
--

local function clearRequest(blockID)
  if not validBlockID(blockID) then
    return
  end
  log.trace("Clearing requests for block " .. tonumber(blockID))
  for i = 1, #requestList do
    if tonumber(trainID) == tonumber(requestList[i][3]) then
      table.remove(requestList,i)
      break
      -- TODO need to replace this with a do while loop so this doesnt break
      -- it's not difficult, I just can't be bothered right now :(
    end
  end
end
--

local function clearRequests(blockIDs)
  if blockIDs == nil then
    clearAllRequests()
    return {true, "All requests cleared"}
  elseif type(blockIDs) ~= "table" then
    clearRequest(tonumber(blockIDs))
    return {true, "Request cleared"}
  end
  for i = 1, #blockIDs do
    clearRequest(blockIDs[i])
  end
  return {true, "Requests cleared"}
end
--

local function clearBoth(blockIDs)
  clearRequests(blockIDs)
  clearAllocations(blockIDs)
end
--



local function clearTrain(trainID)
  for i = 1, #oneWayState do
    if tonumber(trainID) == tonumber(oneWayState[i][6]) then
      clearAllocation(i)
    end
  end
  
  --format blockID, requesterDetectorID, trainID, serviceID
  local listToRemove = {}
  for i = 1, #requestList do
    if tonumber(trainID) == tonumber(requestList[i][3]) then
      table.remove(requestList, i)
    end
  end
end
--


local function lockBlock(blockID)
  if not validBlockID(blockID) then
    return {false, "Invalid block ID"}
  end
  log.debug("Attempting to lock block " .. tostring(blockID))
  local msg = ""
  if oneWayState[blockID][5] == false then
    oneWayState[blockID][5] = true
    oneWayState[blockID][6] = 0
    oneWayState[blockID][7] = "LOCKED"
    msg = "Block " .. tostring(blockID) .. " locked"
    log.debug(msg)
    return {true, msg}
  end
  msg = "Block " .. tostring(blockID) .. " occupied, unable to lock"
  log.debug(msg)
  return {false, msg}
end
--

local function unlockBlock(blockID)
  if not validBlockID(blockID) then
    return {false, "Invalid block ID"}
  end
  log.debug("Attempting to unlock block " .. tostring(blockID))
  local msg = ""
  if oneWayState[blockID][7] == "LOCKED" then
    clearAllocation(blockID)
    checkForWaiting(blockID)
    msg = "Block " .. tostring(blockID) .. " unlocked"
    log.debug(msg)
    return {true, msg}
  end
  
  msg = "Block " .. tostring(blockID) .. " was not locked!"
  log.debug(msg)
  return {false, msg}
end
--

local function lockAllBlocks()
  local success = {true, "All blocks locked"}
  for i = 1, #oneWayState do
    local response = lockBlock(i)
    if response[1] == false then
      success = {false, "Unable to lock all blocks"}
    end
  end
  return success
end
--

local function unlockAllBlocks()
  local success = {true, "All blocks unlocked"}
  for i = 1, #oneWayState do
    local response = unlockBlock(i)
    if response[1] == false then
      success = {false, "Unable to unlock all blocks"}
    end
  end
  return success
end
--


local function lockBlocks(blockIDs)
  if blockIDs == nil then
    return lockAllBlocks()
  end
  
  if type(blockIDs) == table then
    local success = {true, "Selected blocks locked"}
    for i = 1, #blockIDs do
      if lockBlock(blockIDs[i])[1] == false then
        success = {false, "Unable to lock all selected blocks"}
      end
    end
    return success
  else
    return lockBlock(blockIDs)
  end
end
--

local function unlockBlocks(blockIDs)
  if blockIDs == nil then
    return unlockAllBlocks()
  end
  
  if type(blockIDs) == table then
    local success = {true, "Selected blocks unlocked"}
    for i = 1, #blockIDs do
      if unlockBlock(blockIDs[i])[1] == false then
        success = {false, "Unable to unlock all selected blocks"}
      end
    end
    return success
  else
    return unlockBlock(blockIDs)
  end
end
--

local function appendDetector(positionID, blockID, detector)
  local numDetectors = #oneWayState[blockID][positionID]
  if numDetectors == nil then
    oneWayState[blockID][positionID] = {tonumber(detector)}
  else
    for i = 1, numDetectors do
      if detector == #oneWayState[blockID][positionID][i] then
        log.debug("Detector not unique, unable to append")
        return
      end
    end
    oneWayState[blockID][positionID][numDetectors + 1] = tonumber(detector)
  end
end
--

local function appendDetectors(positionID, blockID, detectors)
  if type(detectors) == "table" then
    for i = 1, #detectors do
      appendDetector(positionID, blockID, detectors[i])
    end
  else
    appendDetector(positionID, blockID, detectors)
  end
  return {true, "Append detectors"}
end
--

local function removeDetector(positionID, blockID, detector)
  for i = 1, #oneWayState[blockID][positionID] do
    if tonumber(oneWayState[blockID][positionID][i]) == tonumber(detector) then
      table.remove(oneWayState[blockID][positionID], i)
      return {true, "Detector removed"}
    end
  end
  return {false, "No detector to remove"}
end
--

local function removeDetectors(positionID, blockID, detectors)
  if type(detectors) == "table" then
    for i = 1, #detectors do
      removeDetector(positionID, blockID, detectors[i])
    end
  else
    removeDetector(positionID, blockID, detectors)
  end
  return {true, "Detectors removed"}
end
--

local function replaceDetectors(positionID, blockID, detectors)
  if detectors == nil then
    return {false, "No detectors provided to replace"}
  elseif type(detectors) == "table" then
    oneWayState[blockID][positionID] = detectors
  else
    oneWayState[blockID][positionID] = {detectors}
  end
  return {true, "Detectors replaced"}
end
--

local function detectorEdit(entrance, blockID, modifier, detectors)
  if not validBlockID(blockID) then
    local msg = "Unable to edit detector, block does not exist"
    log.debug(msg)
    return {false, msg}
  end
  
  local modifierTable = {
    ["append"] = appendDetectors,
    ["remove"] = removeDetectors,
    ["replace"] = replaceDetectors
  }
  
  local positionID = entrance and 3 or 4
  local func = modifierTable[tostring(modifier)]
  if (func) then
    return func(positionID, blockID, detectors)
  else
    return {false, "Invalid modifier argument"}
  end
end
--

local function editEntranceDetector(data)
  detectorEdit(true, data.blockID, data.modifier, data.detectors)
end
--

local function editExitDetector(data)
  detectorEdit(false, data.blockID, data.modifier, data.detectors)
end
--

local function returnDetectorTable(detectors)
  if detectors == nil then
    return {}
  elseif type(detectors) == "table" then
    return detectors
  else
    return {tonumber(detectors)}
  end
end
--

local function newBlock(name, entranceDetectors, exitDetectors)
  local block = {#oneWayState + 1,
                 name,
                 returnDetectorTable(entranceDetectors),
                 returnDetectorTable(exitDetectors),
                 false,
                 0,
                 ""
                }
  oneWayState[#oneWayState + 1] = block
end
--

local function blockEdit(data)
  if data.blockID == nil then
    newBlock(data.name, data.entranceDetectors, data.exitDetectors)
    return {true, "New block created"}
  elseif not validBlockID(blockID) then
    return {false, "block ID out of range"}
  end
  
  
  if data.name ~= nil then
    oneWayState[data.blockID][2] = tostring(data.name)
  end
  
  if data.entranceDetectors ~= nil then
    detectorEdit(true, data.blockID, data.modifier, data.entranceDetectors)
  end
  
  if data.exitDetectors ~= nil then
    detectorEdit(false, data.blockID, data.modifier, data.entranceDetectors)
  end
  return {true, "Block updated"}
end
--


program.controlTable  = {
  ["clear"]           = clearBoth,
  ["clearAllocation"] = clearAllocations,
  ["clearRequest"]    = clearRequests,
  ["clearTrain"]      = clearTrain,
  ["lock"]            = lockBlocks,
  ["unlock"]          = unlockBlocks,
  ["block"]           = blockEdit,
  ["entrDetector"]    = editEntranceDetector,
  ["exitDetector"]    = editExitDetector,
}

function program.checkValidID(id)
  return true
end
--


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
  modem.open(mRail.channels.ping_request_channel)
  modem.open(mRail.channels.control_channel)
  
  width, height = monitor.getSize()
  blankString = ""
  for i = 1,width do
    blankString = blankString .. " "
  end
  
  -- run initial display update
  oneWayState = mRail.loadData(filename, oneWayState)
  requestList = mRail.loadData(requestListFile, requestList)
  updateDisplay()
end
--

function program.onLoop()
  mRail.saveData(filename, oneWayState)
	mRail.saveData(requestListFile, requestList)
	monitor.clear()
	monitor.setCursorPos(1,1)
	updateDisplay()
end
--


-- Modem Messages
function program.detect_channel(decodedMessage)
  -- Handle messages on the detection channel
  local blockID = determineBlockExit(decodedMessage.detectorID)
  print("BlockID " .. blockID)
  if blockID == 0 then
    return
  end
  
  -- Also check if it was in another block (but this should raise an error)
  for i = 1, #oneWayState do
    if oneWayState[i][5] == true and oneWayState[i][6] == tonumber(decodedMessage.trainID) then
      clearAllocation(i)
      checkForWaiting(i)
      if i ~= blockID then
        mRail.raise_error("Locomotive " .. tonumber(decodedMessage.trainID) .. " was still allocated in a differen block", 1)
      end
    end
  end
end
--

function program.oneway_dispatch_request(decodedMessage)
  -- Handle messages on the station dispatch request channel
  
  
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
    mRail.oneway_confirm_dispatch(decodedMessage.detectorID, decodedMessage.serviceID, decodedMessage.trainID)
    local textMessage = "In block " .. oneWayState[blockID][2]
    mRail.detection_broadcast(decodedMessage.detectorID, decodedMessage.serviceID, decodedMessage.trainID, textMessage)
  elseif oneWayState[blockID][5] == true then
    -- Check if this train was already allocated into the block
    if oneWayState[blockID][6] == decodedMessage.trainID and oneWayState[blockID][7] == decodedMessage.serviceID then
      mRail.oneway_confirm_dispatch(decodedMessage.detectorID, decodedMessage.serviceID, decodedMessage.trainID)
      local textMessage = "In block " .. oneWayState[blockID][2]
      mRail.detection_broadcast(decodedMessage.detectorID, decodedMessage.serviceID, decodedMessage.trainID, textMessage)
      return
    end
  -- if not, add the request to the request list
    local request = {blockID, decodedMessage.detectorID, decodedMessage.trainID, decodedMessage.serviceID}
    table.insert(requestList,request)
  end
end
--


-- Alarms
function program.handleAlarm(alarmID)
  
end
--

function program.handleRedstone()
  
end
--

return program