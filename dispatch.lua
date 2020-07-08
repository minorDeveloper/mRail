-- mRail Station Controller
-- (C) 2020 Sam Lane

os.loadAPI("mRail.lua")


-- Configuration
local config = {}
-- Default config values:
config_name = ".config"


-- routename, depotID, {stationID, departure time (offset from 0)}, depotID
routes = {
	{"HR Expr", 2, {{1,1.0},{4,10.0}}, 45}}

-- route ID, assigned train, start time
timetabledServices = {{1,2,6.0}}



function dispatch_from_depot(depotID, trainID, serviceID)

end

function set_days_alarms()
	local alarmIDs = {}
	for i = 6, 18.5, 0.5 do
	
	end
	return alarmIDs
end

function send_dispatch_messages(currentTime)

end
