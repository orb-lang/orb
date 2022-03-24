











local s = require "status:status" ()






local scad_knit = {OLD = true}






scad_knit.code_type = "scad"









local scad_noknit = require "orb:knit/predicator" "#asLua"



scad_knit.pred = function() return false end

scad_knit.knit_pred = function() return end







function scad_knit.knit(codeblock, scroll, skein)
   if scad_noknit(codeblock, skein) then return end
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



return scad_knit

