# Codeblock


  Inner parser for code blocks.


This is a good example of how we can extract different syntactic information
at different levels.


For example: we know that the last line will be a ``code-end``, so we don't have
to detect a matching number of ``!`` and ``/``, and we don't have to check that
the closing line is flush with the margin, only that it's the final non-blank
line in the block.


In this instance, we're partially working around a limitation of the Lpeg
engine: any capture will reset named captures, so back references don't work
across rule boundaries.


Even if I'm able to fix this, and I have some ideas there, this is still a
good strategy (IMHO) for parsing complex documents.


For example, we might eventually add Lua parsing to Lua code blocks, and so
on for other languages.  This would make for a tediously long definition of
a Doc, and one in which the parsers are less composable.

```lua
local Peg = require "espalier:espalier/peg"
local metafn = require "espalier:espalier/metafn"

local fragments = require "orb:orb/fragments"
```
```lua
local code_str = [[
    codeblock  ←  code-start code-body code-end
   code-start  ←  "#" "!"+ code-type* (!"\n" 1)* "\n"
    code-body  ←  (!code-end 1)+
     code-end  ←  "#" "/"+ code-type*  (!"\n" 1)* line-end
    code-type  ←  symbol
   `line-end`  ←  ("\n\n" "\n"* / "\n")* (-1)
]] .. fragments.symbol
```
```lua
local code_peg = Peg(code_str)
```
```lua
return metafn(code_peg.parse, "code-nomatch")
```