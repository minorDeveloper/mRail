-- mRail System Program Base
-- (C) 2020-21 Sam Lane

-- TODO - Comment all
-- TODO - Have Dispatch tell platform display what trains are currently in use
-- TODO - Add the ability to request a train be dispatched to the parent station to go somewhere!

-- Load APIs
mRail = require("./mRail/mRail-api")
json = require("./mRail/json")
log = require("./mRail/log")

local config = {}

local mappingFile = "./mRail/program-state/platformMapping"

--Route name, Expected platform
local routePlatformMapping = {}

local arrivals = {}
local departures = {}

local departuresDisplay
local arrivalsDisplay

-- TODO - Make this more elegant
function updateDisplay()
	if config.screens == 1 then
		singleDisplay()
	elseif config.screens == 2 then
		arrDepDisplay()
	end
end

-- TODO - Comment
function arrDepDisplay()
	departuresDisplay.clear()
	arrivalsDisplay.clear()
	
	departuresDisplay.setCursorBlink(false)
	arrivalsDisplay.setCursorBlink(false)
	
	departuresDisplay.setBackgroundColor(colors.black)
	arrivalsDisplay.setBackgroundColor(colors.black)
	
	-- Write departures display
	departuresDisplay.setCursorPos(1,1)
	departuresDisplay.setTextColor(colors.lightGray)
	departuresDisplay.write("Departures")
	departuresDisplay.setTextColor(colors.orange)
	depWidth, depHeight = departuresDisplay.getSize()
	local line = 2
	
	
  for i = 1, #departures do
    if line > depHeight then 
      break
    end
    departuresDisplay.setCursorPos(1,line)
    departuresDisplay.write(textutils.formatTime(tonumber(departures[i][1]), true ))
    departuresDisplay.setCursorPos(7,line)
    local stations = departures[i][2]
    departuresDisplay.write(mRail.station_name[stations[#stations]])
    
    local serviceID = departures[i][3]
    
    for j = 1, #routePlatformMapping do
      if tostring(serviceID) == tostring(routePlatformMapping[j][1]) then
        departuresDisplay.setCursorPos(16,line)
        if routePlatformMapping[j][2] ~= 0 then
          departuresDisplay.write(routePlatformMapping[j][2])
        else
          departuresDisplay.write("--")
        end
        break
      end
    end
    
    line = line + 1
    if #stations > 1 then
      departuresDisplay.setCursorPos(7,line)
      departuresDisplay.write("via " .. mRail.station_name[stations[1]])
      line = line + 1
    end
  end
	
	
	-- Write arrivals display
	arrivalsDisplay.setCursorPos(1,1)
	arrivalsDisplay.setTextColor(colors.lightGray)
	arrivalsDisplay.write("Arrivals")
	arrivalsDisplay.setTextColor(colors.orange)
	arrWidth, arrHeight = arrivalsDisplay.getSize()
	
	local line = 2
	
	
  for i = 1, #arrivals do
    if line > arrHeight then 
      break
    end
    arrivalsDisplay.setCursorPos(1,line)
    arrivalsDisplay.write(mRail.station_name[arrivals[i][2]])
    arrivalsDisplay.setCursorPos(9,line)
    arrivalsDisplay.write(textutils.formatTime(tonumber(arrivals[i][1]),true))
    
    local serviceID = arrivals[i][3]
    for j = 1, #routePlatformMapping do
      if tostring(serviceID) == tostring(routePlatformMapping[j][1]) then
        arrivalsDisplay.setCursorPos(16,line)
        if routePlatformMapping[j][2] ~= 0 then
          arrivalsDisplay.write(routePlatformMapping[j][2])
        else
          arrivalsDisplay.write("--")
        end
        break
      end
    end
    
    line = line + 1
  end
end

-- TODO - Add this!!
function singleDisplay()

end

-- TODO - Comment
function generateRoutePlatformMapping()
  for i = 1, #mRail.stationRouting do
    local temp = {mRail.stationRouting[i][1],0}
    table.insert(routePlatformMapping,temp)
  end

  routePlatformMapping = mRail.loadData(mappingFile, routePlatformMapping)
end

-- TODO - Comment
function handlePlatformUpdate(serviceID, platform)
  for i = 1, #routePlatformMapping do
    if tostring(routePlatformMapping[i][1]) == tostring(serviceID) then
      routePlatformMapping[i][2] = tostring(platform)
    end
  end
  mRail.saveData(mappingFile, routePlatformMapping)
end

-- TODO - Comment
function handleScreenUpdate(newArrivals, newDepartures)
	arrivals = newArrivals
	departures = newDepartures
end

-- From which all other programs are derived...
local program = {}

-- Program Functions
function program.setup(config_)
  config = config_
  
  modem = peripheral.wrap(config.modemSide)
  arrivalsDisplay = peripheral.wrap(config.arrivalsDisp)
  departuresDisplay = peripheral.wrap(config.departuresDisp)
  
  generateRoutePlatformMapping()
  
  -- Open modems
  modem.open(mRail.channels.screen_update_channel)
  modem.open(mRail.channels.screen_platform_channel)
  
  updateDisplay()
end

function program.onLoop()
	updateDisplay()
end

-- Modem Messages
function program.screen_update_channel(decodedMessage)
  -- Handle messages on the screen update channel
  if decodedMessage.stationID == config.stationID then
    print("Arr/dep update recieved")
    handleScreenUpdate(decodedMessage.arrivals, decodedMessage.departures)
  end
  mRail.saveData(mappingFile, routePlatformMapping)
end

function program.screen_platform_channel(decodedMessage)
  -- Handle messages on the screen platform channel
  if decodedMessage.stationID == config.stationID then
    print("Platform update recieved")
    handlePlatformUpdate(decodedMessage.serviceID, decodedMessage.platform)
  end
  mRail.saveData(mappingFile, routePlatformMapping)
end

function program.handleRedstone()
  
end

return program