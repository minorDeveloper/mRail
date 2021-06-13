--- Pathfinder
-- @module pathfinder
-- @author Sam Lane
-- @copyright 2020-21

function table.contains(tbl, e)
  for _, v in pairs(tbl) do
    if v[1] == e[1] and v[2] == e[2] then
      return true
    end
  end

  return false
end

function table.copy(tbl)
  local t = {}

  for _, v in pairs(tbl) do
    table.insert(t, v)
  end

  return t
end


local queue = {}
local directionQ = {}

function queue:init()
  local q = {}

  q.stack = {}

  function q:push(e)
    table.insert(self.stack, e)
  end

  function q:pull()
    local e = self.stack[1]

    table.remove(self.stack, 1)

    return e
  end

  function q:count()
    return #self.stack
  end

  return q
end

function directionQ:init()
  local q = {}

  q.stack = {}

  function q:push(e)
    table.insert(self.stack, e)
  end

  function q:pull()
    local e = self.stack[1]

    table.remove(self.stack, 1)

    return e
  end

  function q:count()
    return #self.stack
  end

  return q
end

local function getDirectionString(direction)
  if direction == forw then
    return "forward"
  end
  return "backward"
end

local function getPathString(path)
  local str = "["
  for i = 1, #path do
    str = str .. " " .. path[i]
    if i ~= #path then
      str = str .. ","
    end
  end
  str = str .. " ]"
  return str
end

local function getDString(directions)
  local str = "["
  for i = 1, #directions do
    str = str .. " " .. ((directions[i] == forw) and "forw" or "back")
    if i ~= #directions then
      str = str .. ","
    end
  end
  str = str .. " ]"
  return str
end

local function getNextDirection(currentDir, directionConverter)
  if directionConverter == continue then
    return currentDir
  end
  
  if currentDir == forw and directionConverter == forwToBack then
    return back
  elseif currentDir == back and directionConverter == backToForw then
    return forw
  end
end




local function bfs(graph, start, goal)
  if not graph[start] or not graph[goal] then
    return false
  end
  local validPaths = {}

  local visited = {}
  local queue = queue:init()
  local directionQ = directionQ:init()
  
  
  directionQ:push({graph[start][5]})
  queue:push({start})
  table.insert(visited, {start, graph[start][5]})

  while queue:count() > 0 do
    local path = queue:pull()
    local node = path[#path]
    local directions = directionQ:pull()
    print("--------------------------------------------------")
    print("Dir  " .. getDString(directions))
    print("Path " .. getPathString(path))
    local direction = directions[#directions]
    if node == goal then 
      print("Path found")
      validPaths[#validPaths + 1] = path
    end
    print("Examining node " .. node .. " in direction " .. ((direction == forw) and "forw" or "back"))
    for i = 1, #graph[node][direction] do
      print("i " .. i)
      print("node " .. node)
      print("direction " .. direction)
      local exit = graph[node][direction][i]
      print("Looking at " .. (exit~=nil and exit or "invalid node"))
      if exit ~= nil and not table.contains(visited, {exit, direction}) then
        print("    We haven't been here before")
        print("direction " .. direction)
        print("node " .. exit)
        print("reverser val " .. graph[exit][4])
        nextDirection = getNextDirection(direction, graph[exit][4])
        table.insert(visited, {exit, nextDirection})
        if graph[exit] then
          local new = table.copy(path)
          local newDir = table.copy(directions)
          table.insert(newDir, nextDirection)
          table.insert(new, exit)
          directionQ:push(newDir)
          queue:push(new)
        end
      end
    end
  end

  if validPaths ~= nil then return validPaths end
  return false
end





continue = 1
forwToBack = 2
backToForw = 3

forw = 2
back = 3


local stationGraph = {
  {01, {4},             {},           continue,   forw},
  {02, {},              {5},          forwToBack, nil},
  {03, {5},             {},           backToForw, nil},
  {04, {1,6,7},         {},           continue,   nil},
  {05, {2,6,8},         {3,8},        continue,   nil},
  {06, {4,5},           {},           continue,   nil},
  {07, {4,9,10},        {},           continue,   nil},
  {08, {5,11},          {5,11},       continue,   nil},
  {09, {7,11},          {},           continue,   nil},
  {10, {7,13},          {},           continue,   nil},
  {11, {8,9,12,14},     {8,12,14},    continue,   nil},
  {12, {11,13},         {11,13},      continue,   nil},
  {13, {10,12,17},      {12,15},      continue,   nil},
  {14, {11,18},         {11,16},      continue,   nil},
  {15, {13},            {},           continue, forw},
  {16, {14},            {},           continue, forw},
  {17, {},              {13},         continue, back},
  {18, {},              {14},         continue, back},
}

local complexStationGraph = {
  
}

print("-------------------------------------------------------------------")
paths = bfs(stationGraph, 1, 8)
print("It ran")
print(#paths)
print("Final path is " .. getPathString(paths[1]))