# C


  With this addition, Orb finally stretches its legs, and strides forth as a
true polyglot programming language\.

Our current codeblock flavors are Lua, SQL, and PEG\.  But we have no knitters
for SQL and PEG, and we probably won't: they aren't programming languages, in
and of themselves\.

If we include the 
\#asLua
 hashtag, and we normally do, they compile into
Lua long strings\.  This is a nice affordance: we get syntax highlighting,
thereby avoiding the "inner language" effect where any dialect which isn't the
runtime environment has to be treated as a string\.

Also, and this will prove useful for SQL\(ite\) in particular, we can reuse the
codeblocks in other contexts\.  SQLite doesn't care which language you're
calling it from, and we can transclude SQL blocks into another language\.\.\.
once we have a\) transclusion, and b\) other languages\.

Which brings us to C\.  We will have an 
\#asLua
 form for the C language,
which will call `ffi.cdef[[...]]` on the codeblock, so we can have nice syntax
highlighting for the FFI\.  But that's a function proper to the Lua knitter,
and this is the C knitter\.  We're going to special\-case the C knitter to
ignore these, and come up with a general solution as we go\.

Our runtime is written in C, and is the only internal piece of code which
isn't written in Orb\.  It's time to change that, so we need a C knitter\.


#### Interface

Much simpler than it was\.


#### imports

We use the predicator to ignore 
\#asLua
 blocks:

```lua
local c_noknit = require "orb:knit/predicator" "#asLua"
```


## C Knitter

```lua
local C_knit = require "orb:knit/knitter" "c"
```


### C\_knit:examine\(skein, codeblock\)

C code tagged `#asLua` should not be knit\.  In the event that we want to
have it both ways, we'll use an additional tag here

```lua
function C_knit.examine(c_knit, skein, codeblock)
   if c_noknit(codeblock, skein) then
      return false
   else
      return true
   end
end
```


```lua
return C_knit
```
