-- mRail system API
-- (C) 2020 Sam Lane

-- TODO - Add functions for complete network control and ability to reset things
--      - Stations
--      - One-way Blocks
--      - Train Tracking
--      - Stop/Start Dispatch


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
	e_train = "Electric Locomotive",
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
	screen_update_channel = 18,
	screen_platform_channel = 19,
	request_dispatch_channel = 20,
	error_channel = 999
}


-- TODO - Pull all this out into network config files!

station_name = {}
for i = 1,5 do
	station_name[i] = ""
end
station_name[0] = "Unassigned"  
station_name[1] = "Hub"
station_name[2] = "SJ"
station_name[3] = "Barron"
station_name[4] = "Ryan"
station_name[5] = "Among Us"

stationRouting = {
	-- basic routes
	--Name   	  Hub										          SJ				    Barron		          Ryan
	{"", 		    {{{13,3},{13,3}},						    {{2},{2}},		{{2,7},{2,7}},			{{2,13},{2,13}}}},
	{"Hub",		  {{{7,11,6,10,5,9,4,8},{13,3}},	{{2},{1}},		{{1},{1}},			    {{1},{1}}}},
	{"SJ", 		  {{{2},{2}},								      {{9,10},{2}},	{{1},{1}},			    {{1},{1}}}},
	{"Barron", 	{{{12},{12}},							      {{2},{1}},		{{3,4,5,6},{2,7}},	{{1},{1}}}},
	{"Ryan", 	  {{{1},{1}},								      {{2},{1}},		{{1},{1}},			    {{5,6,7,8,9,10,11,12},{2,13}}}},
	-- complex routes
	{"BR Expr", {{{1},{1}},								      {{2},{2}},		{{3,4},{1}},		    {{10,9,11,12},{13}}}},
	{"BH Stop", {{{6,4},{3}},							      {{2},{2}},		{{3,4},{1}},		    {{2,13},{2,13}}}},
	{"BR Stop", {{{4,6,7,5},{1}},						    {{2},{2}},		{{3,4},{1}},		    {{10,9,11,12},{2,13}}}},
	{"BS Stop", {{{6,7,4,5},{2}},						    {{9,10},{2}},	{{3,4},{1}},		    {{2,13},{2,13}}}},
	{"HR Expr", {{{4,6,7,5},{1}},						    {{2},{2}},		{{2,7},{2,7}},			{{12,11},{2,13}}}},
	{"HS Expr", {{{4,6,7,5},{2}},						    {{9,10},{2}},	{{2,7},{2,7}},			{{2,13},{2,13}}}},
	{"HB Stop", {{{11,10},{12}},						    {{2},{2}},		{{6,5},{2,7}},		  {{2,13},{2,13}}}},
	{"SH Expr", {{{10,9,11,8},{13}},					  {{5,6},{1}},	{{2,7},{2,7}},			{{2,13},{2,13}}}},
	{"SB Stop", {{{9,11,10,8},{12}},					  {{5,6},{1}},	{{6,5},{2,7}},			{{2,13},{2,13}}}},
	{"RH Expr", {{{9,10,11,8},{13}},					  {{2},{2}},		{{2,7},{2,7}},			{{5,6},{1}}}},
	{"RB Stop", {{{9,11,8,10},{12}},					  {{2},{2}},		{{6,5},{2,7}},			{{8,7},{1}}}},
	{"RB Expr", {{{12},{12}},							      {{2},{2}},		{{6,5},{2,7}},			{{5,6},{1}}}},
  {"AmongUs", {{{12},{12}},							      {{2},{2}},		{{6,5},{2,7}},			{{8,7},{1}}}},
	{"R Branch",{{{12},{12}},							      {{2},{2}},		{{6,5},{2,7}},			{{11,12,10,9},{2,13}}}},
}

-- ALL COMPUTER ID's in here must be unique (aside from the depot)

location_name = {}
for i = 1,100 do
	location_name[i] = ""
end
location_name[0] = "Depot"

--Hub Station

location_name[2] = "HDE"
location_name[3] = "HDW"

location_name[4] = "Hub P1"
location_name[5] = "Hub P2"
location_name[6] = "Hub P3"
location_name[7] = "Hub P4"

location_name[8] = "Hub West Dep"
location_name[9] = "Hub West Arr"
location_name[10]= "Hub Branch Arr"

location_name[11]= "Hub East Dep"
location_name[12]= "Hub East Arr"

-- North Mainline

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


--SJ
location_name[45] = "SJD"

location_name[46] = "SJ P1"
location_name[47] = "SJ P2"

location_name[48]= "SJ Arr"
location_name[49]= "SJ Dep"

location_name[50]= "Hub Branch Dep"

-- Branch West

location_name[51]= "01 East Entr"
location_name[52]= "01 East Exit"

location_name[53]= "01 West Entr"
location_name[54]= "01 West Exit"
location_name[55]= "02 East Entr"
location_name[56]= "02 East Exit"

location_name[57]= "02 West Entr"
location_name[58]= "02 West Exit"
location_name[59]= "03 East Entr"
location_name[60]= "03 East Exit"

location_name[61]= "03 West Entr"
location_name[62]= "03 West Exit"
location_name[63]= "04 East Entr"
location_name[64]= "04 East Exit"

location_name[65]= "04 West Entr"
location_name[66]= "04 West Exit"
location_name[67]= "05 East Entr"
location_name[68]= "05 East Exit"

location_name[69]= "05 West Entr"
location_name[70]= "05 West Exit"

--Barron
location_name[71] = "BDW"
location_name[72] = "BDE"

location_name[73] = "B P1"
location_name[74] = "B P2"

location_name[75] = "Barr East Arr"
location_name[76] = "Barr East Dep"

location_name[77] = "Barr West Arr"
location_name[78] = "Barr West Dep"

--Ryan
location_name[79] = "RDS"
location_name[80] = "RDN"

location_name[81] = "R P1"
location_name[82] = "R P2"
location_name[83] = "R P3"
location_name[84] = "R P4"

location_name[85] = "Ryan South Arr"
location_name[86] = "Ryan South Dep"

location_name[87] = "Ryan North Arr"
location_name[88] = "Ryan North Dep"

--Ryan South Branch

location_name[89] = "Ryan S Branch Entr"
location_name[90] = "Ryan S Branch Exit"

location_name[91] = "Ryan W Branch Entr"
location_name[92] = "Ryan W Branch Exit"

location_name[93] = "Among Us Entr"
location_name[94] = "Among Us Exit"
	
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

-- TODO - Add ability to request next station from dispatch
-- TODO - Add ability to respond to next station request (broadcast to trainTracking)

-- TODO - Comment all of these functions

-- Dispatch-Depot comms

function request_dispatch(modem, recieverID, serviceID, trainID)
	print("Requesting the " .. number_to_color(trainID) .. " train from " .. recieverID .. " on route " .. serviceID)
	local message = json.json.encode({
		['recieverID'] = recieverID,
		['serviceID'] = serviceID,
		['trainID'] = trainID
	})
	print("Message transmitted")
	print(message)
	modem.transmit(channels.request_dispatch_channel,1,message)
end


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

function screen_update(modem, stationID, arrivals, departures)
	local message = json.json.encode({
		['stationID'] = stationID,
		['arrivals'] = arrivals,
		['departures'] = departures
		})
	modem.transmit(channels.screen_update_channel,1,message)
end

function screen_platform_update(modem, stationID, serviceID, platform)
	local message = json.json.encode({
		['stationID'] = stationID,
		['serviceID'] = serviceID,
		['platform'] = platform
		})
	modem.transmit(channels.screen_platform_channel,1,message)
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