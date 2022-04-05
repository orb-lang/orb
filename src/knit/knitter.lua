








local core = require "qor:core"
local cluster = require "cluster:cluster"






local new, Knitter, Knit_M = cluster.genus()




















Knitter.code_type = nil












Knitter.tags = {}


















cluster.construct(new, function(_new, knitter, code_type)
   assert(type(code_type) == 'string', "#1 must be a string")
   knitter.code_type = code_type
   return knitter
end)
























Knitter.examine = assert(cluster.ur.no)




























function Knitter.knit(knitter, skein, codeblock, scroll)
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



return new

