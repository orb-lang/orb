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
local scad_knit = {OLD = true}
```

```lua
local Scad_knit = require "orb:knit/knitter" "scad"
```


### Scad\_knit:examine\(skein, codeblock, from\_tag\)

```lua
function Scad_knit.examine(scad_knit, skein, codeblock, from_tag)
   return true
end
```


### Scad\_knit:knit\(skein, codeblock, scroll\)

```lua
function Scad_knit.knit(scad_knit, skein, codeblock, scroll)
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
return Scad_knit
```
