# Walk module

Contains our filesystem paradigm\.

This will move to `bridge` relatively soon, where we can work out the ways
that bridgetools interact with codex and non\-codex directory systems\.

```lua
local L = require "lpeg"

local s = require "status:status" ()
local a = require "anterm:anterm"
s.chatty = true

local pl_mini = require "orb:util/plmini"
local pl_mini = require "orb:util/plmini"
local read, write, delete = pl_mini.file.read,
                            pl_mini.file.write,
                            pl_mini.file.delete
local getfiles = pl_mini.dir.getfiles
local getdirectories = pl_mini.dir.getdirectories
local makepath = pl_mini.dir.makepath
local extension = pl_mini.path.extension
local dirname = pl_mini.path.dirname
local basename = pl_mini.path.basename
local isdir = pl_mini.path.isdir

local epeg = require "orb:util/epeg"
```

```lua
local Walk = {}
Walk.Path = require "fs:fs/path"
Walk.Dir  = require "fs:fs/directory"
Walk.File = require "fs:fs/file"
Walk.Codex = require "orb:walk/codex"
Walk.writeOnChange = require "orb:walk/ops"
```

```lua
function Walk.strHas(substr, str)
    return L.match(epeg.anyP(substr), str)
end

function Walk.endsWith(substr, str)
    return L.match(L.P(string.reverse(substr)),
        string.reverse(str))
end
```


Finds the last match for a literal substring and replaces it
with `swap`, returning the new string\.

```lua
function Walk.subLastFor(match, swap, str)
   local trs, hctam = string.reverse(str), string.reverse(match)
   local first, last = Walk.strHas(hctam, trs)
   if last then
      -- There is some way to do this without reversing the string twice,
      -- but I can't be arsed to find it. ONE BASED INDEXES ARE A MISTAKE
      return string.reverse(trs:sub(1, first - 1)
          .. string.reverse(swap) .. trs:sub(last, -1))
   else
      s:halt("didn't find an instance of " .. match .. " in string: " .. str)
   end
end
```

```lua
function Walk.writeOnChange(out_file, newest)
    newest = tostring(newest)
    out_file = tostring(out_file)
    local current = read(tostring(out_file))
    -- If the text has changed, write it
    if newest ~= current then
        s:chat(a.green("  - " .. tostring(out_file)))
        write(out_file, newest)
        return true
    -- If the new text is blank, delete the old file
    elseif current ~= "" and newest == "" then
        s:chat(a.red("  - " .. tostring(out_file)))
        delete(out_file)
        return false
    else
    -- Otherwise do nothing

        return nil
    end
end
```


```lua
return Walk
```
