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
    "rm /github.rom",
    "rm /github",
    "rm /mRail/LICENSE",
    "rm /mRail/README.md",
    "rm /mRail/mRail-bootloader.lua",
    "mv /mRail/startup.lua .",
    "rename /mRail temp",
    "copy /temp/mRail .",
    "rm temp",
}


function openingScroll(mon, time)
    for i = 51, (-1 * (string.len(trainASCII[1]))), -1 do 
      mon.clear()
      writeASCII(trainASCII, mon, i, 2)
      writeASCII(trackASCII, mon, 1, #trainASCII + 2)
      sleep(0.2)
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

--openingScroll(term)
term.clear()
writeASCII(logoASCII, term, 10, 2)

read()

-- Download/get additional configs

-- Delete unnecessary files





