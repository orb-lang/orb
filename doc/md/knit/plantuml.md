# Plantuml


  This will be a fun one because it violates certain assumptions we've held\.

That's fine\.  They weren't meant to last\.

```lua
local s = require "status:status" ()
s.chatty = true
```

```lua
local PlantUML = require "orb:knit/knitter" "plantuml"
```


Going to need to brush up the knitting interface as I go, it's quite MVP\.

This is only called right now if `#!plantuml` is the codeblock so we're going
to hotwire it\.

```lua
function PlantUML.examine(plant, skein, codeblock)
   return true
end
```

```lua
local spawn;

function PlantUML.knit(plant, skein, codeblock, scroll)
   spawn = spawn or require "proc:spawn"
   local proc = spawn("plantuml", {"-tsvg", "-pipe"})
   if proc.didnotrun then
      s:warn "plantuml didn't run, is it installed?"
      return
   end
   s:verb "writing plantuml"
   proc:write(codeblock :select "code_body"() :span())
   local reddit = assert(proc:read(), debug.traceback())
   s:chat(reddit)
   scroll:add(reddit)
   proc:exit() -- we can do better than this
end
```

```lua
return PlantUML
```
