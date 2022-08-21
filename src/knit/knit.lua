




































































































local s = require "status:status" ()
s.boring = false





local knitters = require "orb:knit/knitters"

-- we need this as long as we have to support both forms, and perhaps not
-- after
local Knitter = require "orb:knit/knitter"

local core = require "core:core"



local Knit = {}
Knit.__index = Knit





local insert = assert(table.insert)

function Knit.knit(knitter, skein)
   local doc = skein.source.doc
   local knitted
   if skein.knitted then
      knitted = skein.knitted
   else
      knitted = {}
      skein.knitted = knitted
   end
   local knitters = knitters

   for codeblock in doc :select 'codeblock' do
      local code_type = codeblock :select 'code_type'() :span()
      local tagset = skein:tagsFor(codeblock)
      if not tagset("noKnit") then
         -- special case asLua blocks, for now
         if tagset("asLua") then
            local scroll = skein:knitScroll(knitters.lua)
            knitters.lua:knit(skein, codeblock, scroll)
         end
         --  #Todo knitters should be able to register tags to look for and the
         --  whole knitter gets a method for examining this

         -- handle #!language with knitters.language
         local knitter = knitters[code_type]
         if knitter then
            s:bore("block of type %s", code_type)
            if knitter:examine(skein, codeblock) then
               local scroll = skein:knitScroll(knitter)
               knitter:knit(skein, codeblock, scroll)
            end
         end
      end
   end
   -- clean up unused scrolls
   for code_type, scroll in pairs(knitted) do
      if #scroll == 0 then
         knitted[code_type] = nil
      end
   end
end



local function new()
   local knitter = setmetatable({}, Knit)

   return knitter
end

Knit.idEst = new



return new

