










local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"

local Twig = require "orb:orb/metas/twig"

local s = require "status:status" ()
local ts = require "repr:repr" . ts_color
s.verbose = false






















































local ref_str = [[
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
]]






















local anchor_str = [[
   anchor  ←  ref / url / bad-form
      url  ←  "http://example.com" ; placeholder
 bad-form  ←  (! "]" 1)+
]]


anchor_str = anchor_str .. "\n\n" .. ref_str





local Ref = Twig :inherit "ref"














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



-- We'll need some custom metatables soon, but: not this instant.
local Anchor_M = { Twig,
                   ref = Ref }

local anchor_grammar = Peg(anchor_str, Anchor_M)

return subGrammar(anchor_grammar.parse, "anchor-nomatch")

