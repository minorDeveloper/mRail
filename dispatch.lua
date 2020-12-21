-- mRail Dispatch
-- (C) 2020 Sam Lane

os.loadAPI("mRail.lua")


-- Configuration
local config = {}
-- Default config values:
config_name = ".config"


-- routename, depotID, {stationID, departure time (offset from 0)}
routes = {
	{"HR Expr", 2, {{1,1.0},{4,10.0}}},
	{"HB Stop", 3, {{1,1.0},{3,3.25}}},
	{"HS Expr", 2, {{1,1.0},{2,6.5}}},
	{"SH Expr", 45,{{2,1.0},{1,6.5}}},
	{"SB Stop", 45,{{2,1.0},{1,6.75},{3,9.5}}},
	{"BH Stop", 72,{{3,1.0},{1,3.25}}},
	{"BS Stop", 72,{{3,1.0},{1,3.5},{2,8.45}}},
	{"BR Stop", 72,{{3,1.0},{1,3.5},{4,12.60}}},
	
	{"RH Expr", 80,{{4,1.0},{1,10.0}}},
	{"RB Stop", 79,{{4,1.0},{1,10.0},{3,12.5}}},
	{"RB Expr", 80,{{4,1.0},{3,12.20}}},
	{"AmongUs", 79,{{4,1.0},{5,3.0}}},
	{"R Branch",999,{{5,0.0},{4,2.0}}},
}

-- route ID, assigned train, start time
timetabledServices = {
	{8,1,6.5},
	{1,2,7.5},
	{2,3,7.5},
	{2,3,14.5},
	{3,4,9.0},
	{5,5,6.5},
	{11,6,6.5},
	{9,7,9.0},
	{6,8,7.5},
	{6,8,14.5},
	{7,9,8.5},
	{4,10,10.0},
	
	{12,15,6.75},
	{12,15,13.25},
	{12,14,9.25},
--	{12,14,16.25},
	
	
	{13,15,10.1},
	{13,15,16.25},
	{13,14,12.73},
	{13,14,19.25},
--	{10,11,12.0},
--	
--	{9,13,19.0},
--	{1,14,20.75},
--	{7,15,19.0},
--	{5,12,20.0}
}


--alarmID, recieverID, serviceID, trainID
depotAlarmIDs = {}
statAlarmIDs = {}



function set_days_depot_alarms()
	-- clear any previous alarms remaining
	depotAlarmIDs = {}
	-- loop through each timetabled service
	if #timetabledServices ~= 0 then
		for i = 1, #timetabledServices do
			local serviceRoute = timetabledServices[i][1]
			local serviceDepot = routes[serviceRoute][2]
			local depotTime = timetabledServices[i][3]
			local serviceTrain = timetabledServices[i][2]
			local alarmID = os.setAlarm(depotTime)
			table.insert(depotAlarmIDs,{alarmID, serviceDepot, routes[serviceRoute][1], serviceTrain,depotTime})
		end
	end
end

function set_days_station_alarms()
	statAlarmIDs = {}
	
	if timetabledServices ~= 0 then
		for i = 1, #timetabledServices do
			local serviceID = timetabledServices[i][1]
			local trainID = timetabledServices[i][2]
			local startTime = timetabledServices[i][3]
			--print("Service ID " .. serviceID)
			--print("TrainID  " .. trainID)
			--print("Start Time " .. startTime)
			--print("i " .. i)
			
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
end


function processAlarm(alarmID)
	if #depotAlarmIDs ~= 0 then
		for i = 1, #depotAlarmIDs do
			if depotAlarmIDs[i][1] == alarmID then
				dispatch_from_depot(depotAlarmIDs[i][2],depotAlarmIDs[i][3],depotAlarmIDs[i][4])
				table.remove(depotAlarmIDs,i)
				break
			end
		end
	end
	
	if #statAlarmIDs ~= 0 then
		for i = 1, #statAlarmIDs do
			if statAlarmIDs[i][1] == alarmID then
				dispatch_from_station(statAlarmIDs[i][2],statAlarmIDs[i][3],statAlarmIDs[i][4])
				table.remove(statAlarmIDs,i)
				break
			end
		end
	end
	updateDisplays()
end


-- routename, depotID, {stationID, departure time (offset from 0)}
--routes

-- route ID, assigned train, start time
--timetabledServices

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
		if #timetabledServices ~= 0 then
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
    term.setBackgroundColor(math.pow(2,tonumber(trainID) - 1))
  end
  term.write("  ")
  term.setBackgroundColor(32768)
  term.write(" ")
  if serviceID == nil or serviceID == "" then
    serviceID = "No Route"
  end
  term.write(tostring(serviceID))
  for i = string.len(serviceID), 8 do
    term.write(" ")
  end
  term.write(" ")
end

function updateDisplay()
  term.clear()
  
  local xCol2 = 26
  	
  local w, h = term.getSize()
  
	term.setCursorPos(1,1)
  term.write("Depot releases:")
  
  if #depotAlarmIDs ~= 0 then
		for i = 1, math.min(#depotAlarmIDs,h - 1) do
      term.setCursorPos(1, i + 1)
      printColourAndRoute(depotAlarmIDs[i][3], depotAlarmIDs[i][4])
      term.write(mRail.location_name[depotAlarmIDs[i][2]])
      --table.insert(depotAlarmIDs,{alarmID, serviceDepot, routes[serviceRoute][1], serviceTrain,depotTime})
      --    serviceID                       trainID                          depotID                      alarmID
			--print(depotAlarmIDs[i][3] .. "   " .. depotAlarmIDs[i][4] .. "   " .. depotAlarmIDs[i][2] .. "   " .. depotAlarmIDs[i][1])
		end
	end
  
  term.setCursorPos(xCol2,1)
  term.write("Station releases:")
  if #statAlarmIDs ~= 0 then
		for i = 1, math.min(#statAlarmIDs,h - 1) do
      term.setCursorPos(xCol2, i + 1)
      printColourAndRoute(statAlarmIDs[i][3], statAlarmIDs[i][4])
      term.write(mRail.station_name[statAlarmIDs[i][2]])
      --table.insert(statAlarmIDs,{alarmID,stationID,routes[serviceID][1],trainID,totalTime})
      --    serviceID                       trainID                          stationID                      alarmID
			--print(statAlarmIDs[i][3] .. "   " .. statAlarmIDs[i][4] .. "   " .. statAlarmIDs[i][2] .. "   " .. statAlarmIDs[i][1])
		end
	end
  
end

modem = peripheral.wrap("back")
modem.open(mRail.channels.request_dispatch_channel)
mRail.loadConfig(modem,config_name,config)

set_days_depot_alarms()
set_days_station_alarms()

updateDisplays()
while true do
	updateDisplay()
	
	ev, p1, p2, p3, p4, p5, p6 = os.pullEvent()
	if ev == "alarm" then
		processAlarm(p1)
	elseif ev == "redstone" then
		if redstone.getInput("bottom") == true then
			os.reboot()
		end
	elseif ev == "modem_message" then
		-- Check if it was a request for dispatch_from_depot
		if tonumber(p2) == mRail.channels.request_dispatch_channel then
			-- dispatch the train
			local decodedMessage = json.json.decode(p4)
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
		
	end
	updateDisplays()
end
