-- mRail system Bootloader
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
    "mv ./mRail/program-state/ ./tempState/",
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
    --"mkdir ./mRail/program-state/",
    "mv ./tempState/ ./mRail/program-state/",
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

function selectFromVals(listOfOptionPairs, infoString, doCentre, getInt, additionalText)
  local listOfOptionArray = {}
  
  local i = 1
  for param, vals in pairs(listOfOptionPairs) do
    listOfOptionArray[i] = {param, vals}
    i = i + 1
  end
  
  local currentlySelectedInt = 1
  local success = false
  repeat
    -- Print stuff
    logoAndCursor()
    print(infoString .. ": " .. additionalText)
    print("")
    for i = 1, #listOfOptionArray do
      local onSelected = (i == currentlySelectedInt)
      local sideString = (onSelected and " -- " or "    ")
      local mainText = sideString .. listOfOptionArray[i][2] .. sideString
      local padding = ""
      local w, h = term.getSize()
      if doCentre then
        for i = 1, math.floor((w - #mainText)/2) do
          padding = padding .. " "
        end
      end
      print(padding .. mainText)
    end
    -- Wait for keypress
    local event, key, isHeld = os.pullEvent("key")
    if key == keys.up and currentlySelectedInt > 1 then
      currentlySelectedInt = currentlySelectedInt - 1
    elseif key == keys.down and currentlySelectedInt < #listOfOptionArray then
      currentlySelectedInt = currentlySelectedInt + 1
    elseif key == keys.enter then
      success = true
    end
  until(success)
  if getInt then
    return currentlySelectedInt
  end
  return listOfOptionArray[currentlySelectedInt][1]
end

function generateParameter(parameter, values, additionalText)
  while true do
    local options = values[1]
    local configVal = ""
    local optionStrings = {}
    for i = 1, #options do
      local optionString = string.sub(options[i],2,-2)
      if optionString == "%w+" then
        optionString = "Any string"
      elseif optionString == "%d+" then
        optionString = "Any number"
      end
      optionString = string.gsub(optionString, "%%d(+)$", "#")
      optionStrings[i] = optionString
    end

    if #options > 1 then
      configVal = optionStrings[tonumber(selectFromVals(optionStrings, tostring(values[2]) .. ":", true, false, additionalText))]
    else
      configVal = optionStrings[1]
    end
    
    logoAndCursor()
    local lineString = tostring(values[2]) .. ": (enter "
    if configVal == "Any number" then
      lineString = lineString .. "number) "
      print(lineString .. additionalText)
      configVal = tonumber(read())
    elseif configVal == "Any string" then
      lineString = lineString .. "string) "
      print(lineString .. additionalText)
      configVal = tonumber(read())
    elseif string.find(configVal, "#") ~= nil then
      lineString = lineString .. "number) "
      print(lineString .. additionalText)
      configVal = string.gsub(configVal, "#", read())
    end
    
    -- Now check this matches with an option given
    for i = 1, #options do
      if string.match(tostring(configVal),options[i]) ~= nil then
        log.debug("We have been successful!")
        return tostring(configVal)
      end
    end
  end
end

function generateMultiParameter(parameter, values)
  if #values ~= 3 or values[3] == 1 then
    return generateParameter(parameter, values, "")
  end
  local tempValues = {}
  for i = 1, values[3] do
    tempValues[i] = generateParameter(parameter, values, " [" .. i .. "/" .. values[3] .. "]")
  end
  return tempValues
end

function generateConfig()
  local config = {}
  local configTemplate = {}
  
  local success = false
  repeat
    local programType = selectFromVals(mRail.aliases, "Enter the desired program type", true, false, "")
    if mRail.configs[programType] ~= nil then
      config.programType = programType
      success = true
    end
  until (success)
  
  mRail.loadConfig("./mRail/program-configs/" .. mRail.configs[config.programType],configTemplate)
  
  local configID = 1
  if #configTemplate > 1 then
    local tempArray = {}
    for i = 1, #configTemplate do
      tempArray[i] = configTemplate[i].setupName
    end
    configID = selectFromVals(tempArray, "Choose program config", true, true, "")
  end
  
  for parameter, values in pairs(configTemplate[1]) do
    print("Loaded parameter " .. tostring(parameter))
    if tostring(parameter) ~= "setupName" and tostring(parameter) ~= "programType" then
      config[parameter] = generateMultiParameter(parameter, values)
    end
  end
  logoAndCursor()
  mRail.checkConfig(config)
  log.info("Config generated correctly")
  mRail.saveConfig(mRail.configLoc, config)
end


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
log.debug("Checking if a config file already exists")
if fs.exists(mRail.configLoc) then
  local tempConfig = {}
  log.debug("Loading old config")
  mRail.loadConfig(mRail.configLoc, tempConfig)
  local options = {"Continue with old config file", "Create new config file"}
  
  local result = selectFromVals(options, "Config found for " .. mRail.aliases[tempConfig.programType], true, true, "")
  if result == 2 then
    generateConfig()
  end
else
  log.debug("Config file doesn't exist, generating new one")
  generateConfig()
end


-- Pull additional configs from networked computer
--pullConfigs()



os.reboot()


