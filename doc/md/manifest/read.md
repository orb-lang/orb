\-\- \* Manifest Reader
\-\-
\-\- \#\!lua
\-\- local s ` require "status:status" ()
-- s.verbose ` true
\-\- \#/lua
\-\-
\-\- \#\!lua
\-\- local File ` require "fs:file"
-- local Manifest ` require "orb:manifest/manifest"
\-\- local Skein ` require "orb:skein/skein"
-- #/lua
--
-- #!lua
-- local function read(path) Manifest\(\)
\-\-
--    local manifest `    local mani\_file ` File(path)
--    if mani_file:exists() then
--       s:verb("Found manifest.orb at %s", tostring(mani_file)) true
\-\-
--       manifest.file_exists `       local skein = Skein\(mani\_file\):tailor\(\)
\-\-       manifest\(skein\)
\-\-    else
\-\-       s:verb\("Didn't find a manifest\.orb at %s", tostring\(mani\_file\)\)
\-\-    end
\-\-    return manifest
\-\- end
\-\- \#/lua
\-\-
\-\- \#\!lua
\-\- return read
\-\- \#/lua
