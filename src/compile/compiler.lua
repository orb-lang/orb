

















local compiler, compilers = {}, {}
compiler.compilers = compilers






local sha = require "util:sha" . shorthash

local s = require "status:status" ()
s.verbose = false





















local function _moduleName(path, project)
   local mod = {}
   local inMod = false
   for i, v in ipairs(path) do
      if v == project then
         inMod = true
      end
      if inMod then
         if i ~= #path then
            table.insert(mod, v)
          else
             table.insert(mod, path:barename())
         end
      end
   end
   -- drop the bits of the path we won't need
   --- awful kludge fix
   local weird_path = table.concat(mod)
   local good_path = string.gsub(weird_path, "%.%_", "")
   local _, cutpoint = string.find(good_path, "/src/")
   local good_path = string.sub(good_path, cutpoint + 1)
   return good_path
end








function compilers.lua(skein)
   local project = skein.lume.project
   skein.compiled = skein.compiled or {}
   local compiled = skein.compiled
   local path = skein.knitted.lua.path
   local src = skein.knitted.lua
   local mod_name = _moduleName(path, project)
   local bytecode, err = load (tostring(src), "@" .. mod_name)
   if bytecode then
      -- add to srcs
      local byte_str = tostring(src) -- #todo: parse and strip
      local byte_table = {binary = byte_str}
      byte_table.hash = sha(byte_str)
      byte_table.name = mod_name
      byte_table.err = false
      compiled.lua = byte_table
      s:verb("compiled: " .. project .. ":" .. byte_table.name)
   else
      s:chat "error:"
      s:chat(err)
      compiled.lua = { err = err }
   end
end











function compiler.compile(compiler, skein)
   for extension, scroll in pairs(skein.knitted) do
      if compiler.compilers[extension] then
         compiler.compilers[extension](skein)
      end
   end
end



return compiler

