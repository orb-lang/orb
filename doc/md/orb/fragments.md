# Fragments


  A collection of PEG rules which stand alone, and are added in various places
to proper Grammars.


The first newline in a Lua long string is not included in the body, so these
appear to have an 'extra' newline.

```lua
local fragments = {}
```
```lua
local hashtag_str = [[

   hashtag  <-  "#" symbol
]]

fragments.hashtag = hashtag_str
```
```lua
local handle_str = [[

   handle <- "@" symbol ; this rule may require further elaboration.
]]
fragments.handle = handle_str
```
```lua
local symbol_str = [[

   `symbol`  <-  (([a-z]/[A-Z]) ([a-z]/[A-Z]/[0-9]/"-"/"_")*)
]]
fragments.symbol = symbol_str
```
```lua
return fragments
```