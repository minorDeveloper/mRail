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

local function getNextDirection(currentDir, reverser)
  if reverser then
    if currentDir == forw then
      return back
    end
    return forw
  end
  return currentDir
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
      local exit = graph[node][direction][i]
      print("Looking at " .. (exit~=nil and exit or "invalid node"))
      if exit ~= nil and not table.contains(visited, {exit, direction}) then
        print("    We haven't been here before")
        direction = getNextDirection(direction, graph[exit][4])
        table.insert(visited, {exit, direction})
        if graph[exit] then
          local new = table.copy(path)
          local newDir = table.copy(directions)
          table.insert(newDir, direction)
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




reverser = true
continue = false

forw = 2
back = 3

local graph = {
  {01, {3},          {},     continue, forw},
  {02, {3},          {},     continue, forw},
  {03, {1, 2, 5, 6}, {},     continue, nil},
  {04, {5, 7},       {7},    reverser, nil},
  {05, {3, 4},       {},     continue, nil},
  {06, {3, 8},       {},     continue, nil},
  {07, {4, 8},       {4, 8}, continue, nil},
  {08, {6, 7, 10},   {7, 9}, continue, nil},
  {09, {8},          {},     reverser, forw},
  {10, {},           {8},    reverser, back},
}

local ryanGraph = {
  {01, {},               {},            continue, forw},
  {02, {4},              {},            continue, forw},
  {03, {4},              {},            continue, nil},
  {04, {2,3,7},          {},            continue, nil},
  {05, {1,7},            {},            continue, nil},
  {06, {12,15},          {12,15},       reverser, nil},
  {07, {4,5,8,10},       {},            continue, nil},
  {08, {7,11},           {},            continue, nil},
  {09, {1},              {},            continue, nil},
  {10, {7,16},           {},            continue, nil},
  {11, {8,11,12,13,14},  {},            continue, nil},
  {12, {6,11},           {},            continue, nil},
  {13, {11,16},          {},            continue, nil},
  {14, {11,19},          {},            continue, nil},
  {15, {6,17,20},        {6,17,20},     continue, nil},
  {16, {10,13,18,27},    {},            continue, nil},
  {17, {15,19},          {15,19},       continue, nil},
  {18, {16,26},          {},            continue, nil},
  {19, {14,17,21,28,29}, {17,21,24,25}, continue, nil},
  {20, {15,29},          {15,25},       continue, nil},
  {21, {19,29},          {},            continue, nil},
  {22, {9,18},           {},            continue, forw},
  {23, {16},             {},            continue, forw},
  {24, {19},             {},            reverser, forw},
  {25, {20,21},          {},            reverser, forw},
  {26, {31},             {},            continue, forw},
  {27, {30,34},          {},            continue, forw},
  {28, {},               {19},          reverser, back},
  {29, {},               {20,21},       reverser, back},
  {30, {23,31},          {},            continue, nil},
  {31, {22,30,32},       {},            continue, nil},
  {32, {31},             {},            continue, forw},
  {33, {31},             {},            continue, forw},
  {34, {},               {},            continue, nil},
}

print("-------------------------------------------------------------------")
paths = bfs(ryanGraph, 28, 1)
print("It ran")
print(#paths)
print("Final path is " .. getPathString(paths[1]))