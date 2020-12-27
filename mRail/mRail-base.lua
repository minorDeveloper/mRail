-- mRail System Base Program
-- (C) 2020-21 Sam Lane

-- Base program where all mRail systems are launched from

-- Configuration
local config = {}
config_name = ".global-config"

-- Functions:


-- Load mRail-api
mRail = require("/programs/mRail-api.lua")

-- Load config


-- Load appropriate program
mymathmodule = require("mymath")

-- Main loop