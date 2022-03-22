







local s = require "status:status"




local plantUML = {code_type = 'plantuml'}





plantUML.pred = function() return false end
plantUML.knit_pred = function() return end





local spawn;
function plantUML.knit(code_block, scroll, skein)
   spawn = spawn or require "proc:spawn"
   local proc = spawn("plantuml", {"-tSVG"})
   if proc.didnotrun then
      s:warn "plantuml didn't run, is it installed?"
      return
   end
   s:chat "writing plantuml"
   proc:write(code_block :select "code_body" :span())
   scroll:add(proc:read())
end



return plantUML

