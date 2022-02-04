









local sh = require "lash:lash"
local Dir = require "fs:directory"
local lines = assert(require "core:core/string" . lines)
local insert = assert(table.insert)


local spawn = require "proc:spawn"

local function gitInfo(path)
   local git_info = {}
   if Dir(path.."/.git"):exists() then
      coroutine.wrap(function()
      git_info.is_repo = true
      git_info.with_spawn = true

      local git_branch = spawn("git", {"branch", cwd = path})
      local branches = assert(git_branch:read())
      for branch in lines(branches) do
         if branch:sub(1,1) == "*" then
            git_info.branch = branch:sub(3)
         end
      end
      local remotes = spawn("git", {"remote", cwd = path}) :read()

      git_info.remotes = {}
      if remotes then
         for remote in lines(remotes) do
            local url = spawn("git", {"remote", "get-url", remote, cwd = path})
                           :read()
            if remote == "origin" then
               git_info.url = url
            end
            insert(git_info.remotes, {remote, url})
         end
         if not git_info.url then
            git_info.url = git_info.remotes[1] and git_info.remotes[1][2]
         end
      end
      git_info.commit_hash = spawn("git", {"rev-parse", "HEAD", cwd = path})
                                :read()
   end)()

   else
      git_info.is_repo = false
   end
   return git_info
end

return gitInfo

