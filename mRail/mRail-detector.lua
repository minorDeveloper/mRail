--- Detector Computer
-- @module detector
-- @author Sam Lane
-- @copyright 2020-21

-- TODO - Add support for multiple detectors and multiple release points
-- TODO - let the config files accept an array as a config val not just a value
-- TODO - Comment everything

-- Load APIs
mRail = require("./mRail/mRail-api")
json = require("./mRail/json")
log = require("./mRail/log")

local config = {}

local idSide = {
  left = 1,
  right = 2,
}

local function triggerRelease(detectorID)
  if ((detectorID == tonumber(config.ids[1]) and config.releaseSideID == "left")
   or (detectorID == tonumber(config.ids[2]) and config.releaseSideID == "right")) 
   and config.releaseSide ~= "null" then
    log.info("Releasing train from " .. config.releaseSide)
    redstone.setOutput(config.releaseSide, true)
    sleep(1)
    redstone.setOutput(config.releaseSide, false)
    return {false, "Train released"}
  end
  return {false, "This detector doesn't have an output side"}
end

local function triggerControlRelease(data)
  --control(modem, programName, id, command, dataset)
  return triggerRelease(data.detectorID)
end

-- From which all other programs are derived...
local program = {}

program.controlTable  = {
  ["triggerRelease"]  = triggerControlRelease,
}

function program.checkValidID(id)
  if id == tonumber(config.ids[1]) or id == tonumber(config.ids[2]) then
    return true
  end
  return false
end
--

-- Program Functions
function program.setup(config_)
  config = config_
  
  modem = peripheral.wrap(config.modemSide)

  modem.open(mRail.channels.oneway_dispatch_confirm)
  modem.open(mRail.channels.ping_request_channel)
  modem.open(mRail.channels.control_channel)
  modem.open(mRail.channels.gps_data_request_channel)

  term.clear()
  term.setCursorPos(1,1)
  log.info("Name: 		    " .. config.name)
  log.info("Modem Side:   " .. config.modemSide)
  log.info("Release Side: " .. config.releaseSide)
end

function program.onLoop()
  
end


-- Modem Messages
function program.oneway_dispatch_confirm(decodedMessage)
  -- Handle messages on the oneway dispatch confirmation channel
  -- TODO - Add support for multiple detectors here
  triggerRelease(decodedMessage.detectorID)
end



function program.handleMinecart(side, loco, locoName, primary, secondary, destination)
  if (locoName ~= mRail.item_names.train and locoName ~= mRail.item_names.e_train) then
    return
  end
  
  local trainID = 16 - tonumber(secondary)
  log.debug("trainID: " .. tostring(trainID))
  local serviceID = destination
  local detectorID
  local textMessage = ""
  log.info("Detection on " .. side)
  
  detectorID = tonumber(config.ids[idSide[side]])
  if side == config.releaseSideID and config.releaseSide ~= "null" then
    textMessage = "Requesting release from " .. mRail.location_name[tonumber(config.ids[idSide[side]])]
    mRail.oneway_request_dispatch(detectorID, serviceID, trainID)
    log.info("Dispatch requested on " .. side)
  end
  
  textMessage = "Last seen at " .. mRail.location_name[tonumber(config.ids[idSide[side]])]
  mRail.detection_broadcast(detectorID, serviceID, trainID, textMessage)
end

function program.handleRedstone()
  
end

return program