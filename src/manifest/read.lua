


local s = require "status:status" ()
s.verbose = true



local File = require "fs:file"
local Manifest = require "orb:manifest/manifest"
local Skein = require "orb:skein/skein"



local function read(path)
   local manifest = Manifest()
   local mani_file = File(path)
   if mani_file:exists() then
      s:verb("Found manifest.orb at %s", tostring(mani_file))
      manifest.file_exists = true
      -- this is 800 pounds of gorilla we're bringing for one banana
      local lume = require "orb:lume/lume" (uv.cwd(), nil, true)
      local skein = Skein(mani_file):tailor()
      manifest(Skein(mani_file), lume)
   else
      s:verb("Didn't find a manifest.orb at %s", tostring(mani_file))
   end
   return manifest
end



return read

