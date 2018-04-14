# Directory


``bridge`` is going to have a certain attitude toward directories.


The ``orb`` directory module will emulate and prototype that attitude.


- [ ] #todo  Add and use raw "lfs" dependency, since we already need it


- [ ] #todo  And this is the wrong place to put it but, phase out penlight.
             All I use is strict and wrappers around ``lfs``.

```lua
local Dir = {}
Dir.isDir = Dir
Dir.it = require "core/check"

local __Dirs = {} -- Cache to keep each Dir unique by Path
```
```lua
local pl_path = require "pl.path" -- Favor lfs directly
local lfs = require "lfs"
local attributes = lfs.attributes
local Path = require "walk/path"
local isdir  = pl_path.isdir
local mkdir = lfs.mkdir
```
### Dir:exists()

```lua
function Dir.exists(dir)
  return isdir(dir.path.str)
end
```
```lua
function Dir.mkdir(dir)
  if dir:exists() then
    return false
  else
    local success, msg, code = mkdir(dir.path.str)
    if success then
      return success
    else
      code = tostring(code)
      s:complain("mkdir failure # " .. code, msg, dir)
      return false
    end
  end
end
```
```lua
function Dir.attributes(dir)
  return attributes(dir.path.str)
end
```
```lua
function new(__, path)
  if __Dirs[path] then
    return __Dirs[path]
  end
  local dir = setmetatable({}, {__index = Dir})
  local path_str = ""
  if path.isPath then
    assert(path.isDir, "fatal: " .. tostring(path) .. " is not a directory")
    dir.path = path
  else
    local new_path = Path(path)
    assert(new_path.isDir, "fatal: " .. tostring(path) .. " is not a directory")
    dir.path = new_path
  end
  __Dirs[path] = dir

  return dir
end
```
```lua
return setmetatable({}, {__call = new, __index = Dir})
```