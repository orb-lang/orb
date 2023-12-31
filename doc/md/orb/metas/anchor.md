# Anchor


  An anchor is the part of a hypertext link representing the destination\.

Our anchors come in two flavors: the familiar URI, and "ref"s\.


#### imports

```lua
local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"

local Twig = require "orb:orb/metas/twig"

local s = require "status:status" ()
local ts = require "repr:repr" . ts_color
s.verbose = false
```


## Ref

  A ref is a short link, meant to be an Orb\-native way of referring betweeen
documents\.

I'm still working on the syntax here\.  These use the Bridge namespace
conventions to resolve links between projects and within documents in a
flexible way\.

I intend to make newlines within an anchor legal, such that they will be
ignored by the engine\.  They must be between parts of the URI, or ref\.  It's
easier to implement without this and add it later\.


### @ Refs

Refs begin with an `@` sign, making them a sort of handle\.

These always refer to a document or directory in an Orb project, or, a section
within one\.

`@name` is an internal reference, with a name resolution policy which is TBD,
but will be based on the GitHub schema for anchor reference resolution\.  If
there's an explicitly named entity with that name, the link will resolve to it\.

`@:folder/file` refers to a module inside the same project\.  This is a
reference to our `require` syntax, `"project:module"`, with the project
elided\.  `@project:folder/file`, therefore, is a reference across projects,
with the same fully\-qualified form as in `require`: the namespace is assumed
to be the native namespace, unless provided, or overridden in the manifest\.

It's valid to refer to just a project as well, as `@full.domain/project:` or
`@project:` for the default domain\.  This will resolve to a link to the repo
root, unless the weaver is otherwise directed by the manifest\.

In a cross\-document reference, we use the familiar `#` form for an anchor
within a document `@fully.qualified/project:folder/file#fragment`\.  At
present, we don't support queries in refs, but perhaps we should\.  I'm pretty
sure that `@named-ref` is the same as `@project:module/file#named-ref`, if
we're inside project\-module\-file\.

There's no need to elide the domain, a la `@/project:file`, which is
\(currently\) not a valid ref\.  If one isn't provided, the resolved URL will be
based on the `default_domain` field in the [manifest](https://gitlab.com/special-circumstance/br-guide/-/blob/trunk/doc/md/orb.md#manifests)\.

Note that `.orb` is not needed and should be elided, although we'll make the
parser smart enough to accept it\.  Orb documents take on several extensions
depending on where they end up\.


```peg
        ref  ←  pat ( domain net project col doc-path
                    / project col doc-path
                    / doc-path ) (hax fragment)*

     domain  ←  (!"/" 1)+
    project  ←  (!":" 1)*
   doc-path  ←  (!"#" 1)*
   fragment  ←  (!"]" 1)+
        net  ←  "/"
        pat  ←  "@"
        col  ←  ":"
        hax  ←  "#"
```


#### Inline expansion \(not an @ref\) \#NYI

Epistemic status: maybe?

Sometimes we want to expand a large URL which is named elsewhere\.  This is
not an @ ref, although it looks kind of like one:

```orb
[[a long link][`@named-entity()`]]
```

Uses our normal inlining syntax to paste the value of `@named-entity` into the
ref position\.

We haven't added any inline expansion capability anywhere in Orb yet, so this
one is going to sit on the shelf for awhile\.


## Anchor

```peg
   anchor  ←  ref / url / bad-form
      url  ←  "http://example.com" ; placeholder
 bad-form  ←  (! "]" 1)+
```

```lua
anchor_str = anchor_str .. "\n\n" .. ref_str
```

### Ref metatable

```lua
local Ref = Twig :inherit "ref"
```


#### Ref:resolveLink\(skein\)

  Returns a string containing the URI resolved from the ref, using
`skein.manifest`\.

```lua
local ext_refs = { md = "markdown_dir",
                   html = "weave_dir" }
local ext_defaults = { markdown_dir = "doc/md/",
                       weave_dir    = "/doc/html/" }


local print_manifest = true
local format = assert(string.format)
function Ref.resolveLink(ref, skein, extension)
   if print_manifest then
      print_manifest = false
      s:bore(ts(skein.manifest))
   end
   extension = extension or ""
   -- manifest or suitable dummy
   local manifest = skein.manifest or { ref = { domains = {} }}
   local man_ref = manifest.ref or { domains = {} }
   local project  = skein.lume and skein.lume.project or ""
   s:bore("ref: %s", ts(ref:span()))
   local url = ""
   -- build up the url by pieces
   local domain = ref :select "domain" ()
   local project = ref :select "project" ()
   local doc_path = ref :select "doc_path" ()
   local fragment = ref :select "fragment" ()
   s:bore("domain: %s, project: %s, doc_path: %s, fragment: %s",
          domain and domain:span() or "''",
          project and project:span() or "''",
          doc_path and doc_path:span() or "''",
          fragment and fragment:span() or "''")
   if not domain then
      if man_ref.default_domain then
         url = url .. (man_ref.domains[man_ref.default_domain]
                       or format ("NO_DEFAULT_DOMAIN_URL for %s",
                                  man_ref.default_domain))
      else
         url = url .. "NO default.domain IN MANIFEST"
      end
   else
      url = url .. (man_ref.domains[domain:span()]
                    or format("no manifest domain for %s", domain:span()))
   end
   if project then
      project = project:span()
      if project == "" then
         -- default project
         project = man_ref.project_path or skein.lume.project
      end
   else
      -- default project
      project = man_ref.project_path or skein.lume.project
   end
   url = url  .. project .. "/"
   if not doc_path then
      return url
   end
   url = url .. (man_ref.post_project or "MISSING_POST_PROJECT")
   -- extension directory
   local ext_field, ext_dir = ext_refs[extension], nil
   if ext_field then
      ext_dir = man_ref[ext_field] or ext_defaults[ext_field]
   end
   if ext_dir then
      url = url .. ext_dir
   end
   url = url .. doc_path:span() .. "." .. extension
   if fragment then
      url = url .. "#" .. fragment:span()
   end

   s:bore("url: %s", url)
   return url
end
```

```lua
-- We'll need some custom metatables soon, but: not this instant.
local Anchor_M = { Twig,
                   ref = Ref }

local anchor_grammar = Peg(anchor_str, Anchor_M)

return subGrammar(anchor_grammar.parse, "anchor-nomatch")
```
