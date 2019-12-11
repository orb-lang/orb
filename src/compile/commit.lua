








local s = require "singletons/status"
s.verbose = false
local sql = assert(sql, "must have sql in bridge _G")
local Dir = require "orb:walk/directory"
local File = require "orb:walk/file"
local uv  = require "luv"
local sha = require "compile/sha2" . sha3_512
local database = require "orb:compile/database"



local commit = {}












local new_code = [[
INSERT INTO code (hash, binary)
VALUES (:hash, :binary)
;
]]

local new_version_snapshot = [[
INSERT INTO version (edition, project)
VALUES (:edition, :project)
;
]]

local new_version = [[
INSERT INTO version (edition, project, major, minor, patch)
VALUES (:edition, :project, :major, :minor, :patch)
;
]]

-- #todo add timestamp
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

local get_snapshot_version = [[
SELECT CAST (version.version_id AS REAL) FROM version
WHERE version.edition = 'SNAPSHOT'
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

local get_latest_module_code_id = [[
SELECT CAST (module.code AS REAL) FROM module
WHERE module.project = %d
   AND module.name = %s
ORDER BY module.time DESC LIMIT 1;
]]

local get_all_module_ids = [[
SELECT CAST (module.code AS REAL),
       CAST (module.project AS REAL)
FROM module
WHERE module.name = %s
ORDER BY module.time DESC;
]]

local get_latest_module_bytecode = [[
SELECT code.binary FROM code
WHERE code.code_id = %d ;
]]



local get_code_id_for_module_project = [[
SELECT
   CAST (module.code_id AS REAL) FROM module
WHERE module.project_id = %d
   AND module.name = %s
ORDER BY module.time DESC LIMIT 1;
]]

local get_bytecode = [[
SELECT code.binary FROM code
WHERE code.code_id = %d ;
]]







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

commit.commitModule = commitModule






local sh = require "orb:util/sh"
local date = sh.command("date", "-u", '+"%Y-%m-%dT%H:%M:%SZ"')

function commit.commitCodex(codex)
   local conn = database.open()
   local now = tostring(date())
   -- begin transaction
   conn:exec "BEGIN TRANSACTION;"
   -- select project_id
   local project_id = database.project(conn, codex:projectInfo())
   -- if we don't have a specific version, make a snapshot:
   local version_id
   if not codex.version then
      version_id = unwrapKey(conn:exec(get_snapshot_version))
      if not version_id then
         conn : prepare(new_version_snapshot) : bindkv
              { edition = "SNAPSHOT",
                project = project_id }
              : step()
         version_id = unwrapKey(conn:exec(get_snapshot_version))
         if not version_id then
            error "didn't make a SNAPSHOT"
         end
      end
   else
      -- Add a version insert here
   end
   s:verb("version_id is " .. version_id)
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
                  add_module = conn:prepare(add_module)}
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
   -- The below is a good idea but caused a 'database table is locked'
   -- error:
   -- conn.pragma.wal_checkpoint "0" -- 0 == SQLITE_CHECKPOINT_PASSIVE
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




return commit
