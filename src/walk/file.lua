























































































local uv = require "luv"

local Path = require "walk/path"
local lfs = require "lfs"
local pl_mini = require "util/plmini"
local read, write = pl_mini.file.read, pl_mini.file.write
local extension, basename = pl_mini.path.extension, pl_mini.path.basename
local isfile = pl_mini.path.isfile



local new



local function __tostring(file)
   return file.path.str
end




local File = {}
local __Files = {}
File.it = require "kore/check"



function File.parentPath(file)
   return file.path:parentDir()
end



function File.exists(file)
   return isfile(file.path.str)
end



function File.basename(file)
   return basename(file.path.str)
end



function File.extension(file)
   return extension(file.path.str)
end



function File.read(file)
   return read(file.path.str)
end





function File.write(file, doc)
   return write(file.path.str, tostring(doc))
end




local FileMeta = { __index = File,
                   __tostring = __tostring}

new = function (file_path)
   file_str = tostring(file_path)
   -- #nb this is a naive and frankly dangerous guarantee of uniqueness
   -- and is serving in place of something real since filesystems... yeah
   if __Files[file_str] then
      return __Files[file_str]
   end

   local file = setmetatable({}, FileMeta)
   if type(file_path) == "string" then
      file.path = Path(file_path)
   elseif file_path.idEst == Path
      and not file_path.isDir then
      file.path = file_path
   end
   __Files[file_str] = file

   return file
end




File.idEst = new
return new
