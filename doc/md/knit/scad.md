# OpenSCAD format

Can't deal with the IDE which comes with it anymore\.

This is just going to be an MVP copypasta of the C compiler with all
discussion removed, but it's past time to make a generalizable knitter which
other users can plug in and extend\. I mean extension, mixed bag right? but
there's no other way forward\.

#### imports

```lua
local s = require "status:status" ()
```


## SCAD Knitter

```lua
local scad_knit = {}
```


### Code type

```lua
scad_knit.code_type = "scad"
```



### Predicate

We use the predicator to ignore 
\#asLua
 blocks:

```lua
local scad_noknit = require "orb:knit/predicator" "#asLua"
```

```lua
scad_knit.pred = function() return false end

scad_knit.knit_pred = function() return end
```


### Knitter


```lua
function scad_knit.knit(codeblock, scroll, skein)
   if scad_noknit(codeblock, skein) then return end
   local codebody = codeblock :select "code_body" ()
   local line_start, _ , line_end, _ = codebody:linePos()
   for i = scroll.line_count, line_start - 1 do
      scroll:add "\n"
   end
   scroll:add(codebody)
   -- add an extra line and skip 2, to get a newline at EOF
   scroll:add "\n"
   scroll.line_count = line_end + 2
end
```

```lua
return scad_knit
```
