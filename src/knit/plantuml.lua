







local s = require "status:status" ()
s.chatty = true




local plantUML = {code_type = 'plantuml', OLD = true}



local PlantUML = require "orb:knit/knitter" "plantuml"





plantUML.pred = function() return false end
plantUML.knit_pred = function() return end





local spawn;
function plantUML.knit(code_block, scroll, skein)
   spawn = spawn or require "proc:spawn"
   local proc = spawn("plantuml", {"-tsvg", "-pipe"})
   if proc.didnotrun then
      s:warn "plantuml didn't run, is it installed?"
      return
   end
   s:verb "writing plantuml"
   proc:write(code_block :select "code_body"() :span())
   local reddit = assert(proc:read(), debug.traceback())
   s:chat(reddit)
   scroll:add(reddit)
   proc:exit() -- we can do better than this
end






function PlantUML.examine()
   return true
end



function PlantUML.knit(plant, skein, codeblock, scroll)
   spawn = spawn or require "proc:spawn"
   local proc = spawn("plantuml", {"-tsvg", "-pipe"})
   if proc.didnotrun then
      s:warn "plantuml didn't run, is it installed?"
      return
   end
   s:verb "writing plantuml"
   proc:write(codeblock :select "code_body"() :span())
   local reddit = assert(proc:read(), debug.traceback())
   s:chat(reddit)
   scroll:add(reddit)
   proc:exit() -- we can do better than this
end



return PlantUML

