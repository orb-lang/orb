













































































































local s = require "status:status" ()
local a = require "anterm:anterm"
s.chatty = true
s.angry = false



local Doc      = require "orb:orb/doc"
local knitter  = require "orb:knit/knit" ()
local compiler = require "orb:compile/compiler"
local database = require "orb:compile/database"
local Manifest; -- optional load which would otherwise be circular

local File   = require "fs:fs/file"
local Path   = require "fs:fs/path"
local Scroll = require "scroll:scroll"
local Notary = require "status:annotate"



local Skein = {}
Skein.__index = Skein





































function Skein.load(skein)
   local file = assert(skein.source.file, "no file on skein")
   -- fix the rest of green/autothread/etc and let this yield ffs
   if file.fs2file then
      -- suuuuper cheating
   end
   local ok, text = pcall(file.read, file)
   if ok then
      skein.source.text = text
   else
      skein.source.cant_load = true
      skein.source.load_err = text
      s:complain("fail on load %s: %s", tostring(file), text)
   end
   return skein
end












function Skein.filter(skein)
   if not skein.source.text then
      skein:load()
   end
   return skein
end











function Skein.spin(skein)
   if not skein.source.text then
      skein:load()
   end
   local ok, doc = pcall(Doc, skein.source.text)
   if not ok then
       s:complain("couldn't make doc: %s, %s", doc, tostring(skein.source.file))
   end
   skein.source.doc = doc
   return skein
end










Skein.tag = require "orb:tag/tagger"











function Skein.tagAct(skein)
   if not skein.tags then
      skein:tag()
   end
   -- this will most likely turn into a table because tag actions are a /very/
   -- complex stage.
   skein.tag_acted = true
   local mani_blocks = skein.tags.manifest
   if mani_blocks then
      Manifest = require "orb:manifest/manifest"
      s:chat("found manifest blocks in %s", tostring(skein.source.file))
      skein.manifest = skein.manifest and skein.manifest:child() or Manifest()
      for _, block in ipairs(mani_blocks) do
         s:verb("attempted add of node type %s", block.id)
         skein.manifest(block)
      end
   end
   return skein
end








function Skein.format(skein)
   return skein
end










local orbScry;



local with_scry = require "bridge" . args . scry
function Skein.knit(skein)
   if not skein.tag_acted then
      skein:tagAct()
   end
   local ok, err = xpcall(knitter.knit, debug.traceback, knitter, skein)
   if not ok then
      s:warn("failure to knit %s: %s", tostring(skein.source.file), err)
   end
   -- this used to be a de-facto error but no longer is
   if not skein.knitted.lua then
      s:verb("no Lua document produced from %s", tostring(skein.source.file))
   elseif with_scry then
      orbScry = orbScry or require "scry:orb-scry"
      orbScry(skein)
   end
   return skein
end





















function Skein.weave(skein)
   if not skein.knitted then
      skein:knit()
   end
   if not skein.woven then
      skein.woven = {}
   end
   local woven = skein.woven
   woven.md = {}
   local ok, err = pcall(function()
      local scroll = Scroll()
      skein.source.doc:toMarkdown(scroll, skein)
      local ok = scroll:deferResolve()
      if not ok then
         scroll.not_resolved = true
      end
      woven.md.text = tostring(scroll)
      woven.md.scroll = scroll
      -- report errors, if any
      for _, err in ipairs(scroll.errors) do
         s:warn(tostring(skein.source.file) .. ": " .. err)
      end
      -- again, this bakes in the assumption of 'codex normal form', which we
      -- need to relax, eventually.
      woven.md.path = skein.source.file.path
                          :subFor(skein.source_base,
                                  skein.weave_base .. "/md",
                                  "md")
   end)
   if not ok then
      s:complain("couldn't weave %s: %s", tostring(skein.source.file), err)
   end
   return skein
end















function Skein.compile(skein)
   if not skein.knitted then skein:knit() end

   compiler:compile(skein)
   return skein
end















function Skein.tailor(skein)
   if not skein.compiled then skein:compile() end

   return skein
end



























local commitSkein = assert(database.commitSkein)

function Skein.commit(skein, stmts, ids, git_info, now)
   if not skein.compiled then skein:compile() end
   assert(stmts)
   assert(ids)
   assert(git_info)
   assert(now)
   commitSkein(skein, stmts, ids, git_info, now)
   return skein
end








function Skein.forModuleDatabase(skein)
   local artifacts = skein.compiled and skein.compiled.lua
   return { bytecode = artifacts,
            name = tostring(skein.source.file) }
end













function Skein.transact(skein, stmts, ids, git_info, now)
   assert(stmts)
   assert(ids)
   assert(git_info)
   skein.lume.db.begin()
   commitSkein(skein, stmts, ids, git_info, now)
   skein.lume.db.commit()
   return skein
end














local function writeOnChange(scroll, path, dont_write)
   -- if we don't have a path, there's nothing to be done
   -- #todo we should probably take some note of this situation
   if not path then return end
   local current = File(path):read()
   local newest = tostring(scroll)
   if newest ~= current then
      s:chat(a.green("    - " .. tostring(path)))
      if not dont_write then
         File(path):write(newest)
      end
      return true
   else
   -- Otherwise do nothing
      return nil
   end
end



function Skein.persist(skein)
   for code_type, scroll in pairs(skein.knitted) do
      if scroll.idEst == Scroll then
         writeOnChange(scroll, scroll.path, skein.no_write)
      else -- a case, soon

      end
   end
   local md = skein.woven.md
   if md then
      writeOnChange(md.text, md.path, skein.no_write)
   end
   return skein
end











function Skein.transform(skein)
   local db = skein.lume.db
   skein
     : load()
     : filter()
     : spin()
     : tag()
     : tagAct()
     : knit()
     : weave()
     : compile()
     : transact(db.stmts, db.ids, db.git_info, skein.lume:now())
     : persist()
   return skein
end
































local empty_set = require "set:set" ()

function Skein.tagsFor(skein, node)
   local tags = assert(skein.tags, "Skein has not been tagged")
   return tags[node] or empty_set
end











function Skein.knitScroll(skein, knitter)
   local code_type, knitted = knitter.code_type, skein.knitted
   -- Right now we always return the same value
   if knitted[code_type] then
      return knitted[code_type]
   end
   -- Adding custom "scrolls"
   if knitter.customScroll then
      local scroll = knitter:customScroll()
      knitted[knitter.code_type] = scroll
      return scroll
   end
   -- We do additional setup which customScroll is expected to handle
   local scroll = Scroll()
   knitted[code_type] = scroll
   scroll.line_count = 1
   -- #todo this bakes in assumptions we wish to relax
   scroll.path = skein:knitPathFor(code_type)
   return scroll
end








function Skein.knitPathFor(skein, code_type)
   return skein.source.file.path
                    :subFor(skein.source_base,
                            skein.knit_base,
                            code_type)
end















local function new(path, lume)
   local skein = setmetatable({}, Skein)
   skein.note = Notary()
   skein.source = {}
   if not path then
      error "Skein must be constructed with a path"
   end

   local file;
   local path_t = type(path)
   if path_t == 'table' and path.fs2file then
      -- we cheat
      file = path
      skein.an_fs2File = true
   -- handles: string, Path, or File objects
   elseif path_t == 'string' or path.idEst ~= File then
      file = File(Path(path):absPath())
   else
      file = path
   end
   if lume then
      skein.lume = lume
      -- lift info off the lume here
      skein.project     = lume.project
      skein.source_base = lume.orb
      skein.knit_base   = lume.src
      skein.weave_base  = lume.doc
      skein.manifest    = lume.manifest
      if lume.no_write then
         skein.no_write = true
      end
   end

   skein.source.relpath = Path(tostring(path)):relPath(skein.source_base)
   skein.source.file = file
   return skein
end

Skein.idEst = new




return new

