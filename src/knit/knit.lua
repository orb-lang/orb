


































































































local Scroll = require "scroll:scroll"
local Set = require "set:set"





local knitters = require "orb:knit/knitters"

-- we need this as long as we have to support both forms, and perhaps not
-- after
local Knitter = require "orb:knit/knitter"

local core = require "core:core"



local Knit = {}
Knit.__index = Knit








local function _haveScroll(skein, code_type)
   -- idempotent decorator
   if skein.knitted[code_type] then
      return skein.knitted[code_type]
   end

   local knitted = skein.knitted
   local scroll = Scroll()
   knitted[code_type] = scroll
   -- #todo this bakes in assumptions we wish to relax
   scroll.line_count = 1
   scroll.path = skein.source.file.path
                    :subFor(skein.source_base,
                            skein.knit_base,
                            code_type)
   return scroll
end




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
   -- specialize the knitter collection and create scrolls for each type
   -- we stop doing this with Knitters.
   local knit_set = Set()
   local new_knitters = {}
   -- no new-type knitters exist yet, but they will.
   for code_type, knitter in pairs(knitters) do
      if not knitter.OLD then
         new_knitters[code_type] = knitter
      end
   end
   for codeblock in doc :select 'codeblock' do
      local code_type = codeblock :select 'code_type'()
      knit_set:insert(knitters[code_type and code_type:span()])
   end
   for knitter, _ in pairs(knit_set) do
      _haveScroll(skein, knitter.code_type)
   end
   for codeblock in doc :select 'codeblock' do
      local code_type = codeblock :select 'code_type'() :span()
      local tagset = skein.tags[codeblock]

      -- this takes over
      for _type, knitter in pairs(new_knitters) do
         if _type == code_type then -- ignore tags, this is temporary
            if knitter:examine(codeblock) then
               local scroll = _haveScroll(skein, code_type)
               knitter:knit(skein, codeblock, scroll)
            end
         end
      end


      if (not tagset) or (not skein.tags[codeblock] 'noKnit') then
         for knitter in pairs(knit_set) do
            if knitter.code_type == code_type and knitter.OLD then
               knitter.knit(codeblock, knitted[code_type], skein)
            end
            if knitter.pred(codeblock, skein) then
               knitter.pred_knit(codeblock, knitted[knitter.code_type], skein)
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

