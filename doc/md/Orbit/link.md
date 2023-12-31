# Link module

Links will be fairly exacting\. The anchor text is simple enough, it's
the actual URI\-expanded syntax that will get fancy\.

Fancy enough for its own parse, I'd imagine\.

For now, some knitting and weaving notes:

  -  A link starting with `/` is local to the respective directory\.

      So, `/src` to `/src`, `/orb` to `/orb` and so on\.

  -  A link to an orb file has no file extension\.

  -  A link to `./` is the root directory of the codex\.

  -  Thus `/` and `./orb` are equivalent\.

  -  The actual root directory is called `file://`\.



```lua
local L = require "lpeg"

local m = require "orb:Orbit/morphemes"
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
local s = require "status:status" ()

local Node = require "espalier/node"
```


```lua
local Li, li = u.inherit(Node)
```

## Transformers


### toMarkdown

  Our Markdown link parser will need to be moderately sophisticated,
and soon, to deal with internal links\.

For now we are more limited in our pattern recognition\.

```lua
function Li.toMarkdown(link)
   local anchor_text = ""
   local url = ""
   if link[1].id == "anchortext" then
      anchor_text = link[1]:toValue()
   end
   if link[2].id == "url" then
      url = link[2]:toValue()
   end

   return "[" .. anchor_text .. "]"
         .. "(" .. url .. ")"
end
```


### export

```lua
return Li
```