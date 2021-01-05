-- mRail Detector Computer
-- (C) 2020-21 Sam Lane

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

-- From which all other programs are derived...
local program = {}

-- Program Functions
function program.setup(config_)
  config = config_
  
  modem = peripheral.wrap(config.modemSide)

  modem.open(mRail.channels.oneway_dispatch_confirm)

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
  if (decodedMessage.detectorID == tonumber(config.ids[1]) or decodedMessage.detectorID == tonumber(config.ids[2])) and config.releaseSide ~= "null" then
    log.info("Releasing train from " .. config.releaseSide)
    redstone.setOutput(config.releaseSide, true)
    sleep(1)
    redstone.setOutput(config.releaseSide, false)
  end
end

function program.handleMinecart(side, loco, locoName, primary, secondary, destination)
  if (locoName ~= mRail.item_names.train and locoName ~= mRail.item_names.e_train) then
    return
  end
  
  local trainID = 16 - tonumber(secondary)
  log.debug("trainID: " .. tostring(trainID))
  local serviceID = destination
  local detectorID = ""
  local textMessage = ""
  log.info("Detection on " .. side)
  
  -- TODO - Clean this up - remove if and have 1 and 2 correspond to a table with those things in
  --      - maybe put it in mRail if that would be useful?
  detectorID = tonumber(config.ids[idSide[side]])
  textMessage = "Last seen at " .. mRail.location_name[config.ids[idSide[side]]]
  if side == config.releaseSideID and config.releaseSide ~= "null" then
    textMessage = "Requesting release from " .. mRail.location_name[tonumber(config.ids[idSide[side]])]
    mRail.oneway_request_dispatch(modem, detectorID, serviceID, trainID)
    log.info("Dispatch requested on " .. side)
  end
  mRail.detection_broadcast(modem, detectorID, serviceID, trainID, textMessage)
end

function program.handleRedstone()
  
end

return program