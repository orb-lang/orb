







































local c_noknit = require "orb:knit/predicator" "#asLua"






local C_knit = require "orb:knit/knitter" "c"









function C_knit.examine(c_knit, skein, codeblock)
   if c_noknit(codeblock, skein) then
      return false
   else
      return true
   end
end




return C_knit

