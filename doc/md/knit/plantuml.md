# Plantuml


  This will be a fun one because it violates certain assumptions we've held\.

That's fine\.  They weren't meant to last\.

```lua
local s = require "status:status" ()
s.chatty = true
```


```lua
local plantUML = {code_type = 'plantuml', OLD = true}
```

Just for now, we're going to just knit it\.

```lua
plantUML.pred = function() return false end
plantUML.knit_pred = function() return end
```

Going to need to brush up the knitting interface as I go, it's quite MVP\.

```lua
local spawn;
function plantUML.knit(code_block, scroll, skein)
   spawn = spawn or require "proc:spawn"
   local proc = spawn("plantuml", {"-tsvg", "-pipe"})
   if proc.didnotrun then
      s:warn "plantuml didn't run, is it installed?"
      return
   end
   s:verb "writing plantuml"
   proc:write(code_block :select "code_body"() :span())
   local reddit = assert(proc:read(), debug.traceback())
   s:chat(reddit)
   scroll:add(reddit)
   proc:exit() -- we can do better than this
end
```

```lua
return plantUML
```
