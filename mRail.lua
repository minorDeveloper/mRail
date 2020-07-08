-- mRail system API
-- (C) 2020 Sam Lane




-- Local API Variables (for use here)
local mRail = {}

-- json = dofile("json.lua")
os.loadAPI("json.lua")



local col_to_num = {
	white = 1,
	orange = 2,
	magenta = 3,
	light_blue = 4,
	yellow = 5,
	lime = 6,
	pink = 7,
	gray = 8,
	light_gray = 9,
	cyan = 10,
	purple = 11,
	blue = 12,
	brown = 13,
	green = 14,
	red = 15,
	black = 16
}
	
local num_to_col = {
	"white",
	"orange",
	"magenta",
	"light_blue",
	"yellow",
	"lime",
	"pink",
	"gray",
	"light_gray",
	"cyan",
	"purple",
	"blue",
	"brown",
	"green",
	"red",
	"black"
}


-- Global API Variables (for use in sub-programs)

item_names = {
	train = "Perpetuum Locomotive",
	cart = "Minecart",
	anchor = "Admin Worldspike Cart"
}

channels = {
	detect_channel = 2,
	train_info = 3,
	location_update_channel = 4,
	dispatch_channel = 10,
	station_dispatch_confirm = 11,
	station_dispatch_request = 12,
	oneway_dispatch_confirm = 13,
	oneway_dispatch_request = 14,
	timetable_updates = 15,
	station_route_request = 16,
	station_dispatch_channel = 17,
	error_channel = 999
}

station_name = {}
for i = 1,50 do
	station_name[i] = ""
end
station_name[0] = "Unassigned"  
station_name[1] = "Hub"
station_name[2] = "SJ"
station_name[3] = "Barron"
station_name[4] = "Ryan"

station_id = {
	unassigned = 	{0, station_name[0]},
	hub = 			{1, station_name[1]},
	SJ = 			{2, station_name[2]},
	Barron = 		{3, station_name[3]},
	Ryan = 			{4, station_name[4]}
}

-- ALL COMPUTER ID's in here must be unique (aside from the depot)

location_name = {}
for i = 1,100 do
	location_name[i] = ""
end
location_name[0] = "Depot"

location_name[2] = "HDE"
location_name[3] = "HDW"

location_name[4] = "Hub P1"
location_name[5] = "Hub P2"
location_name[6] = "Hub P3"
location_name[7] = "Hub P4"

location_name[8] = "Hub West Dep"
location_name[9] = "Hub West Arr"
location_name[10]= "Hub Branch"

location_name[11]= "Hub East Dep"
location_name[12]= "Hub East Arr"

location_name[13]= "01 South Entr"
location_name[14]= "01 South Exit"

location_name[15]= "01 North Entr"
location_name[16]= "01 North Exit"

location_name[17]= "02 South Entr"
location_name[18]= "02 South Exit"

location_name[19]= "02 North Entr"
location_name[20]= "02 North Exit"

location_name[21]= "03 South Entr"
location_name[22]= "03 South Exit"

location_name[23]= "03 North Entr"
location_name[24]= "03 North Exit"

location_name[25]= "04 South Entr"
location_name[26]= "04 South Exit"

location_name[27]= "04 North Entr"
location_name[28]= "04 North Exit"

location_name[29]= "05 South Entr"
location_name[30]= "05 South Exit"

location_name[31]= "05 North Entr"
location_name[32]= "05 North Exit"

location_name[33]= "06 South Entr"
location_name[34]= "06 South Exit"

location_name[35]= "06 North Entr"
location_name[36]= "06 North Exit"

location_name[37]= "07 South Entr"
location_name[38]= "07 South Exit"

location_name[39]= "07 North Entr"
location_name[40]= "07 North Exit"

location_name[41]= "08 South Entr"
location_name[42]= "08 South Exit"

location_name[43]= "08 North Entr"
location_name[44]= "08 North Exit"

location_name[45]= "RDN"



location_id = {
	depot = 			{0, location_name[0]},
	hub_depot_east = 	{2, location_name[2]},
	hub_depot_west = 	{3, location_name[3]},
	hub_platform_1 = 	{4, location_name[4]},
	hub_platform_2 =	{5, location_name[5]},
	hub_platform_3 =	{6, location_name[6]},
	hub_platform_4 = 	{7, location_name[7]},
	hub_west_depart =   {8, location_name[8]},
	hub_west_arrival =  {9, location_name[9]},
	hub_west_branch =   {10, location_name[10]},
	hub_east_depart =	{11, location_name[11]},
	hub_east_arrival =  {12, location_name[12]},
	oneway_01_south_entrance =  {13, location_name[13]},
	oneway_01_south_exit =		{14, location_name[14]}
}



	
-- Broadcasts

function detection_broadcast(modem, detectorID, serviceID, trainID, textMessage)
	print("Notifying Tracker and Stations of detection")
	local message = json.json.encode({
		["detectorID"] = detectorID,
		["serviceID"] = serviceID,
		["trainID"] = trainID,
		["textMessage"] = textMessage
		})
	modem.transmit(channels.detect_channel,1,message)
end

-- Dispatch-Depot comms

function dispatch_train(modem, recieverID, serviceID, trainID)
	print("Dispatching the " .. number_to_color(trainID) .. " train from " .. recieverID .. " on route " .. serviceID)
	local message = json.json.encode({
		['recieverID'] = recieverID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	print("Message transmitted")
	print(message)
	modem.transmit(channels.dispatch_channel,1,message)
end

function station_dispatch_train(modem, stationID, serviceID, trainID)
	print("Dispatching the " .. number_to_color(trainID) .. " train from " .. stationID .. " on route " .. serviceID)
	local message = json.json.encode({
		['stationID'] = stationID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	print("Message transmitted")
	print(message)
	modem.transmit(channels.station_dispatch_channel,1,message)
end

-- Station-Depot Comms

function station_request_dispatch(modem, stationID, serviceID, trainID, detectorID)
	print("Requesting permission from station " .. stationID .. "to dispatch train")
	local message = json.json.encode({
		['stationID'] = stationID,
		['serviceID'] = serviceID,
		['trainID'] = trainID,
		['detectorID'] = detectorID
	})
	print("Message transmitted")
	print(message)
	modem.transmit(channels.station_dispatch_request,1,message)
end

function station_confirm_dispatch(modem, recieverID, serviceID, trainID)
	print("Giving " .. recieverID .. " permission to dispatch train")
	local message = json.json.encode({
		['recieverID'] = recieverID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	print("Message transmitted")
	print(message)
	modem.transmit(channels.station_dispatch_confirm,1,message)
end

function station_request_route(modem, stationID, entryID, exitID, serviceID, trainID)
	print("Requesting route")
	local message = json.json.encode({
		['stationID'] = stationID,
		['entryID'] = entryID,
		['exitID'] = exitID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	modem.transmit(channels.station_route_request,1,message)
end


-- Oneway-Detector Comms

function oneway_request_dispatch(modem, detectorID, serviceID, trainID)
	print("Requesting permission to dispatch train " .. trainID)
	local message = json.json.encode({
		['detectorID'] = detectorID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	print("Message transmitted")
	print(message)
	modem.transmit(channels.oneway_dispatch_request,1,message)
end

function oneway_confirm_dispatch(modem, detectorID, serviceID, trainID)
	print("Giving " .. detectorID .. " permission to release train")
	local message = json.json.encode({
		['detectorID'] = detectorID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	print("Message transmitted")
	print(message)
	modem.transmit(channels.oneway_dispatch_confirm,1,message)
end

function timetable_update(modem, timetable)
	print("Updating timetable for all stations")
	local message = json.json.encode({
		['timetable'] = timetable
	})
	print("Message transmitted")
	print(message)
	modem.transmit(channels.timetable_updates,1,message)
end





function raise_error(modem, errMessage, errorLevel)
	local x = 0
	local y = 0
	local z = 0
	x,y,z = gps.locate(1)
	local message = json.json.encode({
	['x'] = x,
	['y'] = y,
	['z'] = z,
	['errMessage'] = errMessage,
	['errorLevel'] = errorLevel
})
	print("Message transmitted")
	print(message)
	modem.transmit(channels.error_channel,1,message)
end

-- Files and configuration

function executeFile(filename, ...)
  local ok, err = loadfile( filename )
  print( "Running "..filename )
  if ok then
    return ok( ... )
  else
    printError( err )
  end
end

function loadConfig(modem,file_name, config)
	if fs.exists(file_name) then
		print("Loading config file...")
		local _config = executeFile(file_name)
		for k,v in pairs(_config) do
			config[k] = v
		end
	else
		print("Error, no configuration file!.")
		raise_error(modem,"No configuration file",1)
		return 1
	end
end


-- Conversions

function color_to_number(color)
	return col_to_num[color]
end

function number_to_color(number)
	return  num_to_col[number]
end