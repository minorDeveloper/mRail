-- mRail system API
-- (C) 2020-21 Sam Lane

-- This bootloader program will guide the user through
-- the download and setup process of an mRail computer

-- The program runs standalone without any dependencies

-- Train logo (shown during downloading)
local trainASCII = {
  "           o x o x o x o . . .                                                 ",
  "         o      _____            _______________ ___=====__T___                ",
  "       .][__n_n_|DD[  ====_____  |    |.\\/.|   | |   |_|     |_                ",
  "      >(________|__|_[_________]_|____|_/\\_|___|_|___________|_|               ",
  "      _/oo OOOOO oo   ooo   ooo   o^o       o^o   o^o     o^o                  ",
}

-- Track base for train
local trackASCII = {
  "-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-",
}

-- mRail logo
local logoASCII = {
  "              ____         _  __",
  "   ____ ___  / __ \\____ _ (_)/ /",
  "  / __ `__ \\/ /_/ / __ `// // / ",
  " / / / / / / _, _/ /_/ // // /  ",
  "/_/ /_/ /_/_/ |_|\\__,_//_//_/   ",
}

local commandsToRun = {
    "rm /mRail",
    "rm startup.lua",
    "pastebin run p8PJVxC4",
    "github clone minorDeveloper/mRail",
    "rm /mRail/LICENSE",
    "rm /mRail/README.md",
    "rm /mRail/mRail-bootloader.lua",
    "mv /mRail/startup.lua .",
    "rename /mRail temp",
    "copy /temp/mRail .",
    "rm temp",
    "rm /github.rom",
    "rm /github",
    "mkdir ./mRail/program-state/",
}


function openingScroll(mon, time)
  
  for i = 51, (-1 * (string.len(trainASCII[1]))), -1 do 
    mon.clear()
    writeASCII(trainASCII, mon, i, 2)
    writeASCII(trackASCII, mon, 1, #trainASCII + 2)
    sleep(time / (51 + string.len(trainASCII[1])))
  end
end

function logoAndCursor()
  term.clear()
  term.setCursorPos(1,1)
  writeASCII(logoASCII, term, 10, 2)
  writeASCII(trackASCII, term, 1, #trainASCII + 2)
  term.setCursorPos(1,8)
end


function writeASCII(ascii, mon, x, y)
  for i = 1, #ascii do
    mon.setCursorPos(x, y + (i - 1))
    mon.write(ascii[i])
  end
end

function generateConfig()
  local config = {}
  local configTemplate = {}
  
  local success = false
  repeat
    logoAndCursor()
    print("Enter the desired program type")
    for parameter, values in pairs(mRail.aliases) do
      print(tostring(parameter) .. " : " .. tostring(values))
    end
    print("")
    local programType = read()
    if mRail.configs[programType] ~= nil then
      config.programType = programType
      success = true
    end
  until (success)
  
  logoAndCursor()
  print("")
  print("Program chosen successfully")
  print("Loading config: " .. "./mRail/program-configs/" .. mRail.configs[config.programType])
  read()
  mRail.loadConfig("./mRail/program-configs/" .. mRail.configs[config.programType],configTemplate)
  
  logoAndCursor()
  print("")
  print("Looping through parameters in the configTemplate") 
  
  -- TODO the 1 is VERY PLACEHOLDER!!! --------\*/----------
  for parameter, values in pairs(configTemplate[1]) do
    print("Loaded parameter " .. tostring(parameter))
    if tostring(parameter) == "setupName" or tostring(parameter) == "programType" then
    else
      local success = false
      repeat
        logoAndCursor()
        print(tostring(values[2]) .. ": (choose from the following)")
        local options = values[1]
        for i = 1, #options do
          print(options[i])
        end
        local configVal = read()
        
        -- Now check this matches with an option given
        for i = 1, #options do
          if string.match(tostring(configVal),options[i]) ~= nil then
            log.debug("We have been successful!")
            config[parameter] = tostring(configVal)
            success = true
            break
          end
        end
      until (success)
    end
  end
  logoAndCursor()
  mRail.checkConfig(config)
  log.info("Config generated correctly")
  -- TODO - save config
  log.debug("Saving user generated configuration file")
  mRail.saveConfig("./mRail/.config", config)
end

-- START OF PROGRAM

-- make or read config file

-- Download programs

for i = 1, #commandsToRun do
  shell.run(commandsToRun[i])
end

-- Load APIs
mRail = require("./mRail/mRail-api")
json = require("./mRail/json")
log = require("./mRail/log")
log.info("APIs loaded sucessfully")

term.clear()
openingScroll(term,4)
writeASCII(logoASCII, term, 10, 2)

-- TODO - Make this program use own code
-- TODO - Add config file generation

sleep(2)
-- Write config file!

-- Download/get additional configs (as dictated by config file type)
generateConfig()

-- Pull additional configs from networked computer
--pullConfigs()



os.reboot()


