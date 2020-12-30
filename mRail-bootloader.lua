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
    --"github clone rxi/log.lua",
    --"rm /log.lua/LICENSE",
    --"rm /log.lua/README.md",
    --"mv /log.lua/log.lua ./mRail/",
    --"rm log.lua",
    "rm /github.rom",
    "rm /github",
}


function openingScroll(mon, time)
  
  for i = 51, (-1 * (string.len(trainASCII[1]))), -1 do 
    mon.clear()
    writeASCII(trainASCII, mon, i, 2)
    writeASCII(trackASCII, mon, 1, #trainASCII + 2)
    sleep(time / (51 + string.len(trainASCII[1])))
  end
end


function writeASCII(ascii, mon, x, y)
  for i = 1, #ascii do
    mon.setCursorPos(x, y + (i - 1))
    mon.write(ascii[i])
  end
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
os.reboot()

-- Download/get additional configs

-- Pull additional configs from networked computer

-- Delete unnecessary files





