# Manifest Reader

```lua
local s = require "status:status" ()
s.verbose = true
```

```lua
local File = require "fs:file"
local Manifest = require "orb:manifest/manifest"
local Skein = require "orb:skein/skein"
```

```lua
local function read(path)
   local manifest = Manifest()
   local mani_file = File(path)
   if mani_file:exists() then
      s:verb("Found manifest.orb at %s", tostring(mani_file))
      manifest(Skein(mani_file))
   else
      s:verb("Didn't find a manifest.orb at %s", tostring(mani_file))
   end
   return manifest
end
```

```lua
return read
```
