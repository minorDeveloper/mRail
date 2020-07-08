-- mRail Release Depot
-- (C) 2020 Sam Lane

os.loadAPI("mRail.lua")


-- Configuration
local config = {}
-- Default config values:
config.id = 1
config.name = "Release"
config.modem_side = "top"
config.track_name = "routing_track_2"
config.parent_station = 1

config_name = ".config"

-- Functions 

function pushFirstItem(lowerSlot, upperSlot, destinationSlot)
	local success = 0
	local i = upperSlot
	while success == 0 do
		success = cart_chest.pushItems("bottom",i,1,destinationSlot)
		print("Slot " .. tostring(i) .. " " .. success)
		i = i - 1
		if i == lowerSlot then
			success = true
		end
	end
end

function toDispenser(trainID)
	if loco_chest.pushItems("bottom",trainID,1,1) == 1 then
		pushFirstItem(1,18,2)
		pushFirstItem(1,18,2)
		pushFirstItem(19,27,3)
		return true
	else
		mRail.raise_error(modem,"Train not in depot", 3)
		return false
	end
end


function dispatchTrain(trainID, serviceID)
	if toDispenser(trainID) == true then
		track.setDestination(serviceID)
		-- release train
		redstone.setOutput("bottom",true)
		sleep(0.1)
		redstone.setOutput("bottom",false)
		return true
	else
		return false
	end
end



-- Main program


modem = peripheral.wrap(config.modem_side)
mRail.loadConfig(modem,config_name,config)

loco_chest = peripheral.wrap("right")
cart_chest = peripheral.wrap("left")
dispenser = peripheral.wrap("bottom")

track = peripheral.wrap(config.track_name)

--Open modem to comms channels
modem.open(mRail.channels.dispatch_channel)
modem.open(mRail.channels.station_dispatch_confirm)

term.clear()
while true do
	term.clear()
	term.setCursorPos(1,1)
	print("Current Configuration")
	print("System ID: 	" .. config.id)
	print("Name:		" .. config.name)
	print("Modem Side:	" .. config.modem_side)
	print("Track Name:	" .. config.track_name)
	print("Parent ID:	" .. config.parent_station)
	print("Parent Name: " .. mRail.station_name[tonumber(config.parent_station)])
	print("")
	print("")
	
	print("Waiting for a message")
	local event, modemSide, senderChannel, replyChannel, message, dist = os.pullEvent("modem_message")
	local decodedMessage = json.json.decode(message)
	if decodedMessage.recieverID == config.id then
		if senderChannel == mRail.channels.dispatch_channel then
			print("Dispatch has requested a release")
		-- path A: dispatch requests a release
			mRail.station_request_dispatch(modem, config.parent_station, decodedMessage.serviceID, decodedMessage.trainID, config.id)
			mRail.detection_broadcast(modem, config.id, decodedMessage.serviceID, decodedMessage.trainID, "Pending dispatch from " .. mRail.location_name[tonumber(config.id)])
		elseif senderChannel == mRail.channels.station_dispatch_confirm then
			print("Station has authorised the release")
		-- path B: parent station clears release
			if dispatchTrain(decodedMessage.trainID, tostring(decodedMessage.serviceID)) == true then
				mRail.detection_broadcast(modem, config.id, decodedMessage.serviceID, decodedMessage.trainID, "Dispatched from " .. mRail.location_name[tonumber(config.id)] .. " to " .. mRail.station_name[tonumber(config.parent_station)])
			end
		end
	end
end