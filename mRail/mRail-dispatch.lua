-- mRail Dispatch
-- (C) 2020-21 Sam Lane

-- TODO - Comment all
-- TODO - Add logging
-- TODO - Add support for variable sized displays

-- Load APIs
mRail = require("./mRail/mRail-api")
json = require("./mRail/json")
log = require("./mRail/log")

local config = {}

local tempConfig = {}
mRail.loadConfig("./mRail/network-configs/.timetable-config",tempConfig)
routes = tempConfig.routes
timetabledServices = tempConfig.timetabledServices

--alarmID, recieverID, serviceID, trainID
depotAlarmIDs = {}
statAlarmIDs = {}

local modem
local monitor


function set_days_depot_alarms()
	-- clear any previous alarms remaining
	depotAlarmIDs = {}
	-- loop through each timetabled service
  for i = 1, #timetabledServices do
    local serviceRoute = timetabledServices[i][1]
    local serviceDepot = routes[serviceRoute][2]
    local depotTime = timetabledServices[i][3]
    local serviceTrain = timetabledServices[i][2]
    local alarmID = os.setAlarm(depotTime)
    table.insert(depotAlarmIDs,{alarmID, serviceDepot, routes[serviceRoute][1], serviceTrain,depotTime})
  end
end

function set_days_station_alarms()
	statAlarmIDs = {}
	
  for i = 1, #timetabledServices do
    local serviceID = timetabledServices[i][1]
    local trainID = timetabledServices[i][2]
    local startTime = timetabledServices[i][3]
    
    if #routes[serviceID][3] ~= 0 then
      for j = 1, #routes[serviceID][3] do
        --print("j " .. j)
        local stationID = routes[serviceID][3][j][1]
        --print("Station ID " .. stationID)
        local offsetTime = routes[serviceID][3][j][2]
        --print("Offset time " .. offsetTime)
        local totalTime = startTime + offsetTime
        totalTime = totalTime % 24.0
        --print("Total time " .. totalTime)
        local alarmID = os.setAlarm(totalTime)
        table.insert(statAlarmIDs,{alarmID,stationID,routes[serviceID][1],trainID,totalTime})
      end
    end
  end
end

function updateDisplays()
	--take alarms and generate info for each display
	--messageForDisplays = {{stationID,{arrivals,departures}}}
	--[station][1=arrivals, 2=departure][each departure/arrival][1=Arrival/Departure time, 2=list of stations]
	
	local station_name = mRail.station_name
	
	for i = 1, #station_name do
	    --print("")
	    --print("")
	    --print("Creating message for " .. station_name[i])
		
		local arrivals = {}
		local departures = {}
		
		--loop through each service
    for j = 1, #timetabledServices do
      --check if the station is on the service
      local routeData = routes[timetabledServices[j][1]][3]
      local indexID = 0
      local numberOfStops = #routeData
      if numberOfStops ~= 0 then
        for k = 1, numberOfStops do
          if routeData[k][1] == i then
            indexID = k
            break
          end
        end
      end
      
      
      if indexID ~= 0 then
          --print(station_name[i] .. " station is on service " .. j .. " in pos " .. indexID)
        -- make departures listing
        if indexID ~= numberOfStops then
          --then this is not the last station so there will be a departure
          local tempDep = {}
          --assign time of departure
          tempDep[1] = (routeData[indexID][2] + timetabledServices[j][3]) % 24
          --print("     there is a departure at time " .. tempDep[1])
          local otherStations = {}
          --print("     other stations are:")
          for k = indexID + 1, numberOfStops do
            --  print("         " .. station_name[routeData[k][1]])
            otherStations[k - indexID] = routeData[k][1]
          end
          tempDep[2] = otherStations
          tempDep[3] = tostring(routes[timetabledServices[j][1]][1])
          if (tonumber(tempDep[1]) > os.time() % 24) then
            table.insert(departures,tempDep)
          end
        end
      
        -- make arrivals listing
        if indexID ~= 1 then
            local tempArr = {}
            tempArr[1] = (routeData[indexID][2] + timetabledServices[j][3] - 0.5) % 24
            
            tempArr[2] = routeData[1][1]
          tempArr[3] = tostring(routes[timetabledServices[j][1]][1])
            --print("     service from " .. station_name[tempArr[2]] .. " arriving at " .. tempArr[1])
          if (tonumber(tempArr[1]) > os.time() % 24) then
            table.insert(arrivals,tempArr)
          end
        end
        --print("")
      end
    end
		
		table.sort(arrivals, function(a,b) return a[1] < b[1] end)
		table.sort(departures, function(a,b) return a[1] < b[1] end)
		--print("Updating displays")
		mRail.screen_update(modem, i, arrivals, departures)
	end
end




function dispatch_from_depot(depotID, serviceID, trainID)
	mRail.dispatch_train(modem, depotID, serviceID, trainID)
end

function dispatch_from_station(stationID, serviceID, trainID)
	mRail.station_dispatch_train(modem, stationID, serviceID, trainID)
end

function printColourAndRoute(serviceID, trainID)
  if trainID ~= 0 then
    monitor.setBackgroundColor(math.pow(2,tonumber(trainID) - 1))
  end
  monitor.write("  ")
  monitor.setBackgroundColor(32768)
  monitor.write(" ")
  if serviceID == nil or serviceID == "" then
    serviceID = "No Route"
  end
  monitor.write(tostring(serviceID))
  for i = string.len(serviceID), 8 do
    monitor.write(" ")
  end
  monitor.write(" ")
end

function updateDisplay()
  monitor.clear()
  
  local sortedDepotAlarmIDs = depotAlarmIDs
  local sortedStatAlarmIDs = statAlarmIDs
  
  -- Sort alarms by their time rather than ID
  -- Allows for them to be displated to the user in a meaningful manner
  table.sort(sortedDepotAlarmIDs, function(a,b) return a[5] < b[5] end)
  table.sort(sortedStatAlarmIDs, function(a,b) return a[5] < b[5] end)
  
  local xCol2 = 26
  	
  local w, h = monitor.getSize()
  
	monitor.setCursorPos(1,1)
  monitor.write("Depot releases:")
  
  if #sortedDepotAlarmIDs ~= 0 then
		for i = 1, math.min(#sortedDepotAlarmIDs,h - 1) do
      monitor.setCursorPos(1, i + 1)
      printColourAndRoute(sortedDepotAlarmIDs[i][3], sortedDepotAlarmIDs[i][4])
      monitor.write(mRail.location_name[sortedDepotAlarmIDs[i][2]])
		end
	end
  -- TODO - These should be in a single function
  monitor.setCursorPos(xCol2,1)
  monitor.write("Station releases:")
  if #sortedStatAlarmIDs ~= 0 then
		for i = 1, math.min(#sortedStatAlarmIDs,h - 1) do
      monitor.setCursorPos(xCol2, i + 1)
      printColourAndRoute(sortedStatAlarmIDs[i][3], sortedStatAlarmIDs[i][4])
      monitor.write(mRail.station_name[sortedStatAlarmIDs[i][2]])
		end
	end
  
end


-- From which all other programs are derived...
local program = {}

-- Program Functions
function program.setup(config_)
  config = config_
  
  modem = peripheral.wrap(config.modemSide)
  modem.open(mRail.channels.request_dispatch_channel)
  modem.open(mRail.channels.next_station_request)
  modem.open(mRail.channels.ping_request_channel)
  
  if config.monitor == nil or config.monitor == "term" then
    monitor = term
  else
    monitor = peripheral.wrap(config.monitor)
  end

  set_days_depot_alarms()
  set_days_station_alarms()

  monitor.clear()
  updateDisplays()
  updateDisplay()
end

function program.onLoop()
	updateDisplays()
  updateDisplay()
end

-- Modem Messages
function program.next_station_request(decodedMessage)
  -- Handle messages on the next station request channel
  local nextStationID = 0
  local routeNum = 0
  for i = 1, #routes do
    if tostring(decodedMessage.serviceID) == tostring(routes[i][1]) then
      routeNum = i
      break
    end
  end
  
  if routeNum == 0 then return end
  
  local trainRoute = routes[routeNum][3]
  
  for i = 1, #trainRoute do
    local stationID = trainRoute[i][1]
    
    if tonumber(stationID) == tonumber(decodedMessage.stationID) then
      if i == #trainRoute then
        nextStationID = trainRoute[1][1]
      else
        nextStationID = trainRoute[i + 1][1]
      end
      break
    end
  end
  
  if nextStationID == 0 then return end
  
  mRail.next_station_update(modem, nextStationID, decodedMessage.trainID)
end

function program.request_dispatch_channel(decodedMessage)
  -- Handle messages on the request dispatch channel
  -- dispatch the train
  mRail.dispatch_train(modem, decodedMessage.recieverID, decodedMessage.serviceID, decodedMessage.trainID)
  -- add the train to list of non-timetabledServices
  local serviceID = decodedMessage.serviceID
  local serviceID_number = 0
  for i = 1, #routes do
    if routes[i][1] == serviceID then
      serviceID_number = i
    end
  end
  if serviceID_number > 0 then
    table.insert(timetabledServices, {serviceID_number, decodedMessage.trainID, os.time()})
  end
end



-- Alarms
function program.handleAlarm(alarmID)
  for i = 1, #depotAlarmIDs do
    if depotAlarmIDs[i][1] == alarmID then
      dispatch_from_depot(depotAlarmIDs[i][2],depotAlarmIDs[i][3],depotAlarmIDs[i][4])
      table.remove(depotAlarmIDs,i)
      break
    end
  end

  for i = 1, #statAlarmIDs do
    if statAlarmIDs[i][1] == alarmID then
      dispatch_from_station(statAlarmIDs[i][2],statAlarmIDs[i][3],statAlarmIDs[i][4])
      table.remove(statAlarmIDs,i)
      break
    end
  end
end

function program.handleRedstone()
  if redstone.getInput(config.redstoneSide) == true then
    os.reboot()
  end
end

return program