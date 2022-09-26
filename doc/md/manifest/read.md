\-\- \* Manifest Reader
\-\-
\-\- \#\!lua
\-\- local s ` require "status:status" ()
-- s.verbose ` true
\-\- \#/lua
\-\-
\-\- \#\!lua

\-\- local Manifest ` require "orb:manifest/manifest" require "orb:skein/skein"
\-\-
-- local Skein ` \#/lua
\-\-
\-\- \#\!lua
\-\- local function read\(path\)
\-\-    local manifest ` Manifest() File\(path\)
\-\-
--    local mani_file `    if mani\_file:exists\(\) then
\-\-       s:verb\("Found manifest\.orb at %s", tostring\(mani\_file\)\)
\-\-       manifest\.file\_exists ` true Skein\(mani\_file\):tailor\(\)
\-\-
--       local skein `       manifest\(skein\)
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
