

















local Dir = require "fs:directory"
local File = require "fs:file"
local s = require "status:status"
s.verbose = false

local unwrapKey, toRow = assert(sql.unwrapKey), assert(sql.toRow)






local database = {}
















local new_project = [[
INSERT INTO project (name, repo, repo_alternates, home, website)
VALUES (:name, :repo, :repo_alternates, :home, :website)
;
]]






local get_project = [[
SELECT * FROM project
WHERE project.name = ?
;
]]






local update_project = [[
UPDATE project
SET
   repo = :repo,
   repo_alternates = :repo_alternates,
   home = :home,
   website = :website
WHERE
   name = :name
;
]]









local latest_version = [[
SELECT CAST (version.version_id AS REAL) FROM version
WHERE version.project = ?
ORDER BY major DESC, minor DESC, patch DESC
LIMIT 1
;
]]






local get_version = [[
SELECT CAST (version.version_id AS REAL) FROM version
WHERE version.project = :project
AND version.major = :major
AND version.minor = :minor
AND version.patch = :patch
AND version.edition = :edition
AND version.stage = :stage
;
]]






local new_version_snapshot = [[
INSERT INTO version (edition, project)
VALUES (:edition, :project)
;
]]






local new_version = [[
INSERT INTO version (edition, stage, project, major, minor, patch)
VALUES (:edition, :stage, :project, :major, :minor, :patch)
;
]]



local new_code = [[
INSERT INTO code (hash, binary)
VALUES (:hash, :binary)
;
]]

local new_bundle = [[
INSERT INTO bundle (project, version, time)
VALUES (?, ?, ?)
;
]]

local add_module = [[
INSERT INTO module (version, name, bundle,
                    branch, vc_hash, project, code, time)
VALUES (:version, :name, :bundle,
        :branch, :vc_hash, :project, :code, :time)
;
]]

local get_bundle_id = [[
SELECT CAST (bundle.bundle_id AS REAL) FROM bundle
WHERE bundle.project = ?
ORDER BY time desc limit 1;
]]

local get_code_id_by_hash = [[
SELECT CAST (code.code_id AS REAL) FROM code
WHERE code.hash = :hash;
]]


local get_bytecode = [[
SELECT code.binary FROM code
WHERE code.code_id = %d ;
]]






local insert, concat = assert(table.insert), assert(table.concat)

local function _updateProjectInfo(conn, db_project, codex_project)
   -- determine if we need to do an update
   local update = false
   for k, v in pairs(codex_project) do
      if db_project[k] ~= v then
         update = true
      end
   end
   if update then
      local stmt = conn:prepare(update_project)
      stmt:bindkv(codex_project):step()
   end
end



function database.project(conn, codex_info)
   local db_info = conn:prepare(get_project):bind(codex_info.name):resultset()
   db_info = toRow(db_info) or {}
   local project_id = db_info.project_id
   if project_id then
      s:verb("project_id is " .. project_id)
      -- update information if there are any changes
      _updateProjectInfo(conn, db_info, codex_info)
   else
      conn:prepare(new_project):bindkv(codex_info):step()
      project_id = conn:prepare(get_project):bind(codex_info.name):step()
      if not project_id then
         error ("failed to create project " .. codex.project)
      else
         project_id = project_id[1]
      end
   end
   return project_id
end






function database.version(conn, version_info, project_id)
   local version_id
   if not version_info.is_versioned then
      version_id = conn:prepare(latest_version):bind(project_id):step()
      if not version_id then
         conn : prepare(new_version_snapshot) : bindkv
              { edition = "",
                project = project_id }
              : step()
         version_id = conn:prepare(latest_version):bind(project_id):step()
         if not version_id then
            error "didn't make a SNAPSHOT"
         else
            version_id = version_id[1]
         end
      else
         version_id = version_id[1]
      end
   else
      version_info.project = project_id
      conn:prepare(new_version):bindkv(version_info):step()
      version_id = conn:prepare(get_version):bindkv(version_info):step()
      if not version_id then
         error "failed to create version"
      end
      version_id = version_id[1]
   end
   s:verb("version_id is " .. version_id)
   return version_id
end













local unwrapKey, toRow, blob = sql.unwrapKey, sql.toRow, sql.blob
local function commitModule(stmt, bytecode, project_id, bundle_id,
                            version_id, git_info, now)
   -- get code_id from the hash
   local code_id = unwrapKey(stmt.code_id:bindkv(bytecode):resultset())
   if not code_id then
      bytecode.binary = blob(bytecode.binary)
      stmt.new_code:bindkv(bytecode):step()
      stmt.code_id:reset()
      code_id = unwrapKey(stmt.code_id:bindkv(bytecode):resultset())
   end
   s:verb("code ID is " .. code_id)
   s:verb("module name is " .. bytecode.name)
   if not code_id then
      error("code_id not found for " .. bytecode.name)
   end
   local mod = { name    = bytecode.name,
                 project = project_id,
                 bundle  = bundle_id,
                 code    = code_id,
                 version = version_id,
                 time    = now }
   if git_info.is_repo then
      mod.vc_hash = git_info.commit_hash
      mod.branch  = git_info.branch
   end
   stmt.add_module:bindkv(mod):step()
   for _, st in pairs(stmt) do
      st:reset()
   end
end

database.commitModule = commitModule






local sh = require "lash:lash"
local date = sh.command("date", "-u", '+"%Y-%m-%d %H:%M:%S"')

function database.commitCodex(codex)
   local conn = database.open()
   local now = tostring(date())
   -- begin transaction
   conn:exec "BEGIN TRANSACTION;"
   -- select project_id
   local project_id = database.project(conn, codex:projectInfo())
   -- select or create version_id
   local version_id = database.version(conn, codex:versionInfo(), project_id)
   -- make a bundle
   conn:prepare(new_bundle):bind(project_id, version_id, now):step()
   -- get bundle_id
   local bundle_id = conn:prepare(get_bundle_id):bind(project_id):step()
   if bundle_id then
      bundle_id = bundle_id[1]
   else
      error "didn't retrieve bundle_id"
   end

   -- prepare statements for module insertion
   local stmt = { code_id = conn:prepare(get_code_id_by_hash),
                  new_code = conn:prepare(new_code),
                  add_module = conn:prepare(add_module) }
   for _, bytecode in pairs(codex.bytecodes) do
      commitModule(stmt,
                   bytecode,
                   project_id,
                   bundle_id,
                   version_id,
                   codex.git_info,
                   now)
   end
   -- commit transaction
   conn:exec "COMMIT;"
   -- use a pcall because we get a (harmless) error if the table is locked
   -- by another process:
   pcall(conn.pragma.wal_checkpoint, "0") -- 0 == SQLITE_CHECKPOINT_PASSIVE
   -- set up an idler to close the conn, so that e.g. busy
   -- exceptions don't blow up the hook
   local close_idler = uv.new_idle()
   close_idler:start(function()
      local success = pcall(conn.close, conn)
      if not success then
        return nil
      else
        close_idler:stop()
        uv.stop()
      end
   end)
   if not uv.loop_alive() then
      uv.run "default"
   end
end




return database
