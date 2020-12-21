-- Global Variables

local data = {}					-- State Data
local platformOccupied = {0,0,0,0}

local currentStationState = {}
local currentSignalState = 0
local currentSwitchState = 0



-- Functions

function string:split( inSplitPattern )
 
    local outResults = {}
    local theStart = 1
    local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
 
    while theSplitStart do
        table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
        theStart = theSplitEnd + 1
        theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
    end
 
    table.insert( outResults, string.sub( self, theStart ) )
    return outResults
end

function loadStateTable()
	local lineData = {}
	local file = io.open("DataFiles/StateTable.csv","r")
	i = 1
	for line in file:lines() do
	   lineData[i]=line
	   i=i+1
	end

	for i=1,#lineData do
		local splitLine = lineData[i]:split(",") 
		data[#data + 1] = splitLine
	end
end

function resetOutput()
	redstone.setBundledOutput("back",0)
	redstone.setBundledOutput("left",0)
	redstone.setBundledOutput("right",0)
end

function resetScreen()
	term.clear()
	term.setCursorPos(1,1)
end

function checkCompatible(aReq, aState, bReq, bState)
	return bit.band(bit.band(aReq,bReq),bit.bxor(aState,bState))
end

