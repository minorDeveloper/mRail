-- mRail System Program Base
-- (C) 2020-21 Sam Lane

mRail = require("./mRail/mRail-api")
json  = require("./mRail/json")
log   = require("./mRail/log")

local config = {}


-- From which all other programs are derived...
local program = {}

-- Program Functions
function program.setup(config_)
  config = config_
end
--

function program.onLoop()
  
end
--

-- Modem Messages
function program.ping_channel(decodedMessage)
  -- Handle incoming ping
end
--

function program.detect_channel(decodedMessage)
  -- Handle messages on the detection channel
end
--

function program.train_info(decodedMessage)
  -- Handle messages on the train info channel
end
--

function program.location_update_channel(decodedMessage)
  -- Handle messages on the location update channel
end
--

function program.next_station_request(decodedMessage)
  -- Handle messages on the next station request channel
end
--

function program.next_station_update(decodedMessage)
  -- Handle messsages on the next station update channel
end
--

function program.dispatch_channel(decodedMessage)
  -- Handle messages on the dispatch channel
end
--

function program.ping_request_channel(decodedMessage)
  -- Handle requests for a ping
  program.ping()
end
--

function program.control_channel(decodedMessage)
  if not mRail.identString(config.programType, decodedMessage.programName) then
    return
  end
  
  -- At this point the message is intended for a program of this type
  -- Still need to check for ID (if relevant)
  -- Program specific implementation below
end
--

function program.data_request_channel(decodedMessage)
  
end
--

function program.station_dispatch_confirm(decodedMessage)
  -- Handle messages on the station dispatch confirmation channel
end
--

function program.station_route_request(decodedMessage)
  -- Handle messages on the station route request channel
end
--

function program.station_dispatch_request(decodedMessage)
  -- Handle messages on the station dispatch request channel
end
--

function program.oneway_dispatch_confirm(decodedMessage)
  -- Handle messages on the oneway dispatch confirmation channel
end
--

function program.oneway_dispatch_request(decodedMessage)
  -- Handle messages on the station dispatch request channel
end
--

function program.timetable_updates(decodedMessage)
  -- Handle messages on the detection channel
end
--

function program.station_route_request(decodedMessage)
  -- Handle messages on the station route request channel
end

function program.detect_channel(decodedMessage)
  -- Handle messages on the detection channel
end
--

function program.station_dispatch_channel(decodedMessage)
  -- Handle messages on the station dispatch channel
end
--

function program.screen_update_channel(decodedMessage)
  -- Handle messages on the screen update channel
end
--

function program.screen_platform_channel(decodedMessage)
  -- Handle messages on the screen platform channel
end
--

function program.request_dispatch_channel(decodedMessage)
  -- Handle messages on the request dispatch channel
end
--

function program.control_response_channel(decodedMessage)
  
end
--

function program.error_channel(decodedMessage)
  -- Handle messages on the error channel
end
--

-- Alarms
function program.handleAlarm(alarmID)
  
end
--

function program.handleMinecart(side, loco, locoName, primary, secondary, destination)
  
end
--

function program.handleRedstone()
  
end
--

return program