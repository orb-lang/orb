# Deck


  A Deck is a meta\-directory, cross referenced between source, sorcery, and
weaves\.

```lua
local s   = require "status:status" ()
s.verbose = false
s.chatty  = true

local Dir = require "fs:fs/directory"
```

```lua
local new;

local Deck = {}
Deck.__index = Deck
local __Decks = setmetatable({}, { __mode = "kv" })
```


## new\(dir, lume\)

```lua
local function new(dir, lume)
   if type(dir) == "string" then
      dir = Dir(dir)
   end
   s:verb("directory: %s", tostring(dir))
   if __Decks[dir] then
      return __Decks[dir]
   end
   local deck = setmetatable({}, Deck)
   deck.dir = dir
   deck.lume = lume
   deck.files  = {}
   case(deck)
   return deck
end
```


```lua
Deck.idEst = new
return new
```
