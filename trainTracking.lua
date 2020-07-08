-- mRail Train Tracker and Display
-- (C) 2020 Sam Lane

os.loadAPI("mRail.lua")

local numberTrains = 16

local config = {}
config_name = ".config"

local filename = "trainData"

local struct = {
	trainID = 1,
	serviceID = 2,
	currentLocationID = 3,
	nextStationID = 4,
	msg = 5
}

local xPos = {
	trainID = 4,
	serviceID = 8,
	currentLocationID = 22,
	nextStationID = 35,
	msg = 50
}


local trainData = {
	{1,0,0,0,""},
	{2,0,0,0,""},
	{3,0,0,0,""},
	{4,0,0,0,""},
	{5,0,0,0,""},
	{6,0,0,0,""},
	{7,0,0,0,""},
	{8,0,0,0,""},
	{9,0,0,0,""},
	{10,0,0,0,""},
	{11,0,0,0,""},
	{12,0,0,0,""},
	{13,0,0,0,""},
	{14,0,0,0,""},
	{15,0,0,0,""},
	{16,0,0,0,""},
}


local function saveData()
	jsonEncoded = json.json.encode(trainData)
		
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
		trainData = jsonDecoded
	else
		print("File not present - saving")
		saveData()
	end
end

local function updateDisplay()
	term.clear()
	
	term.setCursorPos(1, 1)
	term.write("Train:")
	
	term.setCursorPos(xPos.serviceID, 1)
	term.write("Service:")
	
	term.setCursorPos(xPos.currentLocationID, 1)
	term.write("Current:")
	
	term.setCursorPos(xPos.nextStationID, 1)
	term.write("Next Station:")
	
	term.setCursorPos(xPos.msg, 1)
	
	
	for i = 1, numberTrains do
		term.setCursorPos(1,i+1)
		term.setBackgroundColor(math.pow(2,i - 1))
		term.write("  ")
		term.setBackgroundColor(32768)
		
		term.setCursorPos(xPos.trainID, i+1)
		local messageString = ""
		idTrain = trainData[i][struct.trainID]
		
		if idTrain < 10 then
			messageString = "0" .. tostring(idTrain)
		else
			messageString = tostring(idTrain)
		end
		term.write(messageString)
		
		term.setCursorPos(xPos.serviceID, i+1)
		term.write(tostring(trainData[i][struct.serviceID]))
		
		term.setCursorPos(xPos.currentLocationID, i+1)
		term.write(tostring(mRail.location_name[trainData[i][struct.currentLocationID]]))
		
		term.setCursorPos(xPos.nextStationID, i+1)
		term.write(tostring(mRail.station_name[trainData[i][struct.nextStationID]]))
		
		term.setCursorPos(xPos.msg, i+1)
		term.write(tostring(trainData[i][struct.msg]))
	end
	
	term.setCursorBlink(false)
	term.setCursorPos(1,1)
end


-- Main program

modem = peripheral.wrap("bottom")
mRail.loadConfig(modem,config_name,config)

display = peripheral.wrap("top")

--Open modem to comms channels
modem.open(mRail.channels.detect_channel)
modem.open(mRail.channels.location_update_channel)

term.setCursorBlink(false)

-- run initial display update
loadData()
updateDisplay()

while true do
	-- wait for update
	local event, modemSide, senderChannel, replyChannel, message, dist = os.pullEvent("modem_message")
	local decodedMessage = json.json.decode(message)
	
	local msgDetectorID = tonumber(decodedMessage.detectorID)
	local msgTrainID = tonumber(decodedMessage.trainID)
	local msgServiceID = tostring(decodedMessage.serviceID)
	local msgMsg = tostring(decodedMessage.textMessage)
	
	trainData[msgTrainID][2] = msgServiceID
	trainData[msgTrainID][3] = msgDetectorID
	trainData[msgTrainID][5] = msgMsg
	
	
	-- save to file:close
	saveData()
	-- update screen
	updateDisplay()
end