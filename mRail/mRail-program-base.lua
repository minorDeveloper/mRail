-- mRail System Program Base
-- (C) 2020-21 Sam Lane

-- From which all other programs are derived...
local program = {}

local baseConfig = {}

-- Program Functions
function program.setup(config_)
  baseConfig = config_
end

function program.onLoop()
  
end


-- Modem Messages
function program.detect_channel(decodedMessage)
  -- Handle messages on the detection channel
end

function program.train_info(decodedMessage)
  -- Handle messages on the train info channel
end

function program.location_update_channel(decodedMessage)
  -- Handle messages on the location update channel
end

function program.dispatch_channel(decodedMessage)
  -- Handle messages on the dispatch channel
end

function program.station_dispatch_confirm(decodedMessage)
  -- Handle messages on the station dispatch confirmation channel
end

function program.station_route_request(decodedMessage)
  -- Handle messages on the station route request channel
end

function program.station_dispatch_request(decodedMessage)
  -- Handle messages on the station dispatch request channel
end

function program.oneway_dispatch_confirm(decodedMessage)
  -- Handle messages on the oneway dispatch confirmation channel
end

function program.station_dispatch_request(decodedMessage)
  -- Handle messages on the station dispatch request channel
end

function program.timetable_updates(decodedMessage)
  -- Handle messages on the detection channel
end

function program.station_route_request(decodedMessage)
  -- Handle messages on the station route request channel
end

function program.detect_channel(decodedMessage)
  -- Handle messages on the detection channel
end

function program.station_dispatch_channel(decodedMessage)
  -- Handle messages on the station dispatch channel
end

function program.screen_update_channel(decodedMessage)
  -- Handle messages on the screen update channel
end

function program.screen_platform_channel(decodedMessage)
  -- Handle messages on the screen platform channel
end

function program.request_dispatch_channel(decodedMessage)
  -- Handle messages on the request dispatch channel
end

function program.error_channel(decodedMessage)
  -- Handle messages on the error channel
end

-- Alarms
function program.handleAlarm(alarmID)
  
end

return program