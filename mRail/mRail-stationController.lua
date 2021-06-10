--- Station Controller
--@module station

-- mRail System Program Base
-- (C) 2020-21 Sam Lane

-- Load APIs
mRail = require("./mRail/mRail-api")
json = require("./mRail/json")
log = require("./mRail/log")

-- Program config
local config = {}

local modem
local monitor

local signalController
local switchController
local releaseController

local stationRouting = {}
local stationConfig = {}
local systemRoutingData = {}

local stateFile = "./mRail/program-state/stationState"

-- state loaded, serviceID, trainID
local currentLoadedStates = {}
local requestList = {}

--sig req, sig state, swit req, swit state
local currentState = {0,0,0,0}

-- alarmID, serviceID, trainID, time
local alarms = {}

-- Functions
function string:split( inSplitPattern )
  local outResults = {}
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )

  while theSplitStart do
      table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end

  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

-- Loops over a multidimensional array to check that
-- a given value is not already present
function checkUnique(array, index, comparison)
  local unique = true
  for i = 1, #array do
    if array[i][index] == comparison then
      unique = false
      break
    end
  end
  return unique
end

-- Loads a csv file into a table
function loadStateTable()
	local lineData = {}
	local file = io.open("./mRail/network-configs/StateTable" .. config.stationID .. ".csv","r")
	i = 1
	for line in file:lines() do
    lineData[i]=line
    i=i+1
	end

	for i=1,#lineData do
		local splitLine = lineData[i]:split(",") 
		systemRoutingData[#systemRoutingData + 1] = splitLine
	end
end

-- Sets the state of a given controller with the signal
-- used for wireless control of points and release tracks
function setControllers(controller, signal, prefix)
	local nSignals = #controller.getSignalNames()
	for i = 1, nSignals do
		local signalName = prefix .. i
		local state = bit.band(signal, 2 ^ (i-1))
		local value = 1
		if state == 0 then
			value = 5
		end
		controller.setAspect(signalName, value)
	end
end

-- Takes the current state of switches and signals and outputs
-- it to the various peripherals (i.e. bundled cables or digital controllers)
function setOutputState(signalsRelease,switches)
	if config.controlType == "wired" then
		redstone.setBundledOutput(config.signalControl,signalsRelease)
		redstone.setBundledOutput(config.releaseControl,signalsRelease)
		redstone.setBundledOutput(config.switchControl,switches)
	elseif config.controlType == "wireless" then
		-- set switches
		setControllers(switchController, switches, "SW")
		-- set signals
		setControllers(signalController, signalsRelease, "S")
		-- set release
		setControllers(releaseController, signalsRelease, "S")
	end
end

-- Returns a table of routes from the entranceID 
-- to the exitID
function findRoutes(entranceID, exitID)
	local possibleRoutes = {}
	for i = 2, #systemRoutingData do
		if tonumber(systemRoutingData[i][3]) == entranceID and tonumber(systemRoutingData[i][4]) == exitID then
			table.insert(possibleRoutes,i-1)
		end
	end
	return possibleRoutes
end

-- Checks if a new state is compatible with the one currently set
function checkNewCombo(stateA)
	local signalStateA 		= tonumber(systemRoutingData[stateA+1][6])
	local signalRequiredA 	= tonumber(systemRoutingData[stateA+1][5])
	local switchStateA 		= tonumber(systemRoutingData[stateA+1][8])
	local switchRequiredA 	= tonumber(systemRoutingData[stateA+1][7])
	
	local signalStateB 		= currentState[2]
	local signalRequiredB 	= currentState[1]
	local switchStateB 		= currentState[4]
	local switchRequiredB 	= currentState[3]
	
	log.debug(currentState[1] .. " " .. currentState[2] .. " " .. currentState[3] .. " " .. currentState[4])
	log.trace(stateA)
	
  -- This is the main bit of processing for the system to determine if two states are compatible
  -- For any switch, signal, or release that is required to be set a certain way, all current states must
  -- agree on how it is set. We do this by anding the two required states to determine any potential locations of conflit,
  -- then identify any differing signals etc with an xor. The two values are finally anded to detect where there are conflicts
  -- that both routes require. If there is a conflict then either validSwitching or validSignalling will be non-zero and 
  -- so we return false
	local validSwitching = bit.band(bit.band(switchRequiredA,switchRequiredB),bit.bxor(switchStateA,switchStateB))
	local validSignalling =bit.band(bit.band(signalRequiredA,signalRequiredB),bit.bxor(signalStateA,signalStateB))
	
	if validSignalling == 0 and validSwitching == 0 then
		return true
	end
	return false
end

-- Attempts to remove a given state ID from the list of currently loaded states
-- Returns true if that state existed in the list of current states
function tryRemove(stateID)
	if #currentLoadedStates ~= 0 then
		for i = 1, #currentLoadedStates do
			if tonumber(currentLoadedStates[i][1]) == stateID then
				table.remove(currentLoadedStates,i)
				log.debug("Removed the state")
				return true
			end
		end
	end
	return false
end

-- Tries to add a state with an associated service and train
function tryAdd(stateID, serviceID, trainID)
  -- Ensure that the stateID is in numerical form
	stateID = tonumber(stateID)
  
	-- We start by removing any state that must be removed for this to be possible
  -- i.e. to route a train out of a platform we must first remove the platform
  -- allocation for our system to find a route
  -- If this process is unsuccessful we re-apply the state at the end and try again
  -- later
	local platformOccupation = 0
	if tonumber(systemRoutingData[stateID+1][9]) ~= 0 then
		platformOccupation = tonumber(systemRoutingData[stateID+1][9])
		tryRemove(platformOccupation)
	end
  
	-- Update the state so that the platform removal can take effect internally
	updateState()
  -- Check that the stateID is valid, and that the state itself is compatible with the current system
	if stateID > 0 and checkNewCombo(stateID) == true and checkUnique(currentLoadedStates, 1, tonumber(stateID)) then
    -- If compatible, then add the state to the table, and update
    table.insert(currentLoadedStates,{stateID, serviceID, trainID})
    log.debug("State added")
    updateState()
    return true
	else
    -- If incompatible then re-add the platform allocation and continue
		log.debug("Requested state incompatible")
		if platformOccupation ~= 0 then
			tryAdd(platformOccupation, serviceID, trainID)
		end
    updateState()
		return false
	end
end

-- Attempts to find a route between a given entrance and exit
-- If a route is found, then it will be allocated
function tryRoute(entranceID, exitID, serviceID, trainID)
	local possibleRoutes = findRoutes(entranceID, exitID)
	log.debug("Routes found")
	log.trace(tostring(possibleRoutes))
	
  for i = 1, #possibleRoutes do
    if tryAdd(possibleRoutes[i], serviceID, trainID) == true then
      return true
    end
  end
	return false
end

-- For currently incompatible routes, we add the request to the request list
function logRequest(entryID, serviceID, trainID, detectorID,entryOrDispatch)
  local unique = checkUnique(requestList, 1, entryID) and checkUnique(requestList, 3, trainID)
	if unique then
		if serviceID == nil then
			serviceID = ""
		end
    mRail.next_station_request(serviceID, trainID, tonumber(config.stationID))
		table.insert(requestList,{entryID, serviceID, trainID, detectorID,entryOrDispatch})
	end
end

-- TODO - Comment
-- TODO - General cleanup
function processRequests()
	local stateRemoved = false
  -- TODO - Replace this with a do while loop, rather than be recursive
  for i = 1, #requestList do
    for j = 1, #stationRouting do
      log.trace(stationRouting[j][1])
      if tostring(requestList[i][2]) == stationRouting[j][1] then
        local routesToTry = stationRouting[j][2][tonumber(config.stationID)][tonumber(requestList[i][5])]
        for k = 1, #routesToTry do
          log.debug("Trying route from " .. requestList[i][1] .. " to " .. routesToTry[k])
          if tryRoute(requestList[i][1], routesToTry[k], requestList[i][2], requestList[i][3]) == true then
            if tonumber(requestList[i][4]) ~= 0 then
              mRail.station_confirm_dispatch(requestList[i][4], requestList[i][2], requestList[i][3])
            end
            --check if it ended in a platform
            for m = 1, #stationConfig.platformIDNameMapping do
              if tonumber(routesToTry[k]) == tonumber(stationConfig.platformIDNameMapping[m][1]) then
                local platformName = tostring(stationConfig.platformIDNameMapping[m][2])
                local serviceID = tostring(requestList[i][2])
                mRail.screen_platform_update(config.stationID, serviceID, platformName)
              end
            end
            stateRemoved = true
            table.remove(requestList,i)
            break
          end
        end
        break
      end
    end
    if stateRemoved then
      break
    end
  end
	if stateRemoved then
		processRequests()
	end
end


function setDepartureAlarm(serviceID, trainID)
	--check that an alarm doesnt already exist for this
  local unique = checkUnique(alarms, 3, trainID)
	--if no alarm then make one for an hour ahead
	if unique then
		local currentTime = os.time()
    local alarmTime = ((currentTime + 1.0) % 24)
		local alarmID = os.setAlarm(alarmTime)
		table.insert(alarms,{alarmID,serviceID,trainID,alarmTime})
	end
end

function printColourAndRoute(serviceID, trainID, display)
  display.setBackgroundColor(math.pow(2,tonumber(trainID) - 1))
  display.write("  ")
  display.setBackgroundColor(32768)
  display.write(" ")
  if serviceID == nil or serviceID == "" or serviceID == "nil" then
    serviceID = "No Route"
  end
  display.write(tostring(serviceID))
  for i = string.len(serviceID), 8 do
    display.write(" ")
  end
  display.write(" ")
end

-- Updates the currentState variable with the list of currently states loaded
function updateState()
	if #currentLoadedStates ~= 0 then
		local signalState = 0
		local signalReq = 0
		local switchState = 0
		local switchReq = 0
		for i = 1, #currentLoadedStates do
			signalState = bit.bor(signalState,tonumber(systemRoutingData[currentLoadedStates[i][1]+1][6]))
			signalReq = bit.bor(signalReq,tonumber(systemRoutingData[currentLoadedStates[i][1]+1][5]))
			
			switchState = bit.bor(switchState,tonumber(systemRoutingData[currentLoadedStates[i][1]+1][8]))
			switchReq = bit.bor(switchReq,tonumber(systemRoutingData[currentLoadedStates[i][1]+1][7]))
		end
		setOutputState(signalState,switchState)
		currentState[1] = signalReq
		currentState[2] = signalState
		currentState[3] = switchReq
		currentState[4] = switchState
	else
		setOutputState(0,0)
		currentState = {0,0,0,0}
	end
end

-- TODO - Proper station display, so you can see what is going on!
--      - Probably separate out to separate program where you can provide the system
function updateDisplay(display)
  display.clear()
	display.setCursorPos(1,1)
  local line = 2
  
  -- (currentLoadedStates,{stateID, serviceID, trainID})
  
	display.write("Current loaded states:")

	display.setCursorPos(1,2)
	if #currentLoadedStates ~= 0 then
		for i = 1, #currentLoadedStates do
      display.setCursorPos(1, line)
      printColourAndRoute(currentLoadedStates[i][2],currentLoadedStates[i][3], display)
			display.write(tostring(systemRoutingData[currentLoadedStates[i][1]+1][2]))
      line = line + 1
		end
	end
  
  display.setCursorPos(1,8)
	display.write("Current requests:")
  display.setCursorPos(1,9)
  line = 9
	if #requestList ~= 0 then
		for i = 1, #requestList do
      display.setCursorPos(1, line)
      printColourAndRoute(requestList[i][2],requestList[i][3], display)
			display.write(tostring(mRail.location_name[stationConfig.detectorEntranceIDMapping[requestList[i][1]]]))
      line = line + 1
		end
	end
	
  display.setCursorPos(1,14)
  display.write("Alarms:")
  display.setCursorPos(1,15)
  line = 15
	if #alarms ~= 0 then
		for i = 1, #alarms do
      display.setCursorPos(1, line)
      printColourAndRoute(alarms[i][2], alarms[i][3], display)
			display.write(textutils.formatTime(alarms[i][4]))
      line = line + 1
		end
	end
end

local function renewAlarms()
  for i = 1, #alarms do
    local alarmTime = alarms[i][4]
    
    -- Check that the alarm is still in the future
    if alarmTime < os.time() then
      alarmTime = (os.time() + 0.5) % 24
    end
    
    -- Generate a new alarm and update the alarmID
    local alarmID = os.setAlarm(alarmTime)
		alarms[i][1] = alarmID
  end
end

local function groupData()
  return {currentLoadedStates, requestList, currentState, alarms}
end

local function saveState()
  mRail.saveData(stateFile, groupData())
end

local function loadState()
  currentState = groupData()
  loadedState = mRail.loadData(stateFile, currentState)
  
  -- Check if something new was actually loaded
  if currentState == loadedState then
    return
  end
  
  currentLoadedStates = loadedState[1]
  requestList = loadedState[2]
  currentState = loadedState[3]
  alarms = loadedState[4]
  
  --Renew alarms (alarms are not preserved during a reset)
  renewAlarms()
end

-- Program Stuff
local program = {}

-- Program Functions
function program.setup(config_)
  config = config_
  log.info("Starting pogram setup")
  -- Setup stuff
  modem = peripheral.wrap(config.modemSide)
  modem.open(mRail.channels.detect_channel)
  modem.open(mRail.channels.station_route_request)
  modem.open(mRail.channels.station_dispatch_request)
  modem.open(mRail.channels.station_dispatch_channel)
  modem.open(mRail.channels.ping_request_channel)
  modem.open(mRail.channels.control_channel)
  
  if config.controlType == "wireless" then
    signalController = peripheral.wrap(config.signalControl)
    switchController = peripheral.wrap(config.switchControl)
    releaseController = peripheral.wrap(config.releaseControl)
  end
  
  loadStateTable()
  
  log.info("Loading station config")
  mRail.loadConfig("./mRail/network-configs/.station-" .. tostring(config.stationID) .. "-config",stationConfig)
  log.debug("Station config loaded")
  
  log.info("Loading routing config")
  stationRouting = dofile("./mRail/network-configs/.station-routing-config")
  log.debug("Routing config loaded")
  
  if config.monitor == nil or config.monitor == "term" then
    monitor = term
  else
    monitor = peripheral.wrap(config.monitor)
  end
  
  updateState()
  updateDisplay(monitor)
  loadState()
  log.info("Program setup complete")
end

function program.onLoop()
	updateState()
	updateDisplay(monitor)
  saveState()
end


-- Modem Messages

-- TODO - Comment function
function program.detect_channel(decodedMessage)
  -- Handle messages on the detection channel
    -- Message format:
  -- modem, detectorID, serviceID, trainID, textMessage
			
  -- Check if the detector corresponds to the an exit location
  for i = 1, #currentLoadedStates do
    local dectectorNumber = tonumber(systemRoutingData[currentLoadedStates[i][1]+1][4])
    local exitDetectorID = stationConfig.detectorExitIDMapping[dectectorNumber]
    if tonumber(decodedMessage.detectorID) == exitDetectorID and tonumber(decodedMessage.trainID) == tonumber(currentLoadedStates[i][3]) then
      log.debug("Removing state")
      local stateBeingRemoved = currentLoadedStates[i][1]
      local stateToAdd = 0
      if systemRoutingData[stateBeingRemoved+1][10] ~= 0 then
        stateToAdd = tonumber(systemRoutingData[stateBeingRemoved+1][10])
      end
      log.trace("State to add: " .. stateToAdd)
      tryRemove(stateBeingRemoved)
      if stateToAdd ~= 0 then
        --check if it's a platformID
        for j = 1, #stationConfig.entryPlatformStateMapping do
          local a = stationConfig.detectorExitIDMapping[stationConfig.entryPlatformStateMapping[j][1]]
          if a == tonumber(decodedMessage.detectorID) then
            -- then it's a platformID
            setDepartureAlarm(decodedMessage.serviceID, tonumber(decodedMessage.trainID))
          end
        end
        --if so then make an alarm
        tryAdd(stateToAdd, decodedMessage.serviceID, decodedMessage.trainID)
      end
      processRequests()
      break
    end
  end
  
  -- Check if the detector corresponds to the an entry location
  for i = 1, #stationConfig.detectorEntranceIDMapping do
    if stationConfig.detectorEntranceIDMapping[i] == tonumber(decodedMessage.detectorID) then
      local entryID = i
      log.trace("Entry ID: " .. entryID)
      logRequest(entryID, decodedMessage.serviceID, decodedMessage.trainID,0,1)
      processRequests()
      break
    end
  end
end

-- TODO - Comment function
function program.station_route_request(decodedMessage)
  -- Handle messages on the station route request channel
  -- Message format:
  -- modem, stationID, entryID, exitID, serviceID, trainID
  
  -- Check if the message is for this station
  if tonumber(decodedMessage.stationID) == tonumber(config.stationID) then
    if tryRoute(tonumber(decodedMessage.entryID), tonumber(decodedMessage.exitID),decodedMessage.serviceID, decodedMessage.trainID) == false then
    end
  end
end

-- TODO - Comment function
function program.station_dispatch_request(decodedMessage)
  -- Handle messages on the station dispatch request channel
  for i = 1, #stationConfig.detectorDepotIDMapping do
    if stationConfig.detectorDepotIDMapping[i] == tonumber(decodedMessage.detectorID) then
      local entryID = i
      log.info("Dispatch from Depot requested")
      log.trace("Entry ID: " .. entryID)
      logRequest(entryID, decodedMessage.serviceID, decodedMessage.trainID, decodedMessage.detectorID,1)
      processRequests()
      break
    end
  end
end

-- TODO - Comment function
function program.station_dispatch_channel(decodedMessage)
  -- Handle messages on the station dispatch channel
  if tonumber(decodedMessage.stationID) == tonumber(config.stationID) then
    log.info("Dispatch from Station requested")
    -- find where the train is
    local entryID = 0
    
    -- loop through all the states
    for i = 1, #currentLoadedStates do
      -- state, service, train
      -- check if the service ID matches
      if tostring(currentLoadedStates[i][2]) == tostring(decodedMessage.serviceID) then
        for j = 1, #stationConfig.entryPlatformStateMapping do
          if tonumber(currentLoadedStates[i][1]) == tonumber(stationConfig.entryPlatformStateMapping[j][2]) then
            entryID = tonumber(stationConfig.entryPlatformStateMapping[j][1])
          end
        end
        -- if so then check that the state corresponds to a platform
      end
    end
    -- request a dispatch
    if entryID ~= 0 then
      for i = 1, #alarms do
        if tonumber(alarms[i][3]) == tonumber(decodedMessage.trainID) then
          table.remove(alarms,i)
          break
        end
      end
      logRequest(entryID, tostring(decodedMessage.serviceID), tonumber(decodedMessage.trainID), 0, 2)
      processRequests()
    end
  end
end



-- Alarms
-- TODO - Comment function
function program.handleAlarm(alarmID)
  for i = 1, #alarms do
    if alarms[i][1] == alarmID then
      -- find where the train is
      local entryID = 0
      
      -- loop through all the states
      for j = 1, #currentLoadedStates do
        -- state, service, train
        -- check if the service ID matches
        if tostring(currentLoadedStates[j][2]) == tostring(alarms[i][2]) then
          for k = 1, #stationConfig.entryPlatformStateMapping do
            if tonumber(currentLoadedStates[j][1]) == tonumber(stationConfig.entryPlatformStateMapping[k][2]) then
              entryID = tonumber(stationConfig.entryPlatformStateMapping[k][1])
            end
          end
          -- if so then check that the state corresponds to a platform
        end
      end
      -- request a dispatch
      if entryID ~= 0 then
        logRequest(entryID, alarms[i][2], alarms[i][3], 0, 2)
        processRequests()
        log.debug("Request made")
        
      else
        log.debug("No Request Made")
      end
      table.remove(alarms,i)
      break
    end
  end
end

function program.handleRedstone()
  
end

return program