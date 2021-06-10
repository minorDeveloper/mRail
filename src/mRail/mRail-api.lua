--- mRail system API
-- @module mRail
-- @author Sam Lane
-- @copyright 2020-21

--- @todo Add functions for complete network control and ability to reset things

--- @todo Comment all

local mRail = {}

-- Load APIs
json = require("./mRail/json")
log = require("./mRail/log")

mRail.modem = nil


--- Color name to number conversion
local col_to_num = {
	white = 1,
	orange = 2,
	magenta = 3,
	light_blue = 4,
	yellow = 5,
	lime = 6,
	pink = 7,
	gray = 8,
	light_gray = 9,
	cyan = 10,
	purple = 11,
	blue = 12,
	brown = 13,
	green = 14,
	red = 15,
	black = 16
}

--- Converts the color of train detected to an ID number
local num_to_col = {
	"white",
	"orange",
	"magenta",
	"light_blue",
	"yellow",
	"lime",
	"pink",
	"gray",
	"light_gray",
	"cyan",
	"purple",
	"blue",
	"brown",
	"green",
	"red",
	"black"
}

--- Internal representation of trains and minecarts
mRail.item_names = {
	train   = "Perpetuum Locomotive", -- Perpetuum Locomotive
	e_train = "Electric Locomotive", -- Electric Locomotive
	cart    = "Minecart", -- Minecart
	anchor  = "Admin Worldspike Cart" -- Admin Worldspike Cart
}

--- Links config name alias to program name
mRail.programs = {
  ["depotCollect"] = "mRail-collection",        -- mRail-collection
  ["depotRelease"] = "mRail-release",           -- mRail-release
  ["detector"]     = "mRail-detector",          -- mRail-detector
  ["dispatch"]     = "mRail-dispatch",          -- mRail-dispatch
  ["network"]      = "mRail-networkControl",    -- mRail-networkControl
  ["oneway"]       = "mRail-onewayControl",     -- mRail-onewayControl
  ["platform"]     = "mRail-platformDisplay",   -- mRail-platformDisplay
  ["station"]      = "mRail-stationController", -- mRail-stationController
  ["time"]         = "mRail-time",              -- mRail-time
  ["tracker"]      = "mRail-tracker",           -- mRail-tracker
}

--- Links config name alias to program config structure
mRail.configs = {
  ["depotCollect"] = ".collection-config",  -- .collection-config
  ["depotRelease"] = ".release-config",     -- .release-config
  ["detector"]     = ".detector-config",    -- .detector-config
  ["dispatch"]     = ".dispatch-config",    -- .dispatch-config
  ["network"]      = ".network-config",     -- .network-config
  ["oneway"]       = ".oneway-config",      -- .oneway-config
  ["platform"]     = ".platform-config",    -- .platform-config
  ["station"]      = ".station-config",     -- .station-config
  ["time"]         = ".time-config",        -- .time-config
  ["tracker"]      = ".tracker-config",     -- .tracker-config
}

--- Links config name alias to description of program
mRail.aliases = {
  ["depotCollect"] = "Train Collection Depot",  -- Train Collection Depot
  ["depotRelease"] = "Train Release Depot",     -- Train Release Depot
  ["detector"]     = "Locomotive Detector",     -- Locomotive Detector
  ["dispatch"]     = "Dispatch Computer",       -- Dispatch Computer
  ["network"]      = "Network Controller",      -- Network Controller
  ["oneway"]       = "One-way Controller",      -- One-way Controller
  ["platform"]     = "Platform Display",        -- Platform Display
  ["station"]      = "Station Controller",      -- Station Controller
  ["time"]         = "System Reboot Computer",  -- System Reboot Computer
  ["tracker"]      = "Train Tracker",           -- Train Tracker
}

--- Location of the loaded program's config file
mRail.configLoc    = "./mRail/program-state/.config"

--- Modem channels used by mRail
mRail.channels = {
  ping_channel             = 01, -- 01
	detect_channel           = 02, -- 02
	train_info               = 03, -- 03
	location_update_channel  = 04, -- 04
  next_station_request     = 05, -- 05
  next_station_update      = 06, -- 06
  ping_request_channel     = 07, -- 07
  control_channel          = 08, -- 08
  data_request_channel     = 09, -- 09
	dispatch_channel         = 10, -- 10
	station_dispatch_confirm = 11, -- 11
	station_dispatch_request = 12, -- 12
	oneway_dispatch_confirm  = 13, -- 13
	oneway_dispatch_request  = 14, -- 14
	timetable_updates        = 15, -- 15
	station_route_request    = 16, -- 16
	station_dispatch_channel = 17, -- 17
	screen_update_channel    = 18, -- 18
	screen_platform_channel  = 19, -- 19
	request_dispatch_channel = 20, -- 20
  control_response_channel = 21, -- 21
  gps_data_request_channel = 22, -- 22
  gps_data_response_channel= 23, -- 23
	error_channel            = 999,-- 999
}

--- Sends a ping from the given computer with a program name and id
-- @param programName Name of the current running program
-- @param id Id of the computer
function mRail.ping(programName, id)
  log.info("Ping!")
  local message = json.encode({
    ["programName"] = programName,
    ["id"] = id
  })
  mRail.transmit(mRail.channels.ping_channel,1,message)
end

--- Requests all active computers retransmit pings
function mRail.requestPings()
  log.info("Requesting pings from all connected services")
  mRail.transmit(mRail.channels.ping_request_channel,1,"")
end

function mRail.requestGPSData(radius, timeout)
  log.info("Requesting computers within " .. radius .. " blocks respond with info")
  
  local locX, locY, locZ = gps.locate()
  
  local message = json.encode({
    ["locX"] = locX,
    ["locY"] = locY,
    ["locZ"] = locZ,
    ["radius"] = id
  })
  
  mRail.transmit(mRail.gps_data_request_channel,1,message)
  
  -- Make a 5 second timer
  local timeoutTimer = os.startTimer(timeout)
  
  -- Keep recieving messages and put the info in a table until the time runs out
  local nearbyComputers = receiveMessages(timeout)
  
  -- Sort the table in order of distance
  table.sort(nearbyComputers, function(a,b) return a[3] < b[3] end)
  
  -- Print that to a screen
  for i = 1, #nearbyComputers do
    print(nearbyComputers[1] .. ": " .. nearbyComputers[2] .. "-ID: " .. nearbyComputers[3])
  end
end

local function receiveMessages(timeout)
  local nearbyComputers = {}
  while true do
    event, param1, param2, param3, param4, param5, param6 = os.pullEvent()
    
    if event == "timer" and param1 == timeoutTime then
      return nearbyComputers
    elseif event == "modem_message" and param2 == gps_data_response_channel then
      local decodedMessage = json.decode(param4)
      table.insert(nearbyComputers, {decodedMessage.computerType, decodedMessage.info, decodedMessage.distance})
    end
  end
end


function mRail.responseGPSData(computerType, info, distance)
  local message = json.encode({
    ["computerType"] = computerType,
    ["info"] = info,
    ["distance"] = distance
  })
  
  mRail.transmit(mRail.gps_data_response_channel,1,message)
end

--- Transmits a control message to another device
-- @param programName The program type of the computer being controlled
-- @param id The id of the computer being controlled
-- @param command (Table) command being transmitted
-- @param dataset Any additional data accompanying the command
function mRail.control(programName, id, command, dataset)
  log.info("Transmitting control message")
  local message = json.encode({
    ["programName"] = programName,
    ["id"] = id,
    ["command"] = command,
    ["dataset"] = dataset
  })
  mRail.transmit(mRail.channels.control_channel,1,message)
end

--- Requests information from another device
-- @param programName The program type of the receiving device
-- @param id ID of the receiving device
-- @param command Command being transmitted
function mRail.requestState(programName, id, command)
  log.info("Transmitting request for data from " .. tostring(programName) .. " id: " .. tostring(id))
  local message = json.encode({
    ["programName"] = programName,
    ["id"] = id,
    ["command"] = command
  })
  mRail.transmit(mRail.channels.data_request_channel,1,message)
end

--- Response to a control message
-- @param programName Program type of this device
-- @param id The id of this device
-- @param command Copy of the command sent
-- @param success If the command was successfully executed
-- @param returnMessage Human readable message describing the command executed
function mRail.response(programName, id, command, success, returnMessage)
  log.info("Responding to control message")
  local message = json.encode({
    ["programName"] = programName,
    ["id"] = id,
    ["command"] = command,
    ["success"] = success,
    ["message"] = returnMessage
  })
  mRail.transmit(mRail.channels.control_response_channel,1,message)
end

--- Broadcast the detection of a train at a given detector
-- @param detectorID
-- @param serviceID Service (string) of the detected train
-- @param trainID ID of the detected train
-- @param textMessage Message to be broadcast
function mRail.detection_broadcast(detectorID, serviceID, trainID, textMessage)
	log.info("Notifying Tracker and Stations of detection")
	local message = json.encode({
		["detectorID"] = detectorID,
		["serviceID"] = serviceID,
		["trainID"] = trainID,
		["textMessage"] = textMessage
		})
	mRail.transmit(mRail.channels.detect_channel,1,message)
end

--- Request information about the next station for a given service
-- @param serviceID
-- @param trainID
-- @param stationID
function mRail.next_station_request(serviceID, trainID, stationID)
  log.info("Requesting next station update for " .. serviceID)
  local message = json.encode({
    ["serviceID"] = serviceID,
    ["trainID"]   = trainID,
    ["stationID"] = stationID
  })
  mRail.transmit(mRail.channels.next_station_request, 1, message)
end

--- Provides tracking with an update regarding the next station for a given train
-- @param nextStationID
-- @param trainID
function mRail.next_station_update(nextStationID, trainID)
  log.info(trainID .. ": next station is " .. nextStationID)
  local message = json.encode({
    ["nextStationID"] = nextStationID,
    ["trainID"] = trainID
  })
  mRail.transmit(mRail.channels.next_station_update, 1, message)
end

--- Requests the dispatch server release the given train
-- . Use this when manually triggering a train release to ensure departure boards and alarms are set correctly
-- @param receiverID Depot ID that the service is to be released from
-- @param serviceID
-- @param trainID
-- @usage mRail.request_dispatch(80, "HR Expr", 5)
function mRail.request_dispatch(receiverID, serviceID, trainID)
	log.info("Requesting the " .. mRail.number_to_color(trainID) .. " train from " .. receiverID .. " on route " .. serviceID)
	local message = json.encode({
		['recieverID'] = receiverID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	log.debug("Message transmitted")
	log.trace(message)
	mRail.transmit(mRail.channels.request_dispatch_channel,1,message)
end

--- Dispatch requesting the release of a train from a depot
-- . Not for manual use
-- @param receiverID
-- @param serviceID
-- @param trainID
function mRail.dispatch_train(receiverID, serviceID, trainID)
	log.info("Dispatching the " .. mRail.number_to_color(trainID) .. " train from " .. receiverID .. " on route " .. serviceID)
	local message = json.encode({
		['recieverID'] = receiverID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	log.debug("Message transmitted")
	log.trace(message)
	mRail.transmit(mRail.channels.dispatch_channel,1,message)
end

--- Command to a station to release a train from its platform
-- @param stationID
-- @param serviceID
-- @param trainID
function mRail.station_dispatch_train(stationID, serviceID, trainID)
	log.info("Dispatching the " .. mRail.number_to_color(trainID) .. " train from " .. stationID .. " on route " .. serviceID)
	local message = json.encode({
		['stationID'] = stationID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	log.debug("Message transmitted")
	log.trace(message)
	mRail.transmit(mRail.channels.station_dispatch_channel,1,message)
end

-- Station-Depot Comms

--- Allows a depot to request permission to dispatch a train
-- @param stationID
-- @param serviceID
-- @param trainID
-- @param detectorID
function mRail.station_request_dispatch(stationID, serviceID, trainID, detectorID)
	log.info("Requesting permission from station " .. stationID .. "to dispatch train")
	local message = json.encode({
		['stationID'] = stationID,
		['serviceID'] = serviceID,
		['trainID'] = trainID,
		['detectorID'] = detectorID
	})
	log.debug("Message transmitted")
	log.trace(message)
	mRail.transmit(mRail.channels.station_dispatch_request,1,message)
end

--- Station confirms that a given depot may release a train
-- @param receiverID
-- @param serviceID
-- @param trainID
function mRail.station_confirm_dispatch(receiverID, serviceID, trainID)
	log.info("Giving " .. receiverID .. " permission to dispatch train")
	local message = json.encode({
		['recieverID'] = receiverID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	log.debug("Message transmitted")
	log.trace(message)
	mRail.transmit(mRail.channels.station_dispatch_confirm,1,message)
end

--- DEPRECATED, allows for a specific route to be requested through the given station
-- @param stationID
-- @param entryID
-- @param exitID
-- @param serviceID
-- @param trainID
function mRail.station_request_route(stationID, entryID, exitID, serviceID, trainID)
	log.info("Requesting route")
	local message = json.encode({
		['stationID'] = stationID,
		['entryID'] = entryID,
		['exitID'] = exitID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	mRail.transmit(mRail.channels.station_route_request,1,message)
end


-- Oneway-Detector Comms

--- Allows a detector computer to request permission from block control to
-- release a train
-- @param detectorID
-- @param serviceID
-- @param trainID
function mRail.oneway_request_dispatch(detectorID, serviceID, trainID)
	log.info("Requesting permission to dispatch train " .. trainID)
	local message = json.encode({
		['detectorID'] = detectorID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	log.debug("Message transmitted")
	log.trace(message)
	mRail.transmit(mRail.channels.oneway_dispatch_request,1,message)
end

--- Block control gives permission for a detector computer to release a train
-- @param detectorID
-- @param serviceID
-- @param trainID
function mRail.oneway_confirm_dispatch(detectorID, serviceID, trainID)
	log.info("Giving " .. detectorID .. " permission to release train")
	local message = json.encode({
		['detectorID'] = detectorID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	log.debug("Message transmitted")
	log.trace(message)
	mRail.transmit(mRail.channels.oneway_dispatch_confirm,1,message)
end

--- Provides information regarding the current timetable and routing of trains
-- @param timetable
function mRail.timetable_update(timetable)
	log.info("Updating timetable for all stations")
	local message = json.encode({
		['timetable'] = timetable
	})
	log.debug("Message transmitted")
	log.trace(message)
	mRail.transmit(mRail.channels.timetable_updates,1,message)
end

--- Provides information to platform displays regarding the arrivals and departures 
-- still due at a given station
-- @param stationID
-- @param arrivals
-- @param departures
function mRail.screen_update(stationID, arrivals, departures)
  log.info("Sending updates to screens")
	local message = json.encode({
		['stationID'] = stationID,
		['arrivals'] = arrivals,
		['departures'] = departures
  })
  log.debug("Message transmitted")
	log.trace(message)
	mRail.transmit(mRail.channels.screen_update_channel,1,message)
end

--- Allows stations to communicate platform allocations with the display screens
-- @param stationID
-- @param serviceID
-- @param platform
function mRail.screen_platform_update(stationID, serviceID, platform)
  log.info("Updating platform allocation")
	local message = json.encode({
		['stationID'] = stationID,
		['serviceID'] = serviceID,
		['platform'] = platform
  })
  log.debug("Message transmitted")
	log.trace(message)
	mRail.transmit(mRail.channels.screen_platform_channel,1,message)
end

--- Allows an error to be raised with a given error level
-- @param errMessage
-- @param errorLevel
function mRail.raise_error(errMessage, errorLevel)
  log.error(errMessage)
	local x = 0
	local y = 0
	local z = 0
	x,y,z = gps.locate(1)
	local message = json.encode({
	['x'] = x,
	['y'] = y,
	['z'] = z,
	['errMessage'] = errMessage,
	['errorLevel'] = errorLevel
})
	log.debug("Message transmitted")
	log.trace(message)
	mRail.transmit(mRail.channels.error_channel,1,message)
end


--- Saves data to a file
-- @param filename
-- @param data
function mRail.saveData(filename, data)
  log.debug("Saving data to " .. filename)
  log.trace(data)
	jsonEncoded = json.encode(data)
  
	local f = fs.open(filename, "w")
	f.write(jsonEncoded)
  log.debug("File write successful")
	f.close()
end

--- Loads data from a given file
-- @param filename
-- @param data
function mRail.loadData(filename, data)
  log.info("Load data from " .. filename)
	if fs.exists(filename) then
		log.debug(filename .. " exists")
		local f = fs.open(filename, "r")
		local fileContents = f.readAll()
		local jsonDecoded = json.decode(fileContents)
    return jsonDecoded
	else
		log.debug(filename .. " not present - saving")
		mRail.saveData(filename, data)
    return data
	end
end

--- Executes the given file
-- @param filename
-- @param parameters
local function executeFile(filename, ...)
  local ok, err = loadfile( filename )
  log.debug( "Running "..filename )
  if ok then
    return ok( ... )
  else
    printError( err )
  end
end


--- Loads config file into variable (uses modem for error messages)
-- @param file_name
-- @param config_var
function mRail.loadConfig(file_name,config_var)
  log.info("Loadign config file")
  local returnVal = loadConfig(file_name,config_var)
  
  if returnVal == 1 then
    raise_error(modem,"No configuration file",1)
  end
  return returnVal
end

--- Loads config file into variable
-- @param file_name
-- @param config_var
function mRail.loadConfig(file_name,config_var)
	if fs.exists(file_name) then
		log.debug("Loading config file...")
		local _config = executeFile(file_name)
		for k,v in pairs(_config) do
			config_var[k] = v
		end
	else
		log.debug("Error, no configuration file!.")
		return 1
	end
end

--- Saves a given program config in a user readable format
-- @param filename
-- @param config_var
function mRail.saveConfig(filename, config_var)
  local f = fs.open(filename, "w")
  f.writeLine("return {")
  for params, vals in pairs(config_var) do
    local line = "  " .. tostring(params) .. " = "
    if type(vals) ~= "table" then
      line = line .. "\"" .. tostring(vals) .. "\","
    else
      line = line .. "{"
      for i = 1, #vals do
        line = line .. "\"" .. tostring(vals[i]) .. "\","
      end
      line = line .."},"
    end
    f.writeLine(line)
  end
	f.writeLine("}")
	f.close()
end

-- @todo Comment

-- @todo Make this more readable

--- Checks the given config
-- @param config
function mRail.checkConfig(config)
  local targetConfigName = "./mRail/program-configs/" .. mRail.configs[config.programType]
  local targetConfig = {}
  mRail.loadConfig(targetConfigName, targetConfig)
  for i = 1, #targetConfig do
    local validConfig = true
    for parameter, values in pairs(targetConfig[i]) do
      -- Check that the value exists
      if tostring(parameter) ~= "setupName" then
        if config[parameter] ~= nil then
        -- Check that the key meets one of the requirements
          local oneMatches = false
          local possibleValues = values[1]
          for j = 1, #possibleValues do
            if type(config[parameter]) == "table" then
              -- TODO - Figure out this bit
            else
              if string.match(tostring(config[parameter]),possibleValues[j]) ~= nil then
                oneMatches = true
                break
              end
            end
          end
          if not oneMatches then
            validConfig = false
          end
        else
          validConfig = false
        end
      end
      if validConfig then
        log.debug("Config valid")
        return true
      end
    end
  end
  log.error("Invalid config")
  read()
  return false
end

--- Gets a side where a modem is attached
function mRail.getModemSide()
  local sModemSide = nil
  for _, sSide in ipairs(rs.getSides()) do
    if peripheral.getType(sSide) == "modem" and peripheral.call(sSide, "isWireless") then
      sModemSide = sSide
      break
    end
  end
  return sModemSide
end

function mRail.wrapModem()
  local modemSide = mRail.getModemSide()
  if modemSide ~= nil then
    mRail.modem = peripheral.wrap(modemSide)
    return true
  end
  return false
end

function mRail.transmit(channel, returnChannel, message)
  if mRail.modem == nil and mRail.wrapModem() == false then
    return
  end
  mRail.modem.transmit(channel,returnChannel,message)
end

--- Checks if two variables are the same string
-- @param strA
-- @param strB
function mRail.identString(strA, strB)
  if tostring(strA) == tostring(strB) then
    return true
  end
  return false
end

--- Checks if two variables are the same number
-- @param numA
-- @param numB
function mRail.identNum(numA, numB)
  if tonumber(strA) == tonumber(strB) then
    return true
  end
  return false
end

--- Converts a colour string to its representative number
-- @param color
function mRail.color_to_number(color)
	return col_to_num[color]
end

--- Converts a colour number to its representative strin
-- @param number
function mRail.number_to_color(number)
	return  num_to_col[number]
end

mRail.eventHandler = {}

function mRail.setupWait(_eventHandler)
  mRail.eventHandler = _eventHandler
end


--- Custom sleep functionality 
-- Don't remember what this does
-- @param time
function mRail.wait(time)
  local timer = os.startTimer(time)
  
  while true do
    local event = {os.pullEvent()}
    
    if (event[1] == "timer" and event[2] == timer) then
      break
    else
      if type(mRail.eventHandler) == "function" then
        mRail.eventHandler(event)
      end
    end
  end
end

-- Load Global Config
local tempConfig = {}
log.info("Loading global config")
mRail.loadConfig("./mRail/network-configs/.global-config",tempConfig)
log.debug("Global config loaded")
mRail.station_name = tempConfig.stationName
mRail.location_name = tempConfig.locationName

return mRail