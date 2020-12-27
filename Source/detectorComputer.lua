-- mRail Detector Computer
-- (C) 2020 Sam Lane

-- TODO - Comment everything

os.loadAPI("mRail.lua")

-- TODO - Add support for multiple detectors and multiple release points

-- Configuration
local config = {}
-- Default config values:
config.ids = {4,5} -- put -1 for any unused sides
--			  l,r
config.releaseSide = "null"
config.releaseSideID = 1
config.name = "Hub West"
config.modem_side = "bottom"

config_name = ".config"

-- Main Program

modem = peripheral.wrap(config.modem_side)
mRail.loadConfig(modem,config_name,config)

modem.open(mRail.channels.oneway_dispatch_confirm)

term.clear()
term.setCursorPos(1,1)
print("Name: 		 " .. config.name)
print("Modem Side: 	 " .. config.modem_side)
print("Release Side: " .. config.releaseSide)

while true do
	eventType, param1, param2, param3, param4, param5, param6 = os.pullEvent()
	print(eventType)
	if eventType == "minecart" and (param3 == mRail.item_names.train or param3 == mRail.item_names.e_train) then
		local side = param1
		local trainID = 16 - tonumber(param5)
		print("trainID: " .. tostring(trainID))
		local serviceID = param6
		local detectorID = ""
		local textMessage = ""
    
    -- TODO - Clean this up - remove if and have 1 and 2 correspond to a table with those things in
    --      - maybe put it in mRail if that would be useful?
		if side == "left" then
			detectorID = config.ids[1]
			textMessage = "Last seen at " .. mRail.location_name[config.ids[1]]
			if config.releaseSideID == 1 and config.releaseSide ~= "null" then
				textMessage = "Requesting release from " .. mRail.location_name[config.ids[1]]
			end
		elseif side == "right" then
			detectorID = config.ids[2]
			textMessage = "Last seen at " .. mRail.location_name[config.ids[2]]
			if config.releaseSideID == 2 and config.releaseSide ~= "null" then
				textMessage = "Requesting release from " .. mRail.location_name[config.ids[2]]
			end
		end
		print("Detection")
		print("Side " .. side)
		print("ReleaseID " .. config.releaseSideID)
		
		if side == "left" and config.releaseSideID == 1 then
			if config.releaseSide ~= "null" then
				mRail.oneway_request_dispatch(modem, detectorID, serviceID, trainID)
			end
		elseif side == "right" and config.releaseSideID == 2 then
			if config.releaseSide ~= "null" then
				mRail.oneway_request_dispatch(modem, detectorID, serviceID, trainID)
			end
		else
			
		end
		mRail.detection_broadcast(modem, detectorID, serviceID, trainID, textMessage)
		
		
	elseif eventType == "modem_message" then
		local side = param1
		local channel = param2
		local message = param4
		decodedMessage = {}
		decodedMessage = json.json.decode(message)
    -- TODO - Add support for multiple detectors here
		if decodedMessage.detectorID == config.ids[1] or decodedMessage.detectorID == config.ids[2] then
			if config.releaseSide ~= "null" then
				redstone.setOutput(config.releaseSide, true)
				sleep(2)
				redstone.setOutput(config.releaseSide, false)
			end
		end
	end	
end

