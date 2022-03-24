





local core = require "qor:core"
local Set = assert(core.set)

local s = require "status:status" ()



local Lua_knit = require "orb:knit/knitter" "lua"






Lua_knit.tags = Set {'asLua'}






function Lua_knit.examine()
   return true
end














local format, find, gsub = assert(string.format),
                           assert(string.find),
                           assert(string.gsub)
local L = require "lpeg"

local end_str_P = L.P "]" * L.P "="^0 * L.P "]"

local function _disp(first, last)
   return last - first - 2
end

-- capture an array containing the number of equals signs in each matching
-- long-string close, e.g. "aa]]bbb]=]ccc]==]" returns {0, 1, 2}

local find_str = L.Ct(((-end_str_P * 1)^0
                      * (L.Cp() * end_str_P * L.Cp()) / _disp)^1)

function _pred_knit(codeblock, scroll, skein)
   local name = codeblock:select "name"()
   local codetype = codeblock:select("code_type")():span()
   local header, str_start = "", " = ["
   if name then
      -- stringify and drop "@"
      name = name:select "handle"() :span() :sub(2)
      -- normalize - to _
      name = gsub(name, "%-", "_")
      -- two forms: =local name= or (=name.field=, name[field])
      if not (find(name, "%.") or find(name, "%[")) then
         header = "local "
      end
   elseif codetype ~= "c" then
      local linum = codeblock :select "code_start"() :linePos()
      s:warn("an #asLua block must have a name, line: %d", linum)
      return
   end
   -- special-case #asLua C blocks as ffi.cdef
   -- this allows for a named C code block; the name isn't used here but
   -- can be used to reference the block elsewhere.
   if codetype == "c" then
      header = "ffi.cdef "
      name = ""
      str_start = " ["
   end
   local codebody = codeblock :select "code_body" ()
   local line_start, _ , line_end, _ = codebody:linePos()
   for i = scroll.line_count, line_start - 2 do
      scroll:add "\n"
   end
   -- search for =="]" "="* "]"== in code_body span and add more = if
   -- needful
   local eqs = ""
   local caps = L.match(find_str, codebody:span())
   if caps then
      table.sort(caps)
      eqs = ("="):rep(caps[#caps] + 1)
   end
   header = header .. name .. str_start .. eqs .. "[\n"
   scroll:add(header)
   scroll:add(codebody)
   scroll:add("]" .. eqs .. "]\n")
   scroll.line_count = line_end + 2
end





function Lua_knit.knit(lua_knit, skein, codeblock, scroll)
   local tags = skein.tags[codeblock]
   -- old sets!
   if tags and tags("asLua") then
      _pred_knit(codeblock, scroll, skein)
   else
      local codebody = codeblock :select "code_body" ()
      local line_start, _ , line_end, _ = codebody:linePos()
      for i = scroll.line_count, line_start - 1 do
         scroll:add "\n"
      end
      scroll:add(codebody)
      -- add an extra line and skip 2, to get a newline at EOF
      scroll:add "\n"
      scroll.line_count = line_end + 2
   end
end




return Lua_knit

