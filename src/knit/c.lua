

































































local c_noknit = require "orb:knit/predicator" "#asLua"






local C_knit = require "orb:knit/knitter" "c"









function C_knit.examine(c_knit, skein, codeblock)
   if c_noknit(codeblock, skein) then
      return false
   else
      return true
   end
end







function C_knit.knit(c_knit, skein, codeblock, scroll)
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



return C_knit

