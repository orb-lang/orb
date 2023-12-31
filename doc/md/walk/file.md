# File

The File class is about to undergo an extensive rewrite.


Currently we use ``penlight`` to open and read from files, and we want to
switch to ``luv`` using coroutines and wrappers.


This will give us flexibility down the line and eliminates a dependency which
is duplicated with ``luv`` to a much greater degree of flexibility.


<<<<<<< HEAD
### Tim Caswell's Magnificent Example

This comes from an email exchange we had in 2018:

```lua-example
local function sleep(ms, answer)
  local co = coroutine.running()
  local timer = uv.new_timer()
  timer:start(ms, 0, function ()
    timer:close()
    return coroutine.resume(co, answer)
  end)
  return coroutine.yield()
end

-- Using it would look like:

coroutine.wrap(function ()
  print "Getting answer to everything..."
  local answer = sleep(1000, 42)
  print("Answer is", answer)
end)()
```

So this is the template for converting File over to luv, along with this
recipe from the **uv-cookbook** portion of the documentation:

```lua-example
local uv = require('luv')


local fname = arg[1] and arg[1] or arg[0]

uv.fs_open(fname, 'r', tonumber('644', 8), function(err,fd)
    if err then
        print("error opening file:"..err)
    else
        local stat = uv.fs_fstat(fd)
        local off = 0
        local block = 10

        local function on_read(err,chunk)
            if(err) then
                print("Read error: "..err);
            elseif #chunk==0 then
                uv.fs_close(fd)
            else
                off = block + off
                uv.fs_write(1,chunk,-1,function(err,chunk)
                    if err then
                        print("Write error: "..err)
                    else
                        uv.fs_read(fd, block, off, on_read)
                    end
                end)
            end
        end
        uv.fs_read(fd, block, off, on_read)
    end
end)

uv.run('default')
```
### Goal

The goal is to set up a lazy set of opens and on-reads that attach to the
File object, which can be iterated onto the event loop once it's up and
running.


This is a rather different way of thinking about this interaction than I'm
used to, and this is going to stretch me considerable.
||||||| merged common ancestors
### Tim Caswell's Magnificent Example

This comes from an email exchange we had in 2018:

```lua-example
local function sleep(ms, ...)
  local co = coroutine.running()
  local timer = uv.new_timer()
  timer:start(ms, 0, function ()
    timer:close()
    return coroutine.resume(co, ...)
  end)
  return coroutine.yield()
end

-- Using it would look like:

coroutine.wrap(function ()
  print "Getting answer to everything..."
  local answer = sleep(1000, 42)
  print("Answer is", answer)
end)()
```

So this is the template for converting File over to luv, along with this
recipe from the **uv-cookbook** portion of the documentation:

```lua-example
local uv = require('luv')


local fname = arg[1] and arg[1] or arg[0]

uv.fs_open(fname, 'r', tonumber('644', 8), function(err,fd)
    if err then
        print("error opening file:"..err)
    else
        local stat = uv.fs_fstat(fd)
        local off = 0
        local block = 10

        local function on_read(err,chunk)
            if(err) then
                print("Read error: "..err);
            elseif #chunk==0 then
                uv.fs_close(fd)
            else
                off = block + off
                uv.fs_write(1,chunk,-1,function(err,chunk)
                    if err then
                        print("Write error: "..err)
                    else
                        uv.fs_read(fd, block, off, on_read)
                    end
                end)
            end
        end
        uv.fs_read(fd, block, off, on_read)
    end
end)

uv.run('default')
```
### Goal

The goal is to set up a lazy set of opens and on-reads that attach to the
File object, which can be iterated onto the event loop once it's up and
running.


This is a rather different way of thinking about this interaction than I'm
used to, and this is going to stretch me considerable.
=======
>>>>>>> use-fs-project



```lua
local uv = require "luv"

local Path = require "fs:path"
local lfs = require "lfs"
local pl_mini = require "orb:util/plmini"
local extension, basename = pl_mini.path.extension, pl_mini.path.basename
local isfile = pl_mini.path.isfile
```
```lua
local new
```
```lua
local function __tostring(file)
   return file.path.str
end
```
```lua
local File = {}
local __Files = {}
File.it = require "singletons/check"
```
```lua
function File.parentPath(file)
   return file.path:parentDir()
end
```
```lua
function File.exists(file)
   return isfile(file.path.str)
end
```
```lua
function File.basename(file)
   return basename(file.path.str)
end
```
```lua
function File.extension(file)
   return extension(file.path.str)
end
```
```lua
function File.read(file)
   local f = io.open(file.path.str, "r")
   local content = f:read("*a")
   f:close()
   return content
end
```

The following is crude but maybe good enough for orb.

```lua
function File.write(file, doc)
   local f = io.open(file.path.str, "w")
   f:write(tostring(doc))
   f:close()
end
```
```lua
local FileMeta = { __index = File,
                   __tostring = __tostring}

new = function (file_path)
   local file_str = tostring(file_path)
   -- #nb this is a naive and frankly dangerous guarantee of uniqueness
   -- and is serving in place of something real since filesystems... yeah
   if __Files[file_str] then
      return __Files[file_str]
   end

   local file = setmetatable({}, FileMeta)
   if type(file_path) == "string" then
      file.path = Path(file_path)
   elseif file_path.idEst == Path
      and not file_path.isDir then
      file.path = file_path
   end
   __Files[file_str] = file

   return file
end

```
```lua
File.idEst = new
return new
```
