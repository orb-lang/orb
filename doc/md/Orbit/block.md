# Block module

   A Block is the container for the next level of granularity below
 a Section\. Any Section has a Header and one or more Blocks\. Both the
 Header and the Block may be virtual, that is, without contents\.

 The most general premise is that Blocks are delineated by blank line
 whitespace\.


 A paragraph of prose is the simplest block, and the default\.  A list with
 a tag line is a block also, as is a table\.  Most importantly for our short
 path, code blocks are enclosed in blocks as well\.

 Blocking needs to identify when it has structure, and when prose, on a
 line\-by\-line basis\.  It must also apply the cling rule to make sure that
 e\.g\. tags are part of the block indicated by whitespacing\.

 Blocking need not, and mostly should not, parse within structure or prose\.
 These categories are determined by the beginning of a line, making this
 tractable\.

 The cling rule requires lookahead\. LPEG is quite capable of this, as is
 packrat PEG parsing generally\.  In the bootstrap implementation, we will
 parse once for ownership, again \(in the \`lines\` array of each Section\) for
 blocking, and a final time to parse within blocks\.

 Grimoire is intended to work, in linear time, as a single\-pass PEG
 grammar\.  Presently \(Feb 2018\) I'm intending to prototype that with
 PEGylator and port it to \`hammer\` with a \`quipu\` back\-end\.


### includes

```lua
local L = require "lpeg"

local Node = require "espalier/node"
local Codeblock = require "orb:Orbit/codeblock"
local Structure = require "orb:Orbit/structure"
local Prose = require "orb:Orbit/prose"

local s = require "status:status" ()

local m = require "orb:Orbit/morphemes"
```


## Metatable for Blocks

```lua
local B = setmetatable({}, { __index = Node })
B.__index = B

B.__tostring = function(block)
    return "Block"
end

function B.addLine(block, line)
    if L.match(m.tagline_hash_p, line) then
        block[#block + 1] = Structure(line, "hashline", block.str)
    elseif L.match(m.tagline_handle_p, line) then
        block[#block + 1] = Structure(line, "handleline", block.str)
        -- Eventually Blocks won't have lines, meantime:
    else
        block.lines[#block.lines + 1] = line
    end

    return block
end
```


## Parse the prose within a block

```lua
function B.parseProse(block)
    if block[1] then
        if block[1].id == "codeblock" then
            return ""
        end
    else
        block[1] = Prose(block)
        block.lines = nil
        return block[1]
    end
end
```

### toValue

 Adds a \.val field which is the union of all lines\.
 Useful in visualization\.

```lua
function B.toString(block)
    local phrase = ""
    if type(block.lines) == "table" then
        for _,v in ipairs(block.lines) do
            phrase = phrase .. v .. "\n"
        end
    end
    return phrase
end

function B.toValue(block)
    block.val = block:toString()
    return block.val
end

function B.toMarkdown(block)
    if block[1] and (block[1].id == "codeblock"
      or block[1].id == "prose") then
        return block[1]:toMarkdown()
    else
        return block:toString()
    end
end

function B.dotLabel(block)
    return "block " .. tostring(block.line_first)
        .. "-" .. tostring(block.line_last)
end
```


## Constructor/module

```lua
local b = {}

local function new(Block, lines, linum, str)
    local block = setmetatable({}, B)
    block.lines = {}
    block.line_first = linum
    if (lines) then
        if type(lines) == "string" then
            block:addLine(lines)
        elseif type(lines) == "table" then
            for _, l in ipairs(lines) do
                block:addLine(l)
            end
        else
            freeze("Error: in block.new type of `lines` is " .. type(lines))
        end
    end

    block.id = "block"
    return block
end
```


 Sorts lines into structure and prose\.

 - line : taken from block\.lines

 - returns:
        1. true for structure, false for prose
        2. id of structure line or "" for prose


```lua
local function structureOrProse(line)
    if L.match(m.tagline_p, line) then
        return true, "tagline"
    elseif L.match(m.listline_p, line) then
        return true, "listline"
    elseif L.match(m.tableline_p, line) then
        return true, "tableline"
    end
    return false, ""
end

b["__call"] = new
b["__index"] = b

return setmetatable({}, b)
```
