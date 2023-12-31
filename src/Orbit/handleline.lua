




local Node = require "espalier/node"
local u = {}
function u.inherit(meta)
  local MT = meta or {}
  local M = setmetatable({}, MT)
  M.__index = M
  local m = setmetatable({}, M)
  m.__index = m
  return M, m
end
function u.export(mod, constructor)
  mod.__call = constructor
  return setmetatable({}, mod)
end

local Handle = require "orb:Orbit/handle"

local H, h = u.inherit(Node)

function H.toMarkdown(handleline)
   return handleline.__VALUE
end

local function new(Handleline, line)
    local handleline = setmetatable({}, H)
    handleline.__VALUE = line
    handleline.id = "handleline"
    handleline[1] = Handle(line)

    return handleline
end


return u.export(h, new)
