











local s = require "status:status" ()






local scad_knit = {OLD = true}



local Scad_knit = require "orb:knit/knitter" "scad"






function Scad_knit.examine(scad_knit, skein, codeblock, from_tag)
   return true
end






function Scad_knit.knit(scad_knit, skein, codeblock, scroll)
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



return Scad_knit

