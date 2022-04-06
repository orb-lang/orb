


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
      local skein = Skein(mani_file):tailor()
      manifest(skein)
   else
      s:verb("Didn't find a manifest.orb at %s", tostring(mani_file))
   end
   return manifest
end



return read

