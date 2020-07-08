-- mRail Station Controller
-- (C) 2020 Sam Lane

os.loadAPI("mRail.lua")


-- Configuration
local config = {}
-- Default config values:
config.stationID = 1
config_name = ".config"






local filename = "stationData"
local requestListFile = "requestList"


-- state loaded, serviceID, trainID
local currentLoadedStates = {}
local requestList = {}

--sig req, sig state, swit req, swit state
local currentState = {0,0,0,0}

--				
-- need to state wether the request is an entry or a dispatch
-- 

-- first bit is for entries, second for dispatch
-- serviceName, {what each station should do with it}
whatToDo = {
	-- basic routes
	--Name   	Hub								SJ		Barron		Ryan
	{"", 		{{{13,3},{13,3}},						{},		{},			{}}},
	{"Hub",		{{{7,11,6,10,5,9,4,8},{13,3}},			{},		{},			{}}},
	{"SJ", 		{{{2},{2}},								{},		{},			{}}},
	{"Barron", 	{{{12},{12}},							{},		{},			{}}},
	{"Ryan", 	{{{1},{1}},								{},		{},			{}}},
	-- complex routes
	{"BR Expr", {{{1},{1}},								{},		{2,3},		{}}},
	{"BH Stop", {{{6,7,4,5},{3}},						{},		{2,3},		{}}},
	{"BR Stop", {{{6,7,4,5},{1}},						{},		{2,3},		{}}},
	{"BS Stop", {{{6,7,4,5},{2}},						{},		{2,3},		{}}},
	
	{"HB Stop", {{{11,10,9,8},{12}},					{},		{4,5},		{}}}
}

--whatToDo[ROUTE NAME][2][STATION][1 = entry, 2 = dispatch][LIST OF ROUTES]

local entryPlatformStateMapping = {
	{4,7},	--Platform 1 West
	{5,8},	--Platform 2 West
	{6,9},	--Platform 3 West
	{7,10},	--Platform 4 West
	{8,3},	--Platform 1 East
	{9,4},	--Platform 2 East
	{10,5},	--Platform 3 East
	{11,6}	--Platform 4 East
}


local detectorEntranceIDMapping = {
	9, -- 01
	10,-- 02
	-1, -- 03
	-1, -- 04
	-1, -- 05
	-1, -- 06
	-1, -- 07
	-1, -- 08
	-1, -- 09
	-1, -- 10
	-1, -- 11
	12,-- 12
	-1, -- 13
	}
	
local detectorDepotIDMapping = {
	-1, -- 01
	-1,-- 02
	3, -- 03
	-1, -- 04
	-1, -- 05
	-1, -- 06
	-1, -- 07
	-1, -- 08
	-1, -- 09
	-1, -- 10
	-1, -- 11
	-1,-- 12
	2, -- 13
	}
	
local detectorExitIDMapping = {
	8,-- 01
	10,-- 02
	0,-- 03
	4,-- 04
	5,-- 05
	6,-- 06
	7,-- 07
	4,-- 08
	5,-- 09
	6,-- 10
	7,-- 11
	11,-- 12
	0,-- 13
	}

local systemRoutingData = {}



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

function loadStateTable()
	local lineData = {}
	local file = io.open("StateTable.csv","r")
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

function loadCurrentRouting()

end

function loadCurrentPlatform()

end

function loadRequestList()

end


function setOutputState(signalsRelease,switches)
	redstone.setBundledOutput("back",signalsRelease)
	redstone.setBundledOutput("left",signalsRelease)
	redstone.setBundledOutput("right",switches)
end

function findRoutes(entranceID, exitID)
	local possibleRoutes = {}
	for i = 2, #systemRoutingData do
		if tonumber(systemRoutingData[i][3]) == entranceID and tonumber(systemRoutingData[i][4]) == exitID then
			table.insert(possibleRoutes,i-1)
		end
	end
	return possibleRoutes
end

function checkValidCombo(stateA, stateB)
	local signalStateA 		= tonumber(systemRoutingData[stateA+1][6])
	local signalRequiredA 	= tonumber(systemRoutingData[stateA+1][5])
	local switchStateA 		= tonumber(systemRoutingData[stateA+1][8])
	local switchRequiredA 	= tonumber(systemRoutingData[stateA+1][7])
	
	local signalStateB 		= tonumber(systemRoutingData[stateB+1][6])
	local signalRequiredB 	= tonumber(systemRoutingData[stateB+1][5])
	local switchStateB 		= tonumber(systemRoutingData[stateB+1][8])
	local switchRequiredB 	= tonumber(systemRoutingData[stateB+1][7])
	
	local validSwitching = bit.band(bit.band(switchRequiredA,switchRequiredB),bit.bxor(switchStateA,switchStateB))
	local validSignalling =bit.band(bit.band(signalRequiredA,signalRequiredB),bit.bxor(signalStateA,signalStateB))
	
	
	if validSignalling == 0 and validSwitching == 0 then
		return true
	end
	return false
end

function checkNewCombo(stateA)
	local signalStateA 		= tonumber(systemRoutingData[stateA+1][6])
	local signalRequiredA 	= tonumber(systemRoutingData[stateA+1][5])
	local switchStateA 		= tonumber(systemRoutingData[stateA+1][8])
	local switchRequiredA 	= tonumber(systemRoutingData[stateA+1][7])
	
	local signalStateB 		= currentState[2]
	local signalRequiredB 	= currentState[1]
	local switchStateB 		= currentState[4]
	local switchRequiredB 	= currentState[3]
	
	print(currentState[1] .. " " .. currentState[2] .. " " .. currentState[3] .. " " .. currentState[4])
	print(stateA)
	
	local validSwitching = bit.band(bit.band(switchRequiredA,switchRequiredB),bit.bxor(switchStateA,switchStateB))
	local validSignalling =bit.band(bit.band(signalRequiredA,signalRequiredB),bit.bxor(signalStateA,signalStateB))
	
	
	if validSignalling == 0 and validSwitching == 0 then
		return true
	end
	return false
end

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

function tryRemove(stateID)
	if #currentLoadedStates ~= 0 then
		for i = 1, #currentLoadedStates do
			if tonumber(currentLoadedStates[i][1]) == stateID then
				table.remove(currentLoadedStates,i)
				print("Removed the state")
				return true
			end
		end
	end
	return false
end

function tryAdd(stateID, serviceID, trainID)
	stateID = tonumber(stateID)
	-- remove any platform occupations associated with the route
	local platformOccupation = 0
	if tonumber(systemRoutingData[stateID+1][9]) ~= 0 then
		platformOccupation = tonumber(systemRoutingData[stateID+1][9])
		tryRemove(platformOccupation)
	end
	-- check if it's compatible
	updateState()
	if checkNewCombo(stateID) == true and stateID > 0 then
		local unique = true
		if #currentLoadedStates ~= 0 then
			for i = 1, #currentLoadedStates do
				if tonumber(currentLoadedStates[i][1]) == tonumber(stateID) then
					unique = false
					break
				end
			end
		end
		
		if unique then 
			table.insert(currentLoadedStates,{stateID, serviceID, trainID})
			print("State added")
			return true
		else
			return false
		end
	-- if so then just insert the new state
	else
		print("Requested state incompatible")
		if platformOccupation ~= 0 then
			tryAdd(platformOccupation, serviceID, trainID)
		end
		return false
	-- if not then re-add the platform occupation state
	end
	updateState()
end

function tryRoute(entranceID, exitID, serviceID, trainID)
	local possibleRoutes = findRoutes(entranceID, exitID)
	print("Routes found")
	print(tostring(possibleRoutes))
	
	if #possibleRoutes ~= 0 then
		for i = 1, #possibleRoutes do
			if tryAdd(possibleRoutes[i], serviceID, trainID) == true then
				return true
			end
		end
	end
	return false
end

function logRequest(entryID, serviceID, trainID, detectorID,entryOrDispatch)
	local unique = true
	if #requestList ~= 0 then
		for i = 1, #requestList do
			if entryID == requestList[i][1] and trainID == requestList[i][3] then
				unique = false
			end
		end
	end
	if unique then
		table.insert(requestList,{entryID, serviceID, trainID,detectorID,entryOrDispatch})
	end
end


function processRequests()
	if #requestList ~= 0 then
		for i = 1, #requestList do
			
			print(requestList[i][2])
			
			if #whatToDo ~= 0 then
				for j = 1, #whatToDo do
					print(whatToDo[j][1])
					if tostring(requestList[i][2]) == whatToDo[j][1] then
						local routesToTry = whatToDo[j][2][tonumber(config.stationID)][tonumber(requestList[i][5])]
						if #routesToTry ~= 0 then
							for k = 1, #routesToTry do
								print("Trying route from " .. requestList[i][1] .. " to " .. routesToTry[k])
								if tryRoute(requestList[i][1], routesToTry[k], requestList[i][2], requestList[i][3]) == true then
									if tonumber(requestList[i][4]) ~= 0 then
										mRail.station_confirm_dispatch(modem, requestList[i][4], requestList[i][2], requestList[i][3])
									end
									table.remove(requestList,i)
									break
								end
							end
						end
						break
					end
				end
			end
		end
	end
end

-- Initialise

modem = peripheral.wrap("top")
mRail.loadConfig(modem,config_name,config)

-- Load all files
loadStateTable()
loadCurrentRouting()
loadCurrentPlatform()
loadRequestList()



-- Main Loop
print("set initial state")
updateState()


--TODO



modem.open(mRail.channels.timetable_updates)




--DONE
modem.open(mRail.channels.detect_channel)
modem.open(mRail.channels.station_route_request)
modem.open(mRail.channels.station_dispatch_request)
modem.open(mRail.channels.station_dispatch_channel)


while true do
	term.clear()
	term.setCursorPos(1,1)
	print("Current loaded states:")
	if #currentLoadedStates ~= 0 then
		for i = 1, #currentLoadedStates do
			print(tostring(systemRoutingData[currentLoadedStates[i][1]+1][2]))
		end
	end
	print("")
	print("")
	
	print("Current requests:")
	if #requestList ~= 0 then
		for i = 1, #requestList do
			print(tostring(requestList[i][1]) .. "  " .. tostring(requestList[i][3]) .. "  " .. tostring(requestList[i][2]))
		end
	end
	print("")
	print("")
	
	print("Waiting for event")
	
	event, param1, param2, param3, param4, param5, param6 = os.pullEvent()
	if event == "modem_message" then
		print("Recived a modem message")
		local channel = tonumber(param2)
		local encodedMessage = param4
		local decodedMessage = json.json.decode(encodedMessage)
		if channel == mRail.channels.station_route_request then
			
			print("Route requested")
			--station_request_route(modem, stationID, entryID, exitID, serviceID, trainID)
			if tonumber(decodedMessage.stationID) == tonumber(config.stationID) then
				if tryRoute(tonumber(decodedMessage.entryID), tonumber(decodedMessage.exitID),decodedMessage.serviceID, decodedMessage.trainID) == false then
				end
			end
		elseif channel == mRail.channels.detect_channel then
			--detection_broadcast(modem, detectorID, serviceID, trainID, textMessage)
			
			print("Detection found")
			print(decodedMessage.detectorID)
			-- check if it's an exit
			if #currentLoadedStates ~= 0 then
				for i = 1, #currentLoadedStates do
					local dectectorNumber = tonumber(systemRoutingData[currentLoadedStates[i][1]+1][4])
					local exitDetectorID = detectorExitIDMapping[dectectorNumber]
					if tonumber(decodedMessage.detectorID) == exitDetectorID then
						print("Removing state")
						local stateBeingRemoved = currentLoadedStates[i][1]
						local stateToAdd = 0
						if systemRoutingData[stateBeingRemoved+1][10] ~= 0 then
							stateToAdd = tonumber(systemRoutingData[stateBeingRemoved+1][10])
						end
						print("State to add: " .. stateToAdd)
						tryRemove(stateBeingRemoved)
						if stateToAdd ~= 0 then
							tryAdd(stateToAdd, decodedMessage.serviceID, decodedMessage.trainID)
						end
						processRequests()
						break
					end
				end
			end
			
			-- check if it's an entry
			if #detectorEntranceIDMapping ~= 0 then
				for i = 1, #detectorEntranceIDMapping do
					if detectorEntranceIDMapping[i] == tonumber(decodedMessage.detectorID) then
						local entryID = i
						print("Entry ID: " .. entryID)
						logRequest(entryID, decodedMessage.serviceID, decodedMessage.trainID,0,1)
						processRequests()
						break
					end
				end
			end
			
		elseif channel == mRail.channels.station_dispatch_request then
			print("Dispatch from depot requested")
			if #detectorDepotIDMapping ~= 0 then
				for i = 1, #detectorDepotIDMapping do
					if detectorDepotIDMapping[i] == tonumber(decodedMessage.detectorID) then
						local entryID = i
						print("Entry ID: " .. entryID)
						logRequest(entryID, decodedMessage.serviceID, decodedMessage.trainID, decodedMessage.detectorID,1)
						processRequests()
						break
					end
				end
			end
		elseif channel == mRail.channels.station_dispatch_channel then
			print("Dispatch from Station requested")
			--dispatch_train(modem, stationID, serviceID, trainID)
			if tonumber(decodedMessage.stationID) == config.stationID then
				-- find where the train is
				local entryID = 0
				
				-- loop through all the states
				if #currentLoadedStates ~= 0 then
					for i = 1, #currentLoadedStates do
						-- state, service, train
						-- check if the service ID matches
						if tostring(currentLoadedStates[i][2]) == tostring(decodedMessage.serviceID) then
							if #entryPlatformStateMapping ~= 0 then
								for j = 1, #entryPlatformStateMapping do
									if tonumber(currentLoadedStates[i][1]) == tonumber(entryPlatformStateMapping[j][2]) then
										entryID = tonumber(entryPlatformStateMapping[j][1])
									end
								end
							end
							-- if so then check that the state corresponds to a platform
						end
					end
				end
				-- request a dispatch
				if entryID ~= 0 then
					logRequest(entryID, decodedMessage.serviceID, decodedMessage.trainID, 0, 2)
					processRequests()
				end
			end
		end
	end
	updateState()
end


