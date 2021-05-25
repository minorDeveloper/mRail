--
-- log.lua
--
-- Copyright (c) 2016 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local log = { _version = "0.1.0" }

log.usecolor = true
log.outfile = nil
log.level = "trace"


local modes = {
  { name = "trace", color = colors.blue, },
  { name = "debug", color = colors.cyan, },
  { name = "info",  color = colors.green, },
  { name = "warn",  color = colors.yellow, },
  { name = "error", color = colors.orange, },
  { name = "fatal", color = colors.red, },
}


local levels = {}
for i, v in ipairs(modes) do
  levels[v.name] = i
end


local round = function(x, increment)
  increment = increment or 1
  x = x / increment
  return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
end


local _tostring = tostring

local tostring = function(...)
  local t = {}
  for i = 1, select('#', ...) do
    local x = select(i, ...)
    if type(x) == "number" then
      x = round(x, .01)
    end
    t[#t + 1] = _tostring(x)
  end
  return table.concat(t, " ")
end


for i, x in ipairs(modes) do
  local nameupper = x.name:upper()
  log[x.name] = function(...)
    
    -- Return early if we're below the log level
    if i < levels[log.level] then
      return
    end

    local msg = tostring(...)
    --local info = debug.getinfo(2, "Sl")
    --local lineinfo = string.sub(string.sub(info.short_src, 0, string.len(info.short_src) - 4),7) .. ":" .. info.currentline
    local lineinfo = ""
    -- TODO REMOVE THIS
    -- Output to console
    local col = term.getTextColor()
    term.setTextColor(x.color)
    local x, y = term.getCursorPos()
    --term.write(string.format("[%-6s%s]",
    --                   nameupper,
    --                   os.date("%H:%M:%S")))
    term.write(string.format("[%-5s]",
                       nameupper))
    term.setTextColor(col)
    print(string.format(" %s: %s",
                        lineinfo,
                        msg))
    -- Output to log file
    if log.outfile then
      local fp = io.open(log.outfile, "a")
      local str = string.format("[%-6s%s] %s: %s\n",
                                nameupper, os.date(), lineinfo, msg)
      fp:write(str)
      fp:close()
    end

  end
end


return log