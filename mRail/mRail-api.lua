-- mRail system API
-- (C) 2020 Sam Lane

-- TODO - Add functions for complete network control and ability to reset things
--      - Stations
--      - One-way Blocks
--      - Train Tracking
--      - Stop/Start Dispatch
-- TODO - Replace prints with logfile calls


local mRail = {}

json = require("./mRail/json")
log = require("./mRail/log")
log.usecolor = true


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


-- Global API Variables (for use in sub-programs)

mRail.item_names = {
	train = "Perpetuum Locomotive",
	e_train = "Electric Locomotive",
	cart = "Minecart",
	anchor = "Admin Worldspike Cart"
}

mRail.programs = {
  ["station"] = "mRail-stationController",
}

mRail.configs = {
  ["station"] = ".station-config"
}

mRail.channels = {
	detect_channel = 2,
	train_info = 3,
	location_update_channel = 4,
	dispatch_channel = 10,
	station_dispatch_confirm = 11,
	station_dispatch_request = 12,
	oneway_dispatch_confirm = 13,
	oneway_dispatch_request = 14,
	timetable_updates = 15,
	station_route_request = 16,
	station_dispatch_channel = 17,
	screen_update_channel = 18,
	screen_platform_channel = 19,
	request_dispatch_channel = 20,
	error_channel = 999
}


-- TODO - Pull all this out into network config files!




-- Broadcasts

function mRail.detection_broadcast(modem, detectorID, serviceID, trainID, textMessage)
	log.info("Notifying Tracker and Stations of detection")
	local message = json.encode({
		["detectorID"] = detectorID,
		["serviceID"] = serviceID,
		["trainID"] = trainID,
		["textMessage"] = textMessage
		})
	modem.transmit(channels.detect_channel,1,message)
end

-- TODO - Add ability to request next station from dispatch
-- TODO - Add ability to respond to next station request (broadcast to trainTracking)

-- TODO - Comment all of these functions

-- Dispatch-Depot comms

function mRail.request_dispatch(modem, recieverID, serviceID, trainID)
	log.info("Requesting the " .. number_to_color(trainID) .. " train from " .. recieverID .. " on route " .. serviceID)
	local message = json.encode({
		['recieverID'] = recieverID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	log.debug("Message transmitted")
	log.trace(message)
	modem.transmit(mRail.channels.request_dispatch_channel,1,message)
end


function mRail.dispatch_train(modem, recieverID, serviceID, trainID)
	log.info("Dispatching the " .. number_to_color(trainID) .. " train from " .. recieverID .. " on route " .. serviceID)
	local message = json.encode({
		['recieverID'] = recieverID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	log.debug("Message transmitted")
	log.trace(message)
	modem.transmit(mRail.channels.dispatch_channel,1,message)
end

function mRail.station_dispatch_train(modem, stationID, serviceID, trainID)
	log.info("Dispatching the " .. number_to_color(trainID) .. " train from " .. stationID .. " on route " .. serviceID)
	local message = json.encode({
		['stationID'] = stationID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	log.debug("Message transmitted")
	log.trace(message)
	modem.transmit(mRail.channels.station_dispatch_channel,1,message)
end

-- Station-Depot Comms

function mRail.station_request_dispatch(modem, stationID, serviceID, trainID, detectorID)
	log.info("Requesting permission from station " .. stationID .. "to dispatch train")
	local message = json.encode({
		['stationID'] = stationID,
		['serviceID'] = serviceID,
		['trainID'] = trainID,
		['detectorID'] = detectorID
	})
	log.debug("Message transmitted")
	log.trace(message)
	modem.transmit(mRail.channels.station_dispatch_request,1,message)
end

function mRail.station_confirm_dispatch(modem, recieverID, serviceID, trainID)
	log.info("Giving " .. recieverID .. " permission to dispatch train")
	local message = json.encode({
		['recieverID'] = recieverID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	log.debug("Message transmitted")
	log.trace(message)
	modem.transmit(mRail.channels.station_dispatch_confirm,1,message)
end

function mRail.station_request_route(modem, stationID, entryID, exitID, serviceID, trainID)
	log.info("Requesting route")
	local message = json.encode({
		['stationID'] = stationID,
		['entryID'] = entryID,
		['exitID'] = exitID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	modem.transmit(mRail.channels.station_route_request,1,message)
end


-- Oneway-Detector Comms

function mRail.oneway_request_dispatch(modem, detectorID, serviceID, trainID)
	log.info("Requesting permission to dispatch train " .. trainID)
	local message = json.encode({
		['detectorID'] = detectorID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	log.debug("Message transmitted")
	log.trace(message)
	modem.transmit(mRail.channels.oneway_dispatch_request,1,message)
end

function mRail.oneway_confirm_dispatch(modem, detectorID, serviceID, trainID)
	log.info("Giving " .. detectorID .. " permission to release train")
	local message = json.encode({
		['detectorID'] = detectorID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	log.debug("Message transmitted")
	log.trace(message)
	modem.transmit(mRail.channels.oneway_dispatch_confirm,1,message)
end

function mRail.timetable_update(modem, timetable)
	log.info("Updating timetable for all stations")
	local message = json.encode({
		['timetable'] = timetable
	})
	log.debug("Message transmitted")
	log.trace(message)
	modem.transmit(mRail.channels.timetable_updates,1,message)
end

function mRail.screen_update(modem, stationID, arrivals, departures)
  log.info("Sending updates to screens")
	local message = json.encode({
		['stationID'] = stationID,
		['arrivals'] = arrivals,
		['departures'] = departures
  })
  log.debug("Message transmitted")
	log.trace(message)
	modem.transmit(mRail.channels.screen_update_channel,1,message)
end

function mRail.screen_platform_update(modem, stationID, serviceID, platform)
  log.info("Updating platform allocation")
	local message = json.encode({
		['stationID'] = stationID,
		['serviceID'] = serviceID,
		['platform'] = platform
  })
  log.debug("Message transmitted")
	log.trace(message)
	modem.transmit(mRail.channels.screen_platform_channel,1,message)
end

function mRail.raise_error(modem, errMessage, errorLevel)
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
	modem.transmit(mRail.channels.error_channel,1,message)
end

-- Files and configuration

local function executeFile(filename, ...)
  local ok, err = loadfile( filename )
  log.debug( "Running "..filename )
  if ok then
    return ok( ... )
  else
    printError( err )
  end
end

function mRail.loadConfig(modem,file_name,config_var)
  log.info("Loadign config file")
  local returnVal = loadConfig(file_name,config_var)
  
  if returnVal == 1 then
    raise_error(modem,"No configuration file",1)
  end
  return returnVal
end

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

-- TODO - Comment
function mRail.checkConfig(config)
  local targetConfigName = "./mRail/program-configs/" .. mRail.configs[config.programType]
  local targetConfig = {}
  mRail.loadConfig(targetConfigName, targetConfig)

  for i = 1, #targetConfig do
    local validConfig = true
    for parameter, values in pairs(targetConfig[i]) do
      -- Check that the value exists
      if config[parameter] ~= nil then
        -- Check that the key meets one of the requirements
        local oneMatches = false
        for j = 1, #values do
          if string.match(config[parameter],values[j]) ~= nil then
            oneMatches = true
            break
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
  log.error("INVALID CONFIG")
  read()
  return false
end


-- Conversions

function mRail.color_to_number(color)
	return col_to_num[color]
end

function mRail.number_to_color(number)
	return  num_to_col[number]
end

-- Load stuff

local tempConfig = {}
log.info("Loading global config")
mRail.loadConfig("./mRail/network-configs/.global-config",tempConfig)
log.debug("Global config loaded")
mRail.station_name = tempConfig.stationName
mRail.location_name = tempConfig.locationName

return mRail