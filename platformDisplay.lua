-- mRail Platform Display
-- (C) 2020 Sam Lane

os.loadAPI("mRail.lua")


-- Configuration
local config = {}
-- Default config values:
config.stationID = 1
config.screens = 2
config.modem_side = "front"
config_name = ".config"

--route name, expected platform
routePlatformMapping = {}
arrivals = {}
departures = {}

-- functions


function updateDisplay()
	if config.screens == 1 then
		singleDisplay()
	elseif config.screens == 2 then
		arrDepDisplay()
	end
end

function arrDepDisplay()
	local departuresDisplay = peripheral.wrap("left")
	local arrivalsDisplay = peripheral.wrap("right")
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
	
	
	if #departures ~= 0 then
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
			if #routePlatformMapping ~= 0 then
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
			end
			
			line = line + 1
			if #stations > 1 then
				print("New via")
				departuresDisplay.setCursorPos(7,line)
				departuresDisplay.write("via " .. mRail.station_name[stations[1]])
				line = line + 1
			end
		end
	end
	
	
	-- Write arrivals display
	arrivalsDisplay.setCursorPos(1,1)
	arrivalsDisplay.setTextColor(colors.lightGray)
	arrivalsDisplay.write("Arrivals")
	arrivalsDisplay.setTextColor(colors.orange)
	arrWidth, arrHeight = arrivalsDisplay.getSize()
	
	local line = 2
	
	
	if #arrivals ~= 0 then
		for i = 1, #arrivals do
			if line > arrHeight then 
				break
			end
			arrivalsDisplay.setCursorPos(1,line)
			arrivalsDisplay.write(mRail.station_name[arrivals[i][2]])
			arrivalsDisplay.setCursorPos(9,line)
			arrivalsDisplay.write(textutils.formatTime(tonumber(arrivals[i][1]), true ))
			
			
			local serviceID = arrivals[i][3]
			if #routePlatformMapping ~= 0 then
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
			end
			
			line = line + 1
		end
	end
end

function singleDisplay()

end

function generateRoutePlatformMapping()
	local whatToDo = mRail.whatToDo
	if #whatToDo ~= 0 then
		for i = 1, #whatToDo do
			local temp = {whatToDo[i][1],0}
			table.insert(routePlatformMapping,temp)
		end
	end
end

function handlePlatformUpdate(serviceID, platform)
	if #routePlatformMapping ~= 0 then
		for i = 1, #routePlatformMapping do
			if tostring(routePlatformMapping[i][1]) == tostring(serviceID) then
				routePlatformMapping[i][2] = tostring(platform)
			end
		end
	end
end

function handleScreenUpdate(newArrivals, newDepartures)
	arrivals = newArrivals
	departures = newDepartures
end

-- main program

modem = peripheral.wrap(config.modem_side)

--generate list of routes and blank platform assignments
generateRoutePlatformMapping()

--open modem to listen for platforms
--open modem to listen for routing updates
modem.open(mRail.channels.screen_update_channel)
modem.open(mRail.channels.screen_platform_channel)
updateDisplay()

while true do
	--wait for an event
	event, side, frequency, replyFrequency, message, distance = os.pullEvent("modem_message")
	--process event
	local decodedMessage = json.json.decode(message)
	print("Frequency " .. frequency)
	
	if frequency == mRail.channels.screen_update_channel then
		if decodedMessage.stationID == config.stationID then
			print("Arr/dep update recieved")
			handleScreenUpdate(decodedMessage.arrivals, decodedMessage.departures)
		end
	elseif frequency == mRail.channels.screen_platform_channel then
		
		if decodedMessage.stationID == config.stationID then
			print("Platform update recieved")
			handlePlatformUpdate(decodedMessage.serviceID, decodedMessage.platform)
		end
	end
	
	--update display
	updateDisplay()
end