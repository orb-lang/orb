








local core = require "qor:core"
local cluster = require "cluster:cluster"






local new, Knitter, Knit_M = cluster.genus()











Knitter.code_type = nil













cluster.construct(new, function(_new, knitter, code_type)
   knitter.code_type = code_type
   return knitter
end)





















Knitter.examine = assert(cluster.ur.no)












Knitter.knit = assert(cluster.ur.NYI)

