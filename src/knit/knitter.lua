








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












Knitter.knit = assert(cluster.ur.NYI)



return new

