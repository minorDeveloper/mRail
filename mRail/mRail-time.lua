--- Time
-- @module time-tracker
-- @author Sam Lane
-- @copyright 2020-21

mRail = require("./mRail/mRail-api")
json = require("./mRail/json")
log = require("./mRail/log")

local config = {}

local playerDetector 


-- From which all other programs are derived...
local program = {}

-- Program Functions
function program.setup(config_)
  config = config_
  
  playerDetector = peripheral.wrap(config.playerDetector)
  
  while true do
    local currentTime = os.time()
    if currentTime <= 6.25 and currentTime >= 6.0 and #playerDetector.getAllPlayers() ~= 0 then
        redstone.setOutput(config.outputSide,true)
    else
        redstone.setOutput(config.outputSide,false)
    end
    sleep(5)
  end
end


function program.onLoop()
  
end

function program.handleRedstone()
  
end

return program