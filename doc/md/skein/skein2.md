# Skein


  A skein is an object for holding a Doc, with all its derivative works\.

The first toolchain was a bootstrap, which was accomplished by the simple
expedient of perfect uniformity\.  Every file in the `orb` directory of a
project was presumed to have some Lua in it, and there is a one\-to\-one
correspondence between `orb` on the one hand, and `src` on the other, same
for the weave\.  Every line of Lua is found in the same place as it is in the
Orb file, and so on\.

This was a useful paradigm, but now we have the new parser, and we need to
walk back some of those design choices\.  The Orb files must remain the source
of truth, but everything else changes: Orb files may affect each other, mutate
themselves and each other, both in ways which are written to disk and ways
which are not, and may generate multiple artifacts of the same sort; or one
Orb document may be a source of code in a knit or weave derived ultimately
from another\.

We took this general\-to\-specific approach to the extreme where compilation in
the old method is all\-or\-nothing\.  We briefly had the ability to knit \(but not
weave\) a single document, but surrendered it\.

Now we'll build from a single file outward\.  We keep the semi\-literate style
for now, but make a single skein capable of everything that needs: parsing,
formatting, spinning, knitting, weaving, and writing all changes to both the
filesystem and the module database\.

Then we'll rebuild the Codex, with as few of the old assumptions as possible\.
In particular, we'll leave out Decks at first, and add them back if they
actually prove useful, which they might\.  That gets us to feature\-parity with
the old compiler, which we may then remove\.

With careful engineering, this will put us in a position for Docs to be
dependent on other Docs, which we can resolve with inter\-skein communication\.


## Instance fields

These are successively created and manipulated over the course of actions
taken on the skein\.


- lume:  A skein carrys a reference to its enclosing lume, which is
    necessary to enable more complex kinds of inter\-document activity\.

    \#Todo this needs to be more flexible and general\.  The Lume, as
    written, requires a codex\-normal directory structure, has completely
    walked it, has hooks into the `bridge.modules` database, and so on\.
    This needs to be appropriately generalized\.


- note:  Annotations left by various operations\.  Like a printf that the Skein
    carries with it\.


- source:  The artifacts of the source file:

  - file:  The Path of the original document\.

  - text:  String representing the contents of the document file\.

  - doc:  The Doc node corresponding to the parsed source doc\.

  - modified:  \#NYI, a flag to mark if the source document itself has been
      modified and needs to be written to disk\.


- knitted:  The artifacts produced by knitting the source\.  Currently, this is
    a key\-value map, where the key is the `code_type` field and the
    value is a Scroll\.


- woven:  The artifacts produced by weaving the source\.

  - md:  The Markdown weave of the source document\.

  - \#Todo:

    - html:  An HTML weave of the source document\.

    - dot:  A [graphviz file](https://www.graphviz.org/doc/info/lang.html)
        of the Doc's Node structure\.

    - pdf:  Just kidding\! Unless\.\.\.

    - latex:  Same, basically

    - pandoc:  I mean, maybe?


- bytecode:  Perhaps a misnomer; this is best defined as artifacts produced by
    further compilation of the knit, suitable for writing to the
    modules database or otherwise using in executable form\.

    For the core bridge modules, this is LuaJIT bytecode, but in
    other cases it could be object code, or a \.jar file, minified JS,
    and the like\.


- completions:  \#NYI\.  These are closures with the necessary information to
    provide the parameters needed to complete them\. An example
    would be a transclusion or macroexpansion which draws from a
    namespace that isn't in the source file\.

    This is the only approach which generalizes across projects,
    and across compilation scenarios:  We want, at the limit, to
    be able to process a single source file, while opening and
    processing only those additional files needed to complete its
    cycle\.


#### imports

```lua
local s = require "status:status" ()
local a = require "anterm:anterm"
s.chatty = true
s.angry = false
```

```lua
local Doc      = require "orb:orb/doc2"
local knitter  = require "orb:knit/knit" ()
local compiler = require "orb:compile/compiler"
local database = require "orb:compile/database"
local Manifest; -- optional load which would otherwise be circular

local File   = require "fs:fs/file"
local Path   = require "fs:fs/path"
local Scroll = require "scroll:scroll"
local Notary = require "status:annotate"
```

```lua
local Skein = {}
Skein.__index = Skein
```


## Skein Stage Methods

  Skeins are in the chaining style: all methods return the skein at the
bottom\. If additional return values become necessary, they may be supplied
after\.

The methods in this section are the basic stages of the Orb tailoring process,
and are presented in order\.  Calling any later stage method should
automatically trigger all missing stages, failure to do so is a bug\.

This offers a chance to optimize with caching \(although we don't yet\), and
makes using Skeins in the helm repl less tedious\.

The stage methods should be idempotent if the Skein doesn't have reason to
perform them a second time, but they aren't\.

The state created and manipulated by method calls is attached to the skein
itself, all stage methods return only the Skein, and either handle errors
internally or throw them\.


#### Next Steps With Stage Methods

  We don't use parameters in most stage methods at all, and


### Skein:load\(\)

This loads the Path data into the `skein.source.text` field\.

If called inside a coroutine and uv event loop, this uses a callback, allowing
us to employ the threadpool for parallelizing the syscall and read penalty\.

```lua
function Skein.load(skein)
   local file = assert(skein.source.file, "no file on skein")
   local ok, text = pcall(file.read, file)
   if ok then
      skein.source.text = text
   else
      s:complain("fail on load %s: %s", tostring(file), text)
   end
   return skein
end
```


### Skein:filter\(\)

Optional step which mostly replaces tabs in the non\-codeblock portions of the
text\.  Any changes will flip the `modified` flag\.

Currently a no\-op\.


```lua
function Skein.filter(skein)
   if not skein.source.text then
      skein:load()
   end
   return skein
end
```


### Skein:spin\(\)

This spins the textual source into a parsed document\.

It will eventually perform some amount of post\-processing as well, such as
in\-place expansion of notebook\-style live documents\.

```lua
function Skein.spin(skein)
   if not skein.source.text then
      skein:filter()
   end
   local ok, doc = pcall(Doc, skein.source.text)
   if not ok then
       s:complain("couldn't make doc: %s, %s", doc, tostring(skein.source.file))
   end
   skein.source.doc = doc
   return skein
end
```


### Skein:tag\(\)

This one is immodestly complex, and gets implemented in its own module\.

This is called within `:spin`\.

```lua
Skein.tag = require "orb:tag/tagger"
```


### Skein:tagAct\(\)

Actions taken as part of the `:spin` which are made possible by tagging\.

Right now, this is checking for a \#manifest codeblock, instantiating a new
instance of the Manifest, and adding the contents\.

```lua
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
```


### Skein:format\(\)

\#NYI

```lua
function Skein.format(skein)
   return skein
end
```


### Skein:knit\(\)

Produces sorcery, derived 'source code' in the more usual sense\.

Referred to as a 'tangle' in the traditional literate coding style\.

```lua
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
   end
   return skein
end
```


### Skein:weave\(\)

This produces derived human\-readable documents from the source\.

We currently produce only Markdown, and as such, there isn't a Weaver instance,
instead, we simply do everything inside the method\.

The roadmap will favor HTML as the first\-class output format\.

This will probably take parameters to specify subcategories of possible
documents; by default, it will produce all the rendered formats it is capable
of producing\.

Eventually, `weaver:weave(skein)` should be the entire method for
`Skein:weave()`, and Scroll will be a dependency of that module, not of Skein
itself\.

```lua
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
```


### Skein:compile\(\)

Takes a knitted Skein and compiles the Scroll if it knows how\.

"Compile" in this case means: check for syntax errors, and render into a form
suitable for persistance into the database, and/or further processing\.

It's unclear what this stage will look like for, in particular, C files; it's
perfectly clear what it looks like for our default, semi\-literate golden path
for Lua artifacts, so we'll start there\.

```lua
function Skein.compile(skein)
   if not skein.knitted then skein:knit() end

   compiler:compile(skein)
   return skein
end
```


### Skein:tailor\(\)

Do every operation on the Skein of which the skein is capable\.

This is currently a no\-op if `:compile` has been called, but probably won't
stay that way\.  The API guarantee is that all the stage methods will be
called if `:tailor` is sent, no matter what particular order and
intermediates might exist\.

We unroll the methods in the Lume, currently, but this is mostly didactic\.

```lua
function Skein.tailor(skein)
   if not skein.compiled then skein:compile() end

   return skein
end
```


## Output Methods

These put various skein contents into databases or the file system\.

This was an expedient way to code the logic, but I don't like that we hand in
a control surface for the database and have the Skein work on itself, I would
prefer a method which provides a commit\-ready table which the Lume could take
action on\.

Similarly, and worse, Skeins are carrying around a whole Lume so they can
write themselves to the file system\.  Skeins should know where things are
*supposed* to go, and should provide the strings and expected locations for
the files with a method\.

The more I think about it, the less I like Skeins writing to the file system\.
I'm not even sure they should be *reading* from it, but one step at a time\.


### Skein:commit\(stmts\)

This commits modules to the database, provided with a collection of prepared
statements sufficient to complete the operation\.

```lua
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
```


### Skein:forModuleDatabase\(\)

Produces a table intended for committing to the module database\.

```lua
function Skein.forModuleDatabase(skein)
   local artifacts = skein.compiled and skein.compiled.lua
   return { bytecode = artifacts,
            name = tostring(skein.source.file) }
end
```


### Skein:transact\(stmts\)

This calls `:commit` inside a transaction, for use in file\-watcher mode and
any other context where the commit itself is a full transaction\.

Necessary because the module and code are written out separately\.

`now` is an optional field, which is provided by the database if left out\.

```lua
function Skein.transact(skein, stmts, ids, git_info, now)
   assert(stmts)
   assert(ids)
   assert(git_info)
   skein.lume.db.begin()
   commitSkein(skein, stmts, ids, git_info, now)
   skein.lume.db.commit()
   return skein
end
```


### Skein:persist\(\)

Writes derived documents out to the appropriate areas of the filesystem\.


#### writeOnChange\(scroll, dont\_write\)

Compares the new file with the old one\. If there's a change, prints the name
of the file, and writes it out\.

```lua
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
```

```lua
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
```


### Skein:transform\(\)

Does the whole dance\.

We need some better way to get all the database machinery decorated onto the
Skein, because currently we overuse parameters for that\.

```lua
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
```


## Reports

There's a lot of reaching into the Skein for things, and most of this should
be replaced with reporting methods\.

The chaining methods will all perform prior stages if they are missing
information, the opposite applies to reports\.

Report methods make two guarantees, in fact: they won't trigger any stage
methods, and they won't mutate any data on the Skein\.


### Skein:tagsFor\(node\)

We have a map of Nodes which are tagged by the tagger, to a set of those tags,
or nil\.

This lets us return a "no tags" empty set so that we don't have to keep
looking for an empty set of tags before checking what we want to know, which
is if a tag applies\.


#### empty\_set

This will return `nil` for `empty_set(val)` and `empty_set[val]`, at least for
tables, which are what the elements are\. This is forward compatible with the
upcoming switch to `core.set`, which uses ordinary indexing\.

```lua
local empty_set = require "set:set" ()

function Skein.tagsFor(skein, node)
   local tags = assert(skein.tags, "Skein has not been tagged")
   return tags[node] or empty_set
end
```


### Skein:knitScroll\(knitter\)

Makes a Scroll if it doesn't have one\.

Here we can also swap a Case for plantuml, and eventually do some actually
sophisticated things with manifests and tags\.

```lua
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
```


#### Skein:knitPathFor\(code\_type\)

This lets us get at the Manifest to direct it eventually\.

```lua
function Skein.knitPathFor(skein, code_type)
   return skein.source.file.path
                    :subFor(skein.source_base,
                            skein.knit_base,
                            code_type)
end
```


### Skein:


### new\(path, lume\)

Takes a path to the source document, which may be either a Path or a bare
string\.

Also receives the handle of the enclosing lume, which we aren't using yet,
and might not need\.

```lua
local function new(path, lume)
   local skein = setmetatable({}, Skein)
   skein.note = Notary()
   skein.source = {}
   if not path then
      error "Skein must be constructed with a path"
   end
   local file;
   -- handles: string, Path, or File objects
   if type(path) == 'string' or path.idEst ~= File then
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
```


```lua
return new
```