







local s = require "status:status" ()
s.chatty = true



local PlantUML = require "orb:knit/knitter" "plantuml"









function PlantUML.examine()
   return true
end



local spawn;

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

