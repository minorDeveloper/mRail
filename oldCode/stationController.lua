-- mRail Station Controller
-- (C) 2020 Sam Lane


-- Configuration
local config = {}
-- Default config values:

-- TODO - Remove all this and put it in a config file
config.stationID = 1
config.controlType = "wireless"

config.signalControl = "digital_controller_box_1"
config.switchControl = "digital_controller_box_0"
config.releaseControl = "digital_controller_box_1"

config_name = ".config"

-- state loaded, serviceID, trainID
local currentLoadedStates = {}
local requestList = {}

--sig req, sig state, swit req, swit state
local currentState = {0,0,0,0}


-- alarmID, serviceID, trainID
local alarms = {}


-- TODO - Bump this out to a network configuration file maybe
-- first bit is for entries, second for dispatch
-- serviceName, {what each station should do with it}
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

-- TODO - Bump all this out to config files
-- TODO - Make helper program for station design
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
	10, -- 02
	-1, -- 03
	-1, -- 04
	-1, -- 05
	-1, -- 06
	-1, -- 07
	-1, -- 08
	-1, -- 09
	-1, -- 10
	-1, -- 11
	12, -- 12
	-1, -- 13
}
	
local detectorDepotIDMapping = {
	-1, -- 01
	-1, -- 02
	 3, -- 03
	-1, -- 04
	-1, -- 05
	-1, -- 06
	-1, -- 07
	-1, -- 08
	-1, -- 09
	-1, -- 10
	-1, -- 11
	-1, -- 12
	 2, -- 13
}
	
local detectorExitIDMapping = {
	8,  -- 01
	50, -- 02
	0,  -- 03
	4,  -- 04
	5,  -- 05
	6,  -- 06
	7,  -- 07
	4,  -- 08
	5,  -- 09
	6,  -- 10
	7,  -- 11
	11, -- 12
	0,  -- 13
}
	
local platformIDNameMapping = {
	{4,"1"},
	{5,"2"},
	{6,"3"},
	{7,"4"},
	{8,"1"},
	{9,"2"},
	{10,"3"},
	{11,"4"},
}

local systemRoutingData = {}











