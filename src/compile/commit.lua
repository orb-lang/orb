








local s = require "singletons/status"
s.verbose = true
local sql = assert(sql, "must have sql in bridge _G")
local sqltools = require "orb:compile/sqltools"
local Dir = require "orb:walk/directory"
local File = require "orb:walk/file"

local sha = require "compile/sha2" . sha3_512

local status = require "singletons/status" ()



local commit = {}












local new_project = [[
INSERT INTO project (name, repo, repo_alternates, home, website)
VALUES (:name, :repo, :repo_alternates, :home, :website)
;
]]

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

local add_module = [[
INSERT INTO module (snapshot, version, name,
                    branch, vc_hash, project, code)
VALUES (:snapshot, :version, :name, :branch,
        :vc_hash, :project, :code)
;
]]





local update_project_head = [[
UPDATE project
SET
]]

local update_project_foot = [[
WHERE
  name = %s
;
]]

local update_project_params = { repo = 'repo = %s',
                                repo_alternates = 'repo_alternates = %s',
                                home = 'home = %s',
                                website = 'website = %s' }





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








local get_snapshot_version = [[
SELECT CAST (version.version_id AS REAL) FROM version
WHERE version.edition = 'SNAPSHOT'
;
]]

local get_project_id = [[
SELECT CAST (project.project_id AS REAL) FROM project
WHERE project.name = %s
;
]]

local get_project = [[
SELECT * FROM project
WHERE project.name = %s
;
]]

local get_code_id_by_hash = [[
SELECT CAST (code.code_id AS REAL) FROM code
WHERE code.hash = %s;
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
local function commitModule(conn, bytecode, project_id, version_id, git_info)
   -- get code_id from the hash
   local code_id = unwrapKey(conn:exec(sql.format(get_code_id_by_hash,
                                                  bytecode.hash)))
   if not code_id then
      bytecode.binary = blob(bytecode.binary)
      conn:prepare(new_code):bindkv(bytecode):step()
      code_id = unwrapKey(conn:exec(sql.format(get_code_id_by_hash,
                                               bytecode.hash)))
   end
   s:verb("code ID is " .. code_id)
   s:verb("module name is " .. bytecode.name)
   if not code_id then
      error("code_id not found for " .. bytecode.name)
   end
   local mod = { name = bytecode.name,
                 project = project_id,
                 code = code_id,
                 snapshot = version_id,
                 version = version_id }
   if git_info.is_repo then
      mod.vc_hash = git_info.commit_hash
      mod.branch  = git_info.branch
   end
   conn:prepare(add_module):bindkv(mod):step()
end

commit.commitModule = commitModule






local function _newProject(conn, project)
   assert(project.name, "project must have a name")
   project.repo = project.repo or ""
   project.repo_alternates = project.repo_alternates or ""
   project.home = project.home or ""
   project.website = project.website or ""
   conn:prepare(new_project):bindkv(project):step()
   return true
end






local insert, concat = assert(table.insert), assert(table.concat)
local function _updateProjectInfo(conn, db_project, codex_project)
   -- determine if we need to do this
   local update = false
   for k, v in pairs(codex_project) do
      if db_project[k] ~= v then
         update = true
      end
   end
   if update then
      local stmt = {update_project_head}
      local clauses = {}
      for k, v in pairs(codex_project) do
         if update_project_params[k] then
            insert(clauses, sql.format(update_project_params[k], v))
         end
      end
      insert(stmt, concat(clauses, ",\n"))
      insert(stmt, "\n")
      insert(stmt, sql.format(update_project_foot, db_project.name))
      stmt = concat(stmt)
      conn:exec(stmt)
   end
end






function commit.commitCodex(conn, codex)
   local codex_project_info = codex:projectInfo()
   -- begin transaction
   conn:exec "BEGIN TRANSACTION;"
   -- select project_id
   local db_project_info = conn:exec(sql.format(get_project,
                                                codex_project_info.name))
   db_project_info = toRow(db_project_info) or {}
   local project_id = db_project_info.project_id
   if project_id then
      s:verb("project_id is " .. project_id)
      -- update information if there are any changes
      _updateProjectInfo(conn, db_project_info, codex_project_info)
   else
      _newProject(conn, codex_project_info)
      project_id = unwrapKey(conn:exec(sql.format(get_project,
                                                  codex_project_info.name)))
      if not project_id then
         error ("failed to create project " .. codex.project)
      end
   end
   -- if we don't have a specific version, make a snapshot:
   local version_id
   if not codex.version then
      version_id = unwrapKey(conn:exec(get_snapshot_version))
      if not version_id then
         conn : prepare(new_version_snapshot) : bindkv
              { edition = "SNAPSHOT",
                project = codex_project_info.name }
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
   for _, bytecode in pairs(codex.bytecodes) do
      commitModule(conn, bytecode, project_id, version_id, codex.git_info)
   end
   -- commit transaction
   conn:exec "COMMIT;"
   return conn
end




return commit
