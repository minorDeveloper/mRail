--- System Base Program
-- Program where all mRail systems are launched from
-- @module base-program
-- @author Sam Lane
-- @copyright 2020-21


-- Configuration
local config = {}

-- Load APIs
mRail = require("./mRail/mRail-api")
json  = require("./mRail/json")
log   = require("./mRail/log")

-- Load config
log.info("Loading config file")
mRail.loadConfig(mRail.configLoc,config)
log.debug("Config file loaded")
local configState = mRail.checkConfig(config)

-- Load appropriate program based on config file
log.info("Loading program")
local program = require(mRail.programs[config.programType])

--- Packages the program id and name and transmits a ping
function program.ping()
  local id = nil
  local name = nil
  if config.id ~= nil then
    id = config.id
  elseif config.stationID ~= nil then
    id = config.stationID
  elseif config.ids ~= nil then
    id = config.ids
  end
  
  if config.name ~= nil then
    name = config.name
  end
  
  mRail.ping(mRail.programs[config.programType], id, name)
end

--- Implementation of the ping request response
function program.ping_request_channel(decodedMessage)
  -- Handle requests for a ping
  log.info("Ping requested")
  program.ping()
end
--

--- Implementation of the control channel message
function program.control_channel(decodedMessage)
  -- Ensure that the control message was intended for a program of this type
  if not mRail.identString(config.programType, decodedMessage.programName) then
    return
  end
  log.debug("Control message recieved")
  
  -- Confirm that the control message has the correct ID
  if not program.checkValidID(decodedMessage.id) then
    return
  end
  
  local cmd = decodedMessage.command
  log.trace("cmd:  " .. tostring(cmd))
  local data = decodedMessage.dataset
  log.trace("data: " .. tostring(data))
  if cmd == nil then
    return
  end
  
  local response
  if program.controlTable[tostring(cmd)] == nil then
    log.debug("Invalid command provided: " .. cmd)
    response = {false, "Invalid command"}
  else
    local func = program.controlTable[tostring(cmd)](data)
  
    if (func) then
      response = func
    end
  end
  
  if response == nil then
    response = {false, "Command did not emit a response"}
  end
  
  mRail.response(decodedMessage.programName, decodedMessage.id, decodedMessage.command, response[1], response[2])
end
--

log.debug("Program loaded")

--- Converts message channels to program callbacks
-- @todo this can be so much neater
handleMessages = {
  [tostring(mRail.channels.ping_channel)]             = program.ping_channel,
  [tostring(mRail.channels.detect_channel)]           = program.detect_channel,
  [tostring(mRail.channels.train_info)]               = program.train_info,
  [tostring(mRail.channels.location_update_channel)]  = program.location_update_channel,
  [tostring(mRail.channels.next_station_request)]     = program.next_station_request,
  [tostring(mRail.channels.next_station_update)]      = program.next_station_update,
  [tostring(mRail.channels.dispatch_channel)]         = program.dispatch_channel,
  [tostring(mRail.channels.ping_request_channel)]     = program.ping_request_channel,
  [tostring(mRail.channels.control_channel)]          = program.control_channel,
  [tostring(mRail.channels.data_request_channel)]     = program.data_request_channel,
  [tostring(mRail.channels.station_dispatch_confirm)] = program.station_dispatch_confirm,
  [tostring(mRail.channels.station_route_request)]    = program.station_route_request,
  [tostring(mRail.channels.station_dispatch_request)] = program.station_dispatch_request,
  [tostring(mRail.channels.oneway_dispatch_confirm)]  = program.oneway_dispatch_confirm,
  [tostring(mRail.channels.oneway_dispatch_request)]  = program.oneway_dispatch_request,
  [tostring(mRail.channels.timetable_updates)]        = program.timetable_updates,
  [tostring(mRail.channels.station_route_request)]    = program.station_route_request,
  [tostring(mRail.channels.station_dispatch_channel)] = program.station_dispatch_channel,
  [tostring(mRail.channels.screen_update_channel)]    = program.screen_update_channel,
  [tostring(mRail.channels.screen_platform_channel)]  = program.screen_platform_channel,
  [tostring(mRail.channels.request_dispatch_channel)] = program.request_dispatch_channel,
  [tostring(mRail.channels.control_response_channel)] = program.control_response_channel,
  [tostring(mRail.channels.error_channel)]            = program.error_channel,
}

-- Trigger setup of program
log.info("Setting up program")
program.setup(config)
program.ping()
log.info("Program setup")

while true do
  -- Wait for event
	event, param1, param2, param3, param4, param5, param6 = os.pullEvent()
	if event == "modem_message" then
    log.trace("Modem message recieved")
		local channel = tonumber(param2)
		local decodedMessage = json.decode(param4)
    -- Hand off message to appropriate function based on the channel
    local func = handleMessages[tostring(channel)](decodedMessage)
    if (func) then
      func()
    end
  elseif event == "minecart" then
    program.handleMinecart(param1, param2, param3, param4, param5, param6)
	elseif event == "alarm" then
    -- Hand off to program to handle the alarm
    log.trace("Alarm triggered")
		program.handleAlarm(param1)
  elseif event == "redstone" then
    program.handleRedstone()
	end
  program.onLoop()
end