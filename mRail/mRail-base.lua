-- mRail System Base Program
-- (C) 2020-21 Sam Lane

-- Base program where all mRail systems are launched from

-- Configuration
local config = {}
local configFilename = "./mRail/.config"

-- Load APIs
mRail = require("./mRail/mRail-api")
json = require("./mRail/json")
log = require("./mRail/log")

-- Load config
log.info("Loading config file")
mRail.loadConfig(configFilename,config)
log.debug("Config file loaded")
local configState = mRail.checkConfig(config)

-- Load appropriate program based on config file
log.info("Loading program")
local program = require(mRail.programs[config.programType])
log.debug("Program loaded")

handleMessages = {
  [tostring(mRail.channels.detect_channel)]           = program.detect_channel,
  [tostring(mRail.channels.train_info)]               = program.train_info,
  [tostring(mRail.channels.location_update_channel)]  = program.location_update_channel,
  [tostring(mRail.channels.dispatch_channel)]         = program.dispatch_channel,
  [tostring(mRail.channels.station_dispatch_confirm)] = program.station_dispatch_confirm,
  [tostring(mRail.channels.station_route_request)]    = program.station_route_request,
  [tostring(mRail.channels.station_dispatch_request)] = program.station_dispatch_request,
  [tostring(mRail.channels.oneway_dispatch_confirm)]  = program.oneway_dispatch_confirm,
  [tostring(mRail.channels.station_dispatch_request)] = program.station_dispatch_request,
  [tostring(mRail.channels.timetable_updates)]        = program.timetable_updates,
  [tostring(mRail.channels.station_route_request)]    = program.station_route_request,
  [tostring(mRail.channels.station_dispatch_channel)] = program.station_dispatch_channel,
  [tostring(mRail.channels.screen_update_channel)]    = program.screen_update_channel,
  [tostring(mRail.channels.screen_platform_channel)]  = program.screen_platform_channel,
  [tostring(mRail.channels.request_dispatch_channel)] = program.request_dispatch_channel,
  [tostring(mRail.channels.error_channel)]            = program.error_channel,
}

-- Trigger setup of program
log.info("Setting up program")
program.setup(config)
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
  elseif event == "minecart"
    program.handleMinecart(param6)
	elseif event == "alarm" then
    -- Hand off to program to handle the alarm
    log.trace("Alarm triggered")
		program.handleAlarm(param1)
	end
  program.onLoop()
end