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

Refs begin with an `@` sign\.  This resembles handles both syntactically and
semantically, however refs have their own grammar, there is no overlap between
where refs and handles are found\.

These always refer to a document or directory in an Orb project, or, a section
within one\.  Note that `.orb` is not included in refs\.

`@name` is an internal reference, with a name resolution policy which is TBD,
but will be based on the GitHub schema for anchor reference resolution\.  If
there's an explicitly named entity with that name, the link will resolve to
it\.  This is a fragment with a leading `#` in the resulting URL\.

Any other reference is out of the document, and can take a fragment with a
`#`\.

`@folder/file` refers to a module inside the same project\.  If there's no
folder between the project root and the file, this must be spelled `@:file`,
therefor `@:folder/file` is a legal synonym for the first form\.

We also allow `@:folder/` by itself, but `@folder/` is not a synonym\.  It
should refer to a domain, though I'm leaving that out for lack of a use for
it\.  For now\.

`@/project:folder/file`, and `@/project:file`, are references across projects
within the base domain, which defaults to the same domain as the project
incorporating the ref\.  For us, `br` or `bridge`\.

It's valid to refer to just a project as well, as `@full.domain/project:` or
`@/project:` for the default domain\.  This will resolve to a link to the repo
root, unless the weaver is otherwise directed by the manifest\.  While we
could allow `@project:`, I find it confusing and don't see this as a good
place for a synonym\.

In any cross\-document reference, we use the familiar `#` form for an anchor
within a document `@fully.qualified/project:folder/file#fragment`\.  At
present, we don't support queries in refs, but perhaps we should\.
`@named-ref` is the same as `@project:folder/file#named-ref`, if we're inside
project\-module\-file\.


```peg

           ref  ←  pat ref-form -1 ; / bad-ref

    `ref-form`  ←  cross-ref / in-ref

   `cross-ref`  ←  full-ref
                /  doc-ref
                /  project-ref

        in-ref  ←  fragment

      full-ref  ←  domain project-ref
       doc-ref  ←  full-doc / short-doc
   project-ref  ←  net project doc-ref?

        domain  ←  name (dot name)*
    `full-doc`  ←  col folder* file?
   `short-doc`  ←  folder+ file
       project  ←  name col
        folder  ←  name net
          file  ←  name frag?

        `frag`  ←  hax fragment

           net  ←  "/"
           pat  ←  "@"
           col  ←  ":"
           hax  ←  "#"
           dot  ←  "."

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

This is a huge mess, not helped by the fact that Refs themselves are
practically folklore in how I've written them relative to what this rat's
nest is doing\.


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
   local man_ref;
   local manifest = skein.manifest
   if manifest then
      man_ref = manifest.data.ref or { domains = {} }
   else
      man_ref = {domains = {}}
   end
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
