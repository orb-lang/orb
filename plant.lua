local spawn = require "proc:spawn"

local plant = spawn("plantuml", {"-h"})

require "luv" . run 'default'

print(plant:read())

print(plant:err())

print(plant.success, plant.didnotrun)
