

































































local meta = require "core:core/cluster" . Meta
local s = require "status:status" ()
s.verbose = true
s.boring = false

local Skein = require "orb:skein/skein"

local Toml = require "lon:loml"






local Manifest = meta {}





local function _addTable(manifest, tab)
   for k,v in pairs(tab) do
      s:verb("adding %s : %s", k, v)
      if type(v) == 'table' and manifest[k] ~= nil then
         _addTable(manifest[k], v)
      else
         manifest[k] = v
      end
   end
end

local function _addNode(manifest, block)
   -- quick sanity check
   assert(block and block.isNode, "manifest() must receive a Node")
   -- codeblocks are all we know (for now)
   if not (block.id == 'codeblock')then
      s:verb("found a %s node tagged with #manifest, no action", block.id)
      return
   end
   -- toml is all we speak (for now)
   local code_type = block :select 'code_type' () :span()
   if code_type ~= 'toml' then
      s:chat("don't know what to do with a %s codeblock tagged with #manifest",
             code_type)
      return
   end

   local codebody = block :select 'code_body' () :span()
   local toml = Toml(codebody)
   if toml then
      s:verb("adding contents of manifest codebody")
      local contents = toml:toTable()
      _addTable(manifest, contents)
   else
       s:warn("no contents generated from #manifest block, line %d",
              block:linePos())
   end
end



local function _addSkein(manifest, skein)
   -- check if the Skein has been loaded and spun (probably not)
   if (not skein.source.text) or (not skein.source.doc) then
      skein:load():spin():tag()
   end
   local nodes = skein.tags.manifest
   if nodes then
      for _, block in ipairs(nodes) do
         if block.id == 'codeblock' then
            s:verb "adding codeblock from Skein"
            _addNode(manifest, block)
         else
            s:verb("don't know what to do with a %s tagged "
                   .. "with #manifest", block.id)
         end
      end
   else
      s:verb("no manifest blocks found in %s" .. tostring(skein.source.file))
   end
end



function Manifest.child(manifest)
   return setmetatable({}, { __index = getmetatable(manifest),
                             __call  = Manifest.__call })
end




local function _call(manifest, msg)
   s:bore "entering manifest()"
   if not type(msg) == 'table' then
      s:warn("oopsie in manifest of type %s", type(msg))
      return
   end
   --assert(type(msg)  == 'table', "argument to manifest must be a table")
   -- otherwise this should be a codeblock or a Skein
   if msg.idEst and msg.idEst == Skein then
      s:bore("manifest was given a skein")
      _addSkein(manifest, msg)
   elseif msg.isNode then
      s:bore("manifest was given a node")
      _addNode(manifest, msg)
   else
      s:warn("manifest given something weird, type %s", type(msg))
   end
   s:bore "leaving manifest()"
end

Manifest.__call = _call





local function new(block)
   local manifest = meta(Manifest)
   if block then
      _call(manifest, block)
   end
   return manifest
end

Manifest.idEst = new



return new

