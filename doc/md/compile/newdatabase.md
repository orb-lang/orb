# \(new\) Database


A module for controlling the `bridge.modules` database\.


##### "new" Database?

  As we've done for several modules, we're going to reuse the same name once
we've safely laid the old code to rest\.

Which we're tantalizingly close to doing\! This is actually the last major step,
right here\.


#### imports

```lua
local Dir = require "fs:fs/directory"
local File = require "fs:fs/file"
local s = require "status:status"
s.verbose = false

local unwrapKey, toRow = assert(sql.unwrapKey), assert(sql.toRow)
```


## database library

```lua
local database = {}
```

## SQL


### CREATE

We create the modules database [in pylon](@pylon:modules)\.


### project


#### new\_project

```sql
INSERT INTO project (name, repo, repo_alternates, home, website)
VALUES (:name, :repo, :repo_alternates, :home, :website)
;
```


#### get\_project

```sql
SELECT * FROM project
WHERE project.name = ?
;
```


#### update\_project

```sql
UPDATE project
SET
   repo = :repo,
   repo_alternates = :repo_alternates,
   home = :home,
   website = :website
WHERE
   name = :name
;
```


### version


#### latest\_version

```sql
SELECT CAST (version.version_id AS REAL) FROM version
WHERE version.project = ?
ORDER BY major DESC, minor DESC, patch DESC
LIMIT 1
;
```


#### get\_version

```sql
SELECT CAST (version.version_id AS REAL) FROM version
WHERE version.project = :project
AND version.major = :major
AND version.minor = :minor
AND version.patch = :patch
AND version.edition = :edition
AND version.stage = :stage
;
```


#### new\_version\_snapshot

```sql
INSERT INTO version (edition, project)
VALUES (:edition, :project)
;
```


#### new\_version

```sql
INSERT INTO version (edition, stage, project, major, minor, patch)
VALUES (:edition, :stage, :project, :major, :minor, :patch)
;
```

```sql
INSERT INTO code (hash, binary)
VALUES (:hash, :binary)
;
```

```sql
INSERT INTO bundle (project, version, time)
VALUES (?, ?, ?)
;
```

```sql
INSERT INTO module (version, name, bundle,
                    branch, vc_hash, project, code, time)
VALUES (:version, :name, :bundle,
        :branch, :vc_hash, :project, :code, :time)
;
```

```sql
SELECT CAST (bundle.bundle_id AS REAL) FROM bundle
WHERE bundle.project = ?
ORDER BY time desc limit 1;
```

```sql
SELECT CAST (code.code_id AS REAL) FROM code
WHERE code.hash = :hash;
```

```sql
SELECT code.binary FROM code
WHERE code.code_id = %d ;
```


### database\.project\(stmt, project\_info\)

```lua
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
```

```lua
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
```


### database\.version\(conn, version\_info, project\_id\)

```lua
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
```


### database\.commitSkein\(skein, stmts, ids, git\_info, now\)

Commits a single module and associated bytecode\.

This is currently specialized around lua, for the simple reason that we only
compile lua\.  Plenty of time to rewrite this if and when that's no longer
true\.

```lua
local unwrapKey, toRow, blob = sql.unwrapKey, sql.toRow, sql.blob

function database.commitSkein(skein, stmts, ids, git_info, now)
   local bytecode = skein.compiled and skein.compiled.lua
   if not bytecode or bytecode.err then
      local err = bytecode and bytecode.err
      if err then
        s:complain("attempt to commit erroneous bytecode data: %s, %s",
               tostring(skein.source.file), err)
        return nil, err
      end
      -- missing bytecode means the Doc didn't create a knitted.lua, which
      -- is normal
      return nil
   end
   local project_id, version_id, bundle_id = ids.project_id,
                                             ids.version_id,
                                             ids.bundle_id
   -- get code_id from the hash
   local code_id = unwrapKey(stmts.code_id:bindkv(bytecode):resultset('i'))
   if not code_id then
      bytecode.binary = blob(bytecode.binary)
      stmts.new_code:bindkv(bytecode):step()
      stmts.code_id:reset()
      code_id = unwrapKey(stmts.code_id:bindkv(bytecode):resultset('i'))
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
   stmts.add_module:bindkv(mod):step()
   for _, st in pairs(stmts) do
      st:clearbind():reset()
   end
end
```


### database\.commitBundle\(lume\)

Commits all project\-level information, and prepares ids and statements for
use by `commitSkein`\.

Returns `stmts, ids, now`\.  The actual transaction is begun and ended in the
Lume\.


```lua
function database.commitBundle(lume)
   local conn = lume.conn or s:halt("no database conn on the Lume")
   local now = lume:now()
   -- select project_id
   local project_id = database.project(conn, lume:projectInfo())
   -- select or create version_id
   local version_id = database.version(conn, lume:versionInfo(), project_id)
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
   local stmts = { code_id = conn:prepare(get_code_id_by_hash),
                   new_code = conn:prepare(new_code),
                   add_module = conn:prepare(add_module) }
   -- wrap ids
   local ids = { project_id = project_id,
                 version_id = version_id,
                 bundle_id  = bundle_id }
   return stmts, ids, now
end
```


```lua
return database
```


