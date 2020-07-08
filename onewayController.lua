-- mRail One-Way Controller
-- (C) 2020 Sam Lane

os.loadAPI("mRail.lua")


-- Configuration
local config = {}
-- Default config values:



config.name = "One Way Control 1"
config.modem_side = "bottom"

config_name = ".config"


local filename = "onewayData"
local requestListFile = "requestList"

-- TRUE = OCCUPIED, FALSE = EMPTY
--Each entry represents a block:
--blockID (increasing number!), blockName, {entranceDetectors}, {exitDetectors}, occupiedState, occupyingTrainID, occupyingServiceID
local oneWayState = {
	{1, "01 North Mainline", {13,15}, {14,16},false,0,0},
	{2, "02 North Mainline", {17}, {18},false,0,0}
}


--format blockID, requesterDetectorID, trainID, serviceID
local requestList = {}

-- Functions

local function saveData()
	jsonEncoded = json.json.encode(oneWayState)
		
	local f = fs.open(filename, "w")
	f.write(jsonEncoded)
	
	f.close()
end

local function loadData()
	if fs.exists(filename) then
		print("Loading Data")
		local f = fs.open(filename, "r")
		fileContents = f.readAll()
		print("File contents")
		print(fileContents)
		jsonDecoded = json.json.decode(fileContents)
		print("jsonDecoded")
		print(jsonDecoded)
		oneWayState = jsonDecoded
	else
		print("File not present - saving")
		saveData()
	end
end

local function saveRequestList()
	jsonEncoded = json.json.encode(requestList)
		
	local f = fs.open(requestListFile, "w")
	f.write(jsonEncoded)
	
	f.close()
end

local function loadRequestList()
	if fs.exists(requestListFile) then
		print("Loading Data")
		local f = fs.open(requestListFile, "r")
		fileContents = f.readAll()
		print("File contents")
		print(fileContents)
		jsonDecoded = json.json.decode(fileContents)
		print("jsonDecoded")
		print(jsonDecoded)
		requestList = jsonDecoded
	else
		print("File not present - saving")
		saveRequestList()
	end
end


local function updateDisplay()
	monitor.clear()
	monitor.setCursorPos(1,1)
	for i = 1, #oneWayState do
		if oneWayState[i][5] == false then
			monitor.setBackgroundColor(colors.green)
		elseif oneWayState[i][5] == true then
			monitor.setBackgroundColor(colors.red)
		end
		monitor.setCursorPos(i,i)
		monitor.write(blankString)
		
		monitor.setCursorPos(1,i)
		monitor.write(oneWayState[i][2])
		
		monitor.setCursorPos(25,i)
		monitor.write(oneWayState[i][7])
	end
	for i = #oneWayState + 1, height do
		monitor.setCursorPos(1,i)
		monitor.setBackgroundColor(colors.black)
		monitor.write(blankString)
	end
end

function determineBlockEntr(detectorID)
	local blockID = 0
	for i = 1, #oneWayState do
		for j = 1,#oneWayState[i][3] do
			if oneWayState[i][3][j] == detectorID then
				blockID = i
				return blockID
			end
		end
	end
	return blockID
end

function determineBlockExit(detectorID)
	local blockID = 0
	for i = 1, #oneWayState do
		for j = 1,#oneWayState[i][4] do
			if oneWayState[i][4][j] == detectorID then
				blockID = i
				return blockID
			end
		end
	end
	return blockID
end

function trainWaiting(blockID)
	local result = 0
	for i = 1, #requestList do
		if blockID == requestList[i][1] then
			result = i
			return result
		end
	end
	return result
end

-- Main program




modem = peripheral.wrap("bottom")
monitor = peripheral.wrap("top")
mRail.loadConfig(modem,config_name,config)

width, height = monitor.getSize()
blankString = ""
for i = 1,width do
	blankString = blankString .. " "
end

print("Width " .. width)
print("Height " .. height)


--Open modem to comms channels
modem.open(mRail.channels.oneway_dispatch_request)
modem.open(mRail.channels.detect_channel)

monitor.setCursorBlink(false)

-- run initial display update
loadData()
loadRequestList()
updateDisplay()

while true do
	-- wait for event
	local event, modemSide, senderChannel, replyChannel, message, dist = os.pullEvent("modem_message")
	local decodedMessage = json.json.decode(message)
	
	if senderChannel == mRail.channels.oneway_dispatch_request then
	-- if the event is a request
		print("Dispatch has been requested")
		-- determine which block
		local blockID = determineBlockEntr(decodedMessage.detectorID)
		print("DetectorID " .. decodedMessage.detectorID)
		-- check if the block is free
		print("BlockID " .. blockID)
		if blockID ~= 0 then
			if oneWayState[blockID][5] == false then
			-- if so, then make the block occupied and release the train
				oneWayState[blockID][5] = true
				oneWayState[blockID][6] = decodedMessage.trainID
				oneWayState[blockID][7] = decodedMessage.serviceID
				mRail.oneway_confirm_dispatch(modem, decodedMessage.detectorID, decodedMessage.serviceID, decodedMessage.trainID)
				local textMessage = "In block " .. oneWayState[blockID][2]
				mRail.detection_broadcast(modem, decodedMessage.detectorID, decodedMessage.serviceID, decodedMessage.trainID, textMessage)
				saveData()
			elseif oneWayState[blockID][5] == true then
			-- if not, add the request to the request list
				local request = {blockID, decodedMessage.detectorID, decodedMessage.trainID, decodedMessage.serviceID}
				table.insert(requestList,request)
				saveRequestList()
			end
		end	
	elseif senderChannel == mRail.channels.detect_channel then
	-- if the event is a detection (frequency dependant)
		-- check if there is a block to free up
		local blockID = determineBlockExit(decodedMessage.detectorID)
		print("BlockID " .. blockID)
		if blockID ~= 0 then
			if oneWayState[blockID][5] == true then
				-- free the block
				oneWayState[blockID][5] = false
				oneWayState[blockID][6] = 0
				oneWayState[blockID][7] = ""
				
				local trainWaitingRequestID = trainWaiting(blockID)
				
				-- check if there is a train waiting to enter the block
				if trainWaitingRequestID ~= 0 then
					oneWayState[blockID][5] = true
					oneWayState[blockID][6] = requestList[trainWaitingRequestID][3]
					oneWayState[blockID][7] = requestList[trainWaitingRequestID][4]
					local textMessage = "In block " .. oneWayState[blockID][2]
					mRail.detection_broadcast(modem, requestList[trainWaitingRequestID][2], requestList[trainWaitingRequestID][4], requestList[trainWaitingRequestID][3], textMessage)
					-- permit entry
					mRail.oneway_confirm_dispatch(modem, requestList[trainWaitingRequestID][2], requestList[trainWaitingRequestID][4], requestList[trainWaitingRequestID][3])
					-- remove from list
					table.remove(requestList,trainWaitingRequestID)
				end
				saveData()
				saveRequestList()
			end
		end
	end
	saveData()
	saveRequestList()
	monitor.clear()
	monitor.setCursorPos(1,1)
	updateDisplay()
end

