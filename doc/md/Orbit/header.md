# Header metatable

 A specialized type of Node, used for first\-pass ownership and
 all subsequent operations\.

```lua
local L = require "lpeg"

local Node = require "espalier/node"

local m = require "orb:Orbit/morphemes"
```


 A header contains a header line, that is, one which begins with
 `WS^0 * '*'^1 * ' '`\.

 In addition to the standard Node fields, a header has:

  - parent\(\) :  A function that returns its parent, which is either a
      **block** or a **doc**\.

      \#deprecated a Node has a \.parent field, we should use that

  -  dent :  The level of indentation of the header\. Must be non\-negative\.

  -  level :  The level of ownership \(number of tars\)\.

  - line :  The rest of the line \(stripped of lead whitespace and tars\)


## Metatable for Headers

```lua
local H = setmetatable({}, { __index = Node })
H.id = "header"
H.__index = H

H.__tostring = function(header)
    return "Lvl " .. tostring(header.level) .. " ^: "
           .. tostring(header.line)
end

function H.dotLabel(header)
    return tostring(header.level) .. " : " .. header.line
end

function H.toMarkdown(header)
    local haxen = ""
    if header.level > 0 then
        haxen = ("#"):rep(header.level)
    end
    return haxen .. " " .. header.line
end
```


## Constructor/module

```lua
local h = {}
```


### Header:match\(str\)

 Matches a header line\.

 - str :  The string to match against\.

 \#return :
  - boolean for header match
  - level of header
  - header stripped of left whitespace and tars


```lua
function h.match(str)
    if str ~= "" and L.match(m.header, str) then
        local trimmed = str:sub(L.match(m.WS, str))
        local level = L.match(m.tars, trimmed) - 1
        local bareline = trimmed:sub(L.match(m.tars * m.WS, trimmed))
        return true, level, bareline
    else
        return false, 0, ""
    end
end
```


 Creates a Header Node\.

 @Header: this is h
 @line: string containing the left\-stripped header line \(no tars or whitespace\)\.
 @level: number representing the document level of the header
 @spanner: a table containing the Node values
 @parent: a closure which returns the containing Node\. Must be "doc" or "block"\.

 @return: a Header representing this data\.


```lua
local function new(Header, line, level, first, last, str)
    local header = setmetatable({}, H)
    header.line = line
    header.level = level
    header.first = first
    header.last = last
    header.str = str
    return header
end

function H.howdy()
    io.write("Why hello!\n")
end


h.__call = new
h.__index = h

return setmetatable({}, h)
```
