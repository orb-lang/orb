# Path


Let's make a little Path class that isn't just a string.


They need to be:


-  Immutable. Adding to a path or substituting within it
   produces a new path; a path can't be changed once it's
   established.


-  Stringy.  ``tostring`` gives us the literal string rep of
   the Path, __concat works (but immutably), and so on.


Paths are going to be heavily re-used and extended, first by Directories
and Files, and then we'll want to take a pass a making them grammatical
and extending their properties to the URI class.


## Fields

The array portion of Path tables is entirely strings.


Special characters, notably "/", are represented, by themselves,
as strings.


- Prototype


  -  divider:  The dividing character, ``/`` in all sensible realms.


  -  div_patt:  This is ``%/``, in a quirk of Lua.


  -  parent_dir, same_dir:  Not currently used.


  -  isPath:  Always equal to the Path table.


- Instance


  -  filename:  If present, the name of the file.  This will always be
                ``nil`` for a directory.


  -  isDir:  If ``true``, indicates the Path is structured to be a directory.
        It does **not** indicate that there is a real directory at this path.


  -  str:  The string form of the path.  ``__tostring`` simply returns this,
           it is in-contract to read from this field.  Nothing but Path
           should write to it, which we won't enforce until we can do so
           at compile time.


- [ ] #todo   Check memoized ``__Path`` table during ``__concat``.

```lua
local Path = setmetatable({}, {__index = Path})
local __Paths = {} -- one Path per real Path

local s = require "status" ()
s.angry = false
Path.isPath = Path

Path.it = require "core/check"

Path.divider = "/"
Path.div_patt = "%/"
Path.parent_dir = ".."
Path.same_dir = "."
```
## Methods


## __concat

Concat returns a new path that is the synthesis of either a
string or another path.


- params


  -  head_path:  A Path. Cloned before concatenation.


  -  tail_path:  If a String, this is concatenated.  If the result is
           not a structurally valid string, this is complained about
           and nil is returned.


           If it's another Path, we want to do the right thing, and not
           make developers guess what that might be, so:


           If it's two absolute Paths, then **iff** the tail_path nests in the
           head_path, the tail_path is returned.  So ``"/usr/" .. "/usr/bin/"``
           returns ``"/usr/bin"``.


           If the tail_path is relative, then it's flexibly applied to the
           head_path. For a path that _doesn't_ start with ``.``, ``..``, or ``*``,
           this is simple concatenation.


           Note that ``__concat`` refuses to make "foo//bar" from "foo/"
           and "/bar", and similarly won't make "/foobar" from "/foo" and "bar". Both
           of these will return ``nil``, and the malformed string as the error. #nyi




- return


  - A new Path.


### clone(path)

This returns a copy of the path with the metatable stolen.

```lua
local function clone(path)
  local new_path = {}
  for k,v in pairs(path) do
    new_path[k] = v
  end
  setmetatable(new_path, getmetatable(path))
  return new_path
end

```
### stringAwk

This is used twice, once to build new paths, and once to add to them.

```lua
local function stringAwk(path, str)
  local div, div_patt = Path.divider, Path.div_patt
  local phrase = ""
  local remain = string.sub(str, 2)
  path[1] = div
    -- chew the string like Pac Man
  while remain  do
    local dir_index = string.find(remain, div_patt)
    if dir_index then
      -- add the handle minus div
      path[#path + 1] = string.sub(remain, 1, dir_index - 1)
      -- then the div
      path[#path + 1] = div
      local new_remain = string.sub(remain, dir_index + 1)
      assert(#new_remain < #remain, "remain must decrease")
      remain = new_remain
      if remain == "" then
        remain = nil
      end
    else
      -- file
      path[#path + 1] = remain
      path.filename = remain
      remain = nil
    end
  end
  if not path.filename then
    path.isDir = true
  end

  return path
end
```

- [ ]  #todo add a guard against file-file and dir-dir
       interaction, if this actually happens enough to get
       annoying.

```lua
local function __concat(head_path, tail_path)
  local new_path = clone(head_path)
  if type(tail_path) == 'string' then
    -- use the stringbuilder
    local path_parts = stringAwk({}, tail_path)
    for _, v in ipairs(path_parts) do
      new_path[#new_path + 1] = v
    end

    new_path.str = new_path.str .. tail_path
    if string.sub(new_path.str, -1) == Path.divider then
      new_path.isDir = true
      new_path.filename = nil
    else
      new_path.filename = path_parts.filename
    end

    return new_path
  else
    s:complain("NYI", "can only concatenate string at present")
  end
end
```
## __tostring

Since we always have a path as a string, we simply return it.

```lua
local function __tostring(path)
  return path.str
end
```
### fromString(str)

This is a builder function and hence private.

```lua
local function fromString(path, str)
  local div, div_patt = Path.divider, Path.div_patt
  if string.sub(str, 1, 1) ~= div and not catting then
    local msg = "Paths must be absolute and start with " .. div
    s:complain("validation error", msg)
    return nil, msg
  else
    return stringAwk(path, str, div, div_patt)
  end
end
```
### new

Builds a Path from, currently, a string.


This is the important use case.

```lua
local function new (_, path_seed)
  if __Paths[path_seed] then
    return __Paths[path_seed]
  end
  local path = setmetatable({}, {__index = Path,
                               __concat = __concat,
                               __tostring = __tostring})
  if type(path_seed) == 'string' then
    path.str = path_seed
    path =  fromString(path, path_seed)
  elseif type(path_seed) == 'table' then
    s:complain("NYI", 'construction from a Path or other table is not yet implemented')
  end

  __Paths[path_seed] = path

  return path
end
```
```lua
function Path.spec(path)
  local a = new(_, "/core/build/")
  local b = clone(a)
  local c = a .. "bar/"

  -- new way
  b: it("a Path") : must ("have a path")
     : have "str"
     : equalTo "/core/build/"
     : ofLen(12)
     : have "isPath"
     : equalTo(Path)
     : report()

  a: it(): mustnt()
     : have "brack"
     : have "broil"
     : have "badAttitude"
     : report()
end
```
```lua
return setmetatable({}, {__call = new})
```