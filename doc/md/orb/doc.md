# Doc

  A Doc is an Orb source document\.

The parser proceeds outside\-in, taking advantage of the fact that we can
assign functions as 'metatables' for Nodes, and the Grammar will obligingly
call that function on the semi\-constructed table\.

That function may in turn be a Grammar, which we can call with an offset, so
that the secondary parsing boundaries line up with the overall document
string\.

We also have the ability to post\-process a Grammar, which is handy, since a
few operations, notably making a heirarchy out of Sections, are better
performed once parsing is completed\.


#### imports

```lua
local Peg   = require "espalier:peg"
local table = require "core:core/table"
```


### Metas

```lua
local Twig      = require "orb:orb/metas/twig"
local Header    = require "orb:orb/header"
local Codeblock = require "orb:orb/codeblock"
local Table     = require "orb:orb/table"
local Prose     = require "orb:orb/prose"
local List      = require "orb:orb/list"
local Listline  = require "orb:orb/list-line"
local fragments = require "orb:orb/fragments"
```


## Doc Grammar

  A Parsing Expression Grammar, defining the main characteristics of an Orb
document's structure, using [espalier's PEG parser](https://gitlab.com/special-circumstance/espalier/-/blob/trunk/doc/md/espalier/peg.md)\.

```peg
            doc  ←  (first-section / section) section*
`first-section`  ←  (block-sep / line-end)? blocks / (block-sep / line-end)

        section  ←  header line-end blocks*
         header  ←  " "* "*"+ " " (!"\n" 1)*
                 /   " "* "*"+ &"\n"

       `blocks`  ←  block (block-sep* block)* block-sep*
        `block`  ←  structure
                 /  paragraph
    `structure`  ←  codeblock
                 /  blockquote
                 /  table
                 /  list
                 /  handle-line
                 /  hashtag-line
                 /  note
                 /  link-line
                 /  drawer
      block-sep  ←  "\n\n" "\n"*

      codeblock  ←  code-start (!code-end 1)* code-end
   `code-start`  ←  "#" ("!"+)@codelevel code-type@code_c (!"\n" 1)* "\n"
     `code-end`  ←  "\n" "#" ("/"+)@(#codelevel) code-type@(code_c)
                     (!"\n" 1)* line-end
                 /  -1
    `code-type`  ←  symbol?

     blockquote  ←  block-line+ line-end
   `block-line`  ←  " "* "> " (!"\n" 1)* (!"\n\n" "\n")?

          table  ←  table-head table-line*
   `table-head`  ←  (" "* handle_h* " "*)@table_c
                    "|" (!"\n" 1)* line-end
   `table-line`  ←  (" "*)@(#table_c) "|" (!line-end 1)* line-end

           list  ←  (list-line / numlist-line)+
      list-line  ←  ("- ")@list_c (!line-end 1)* line-end
                    (!(" "* list-num)
                    (" "+)@(>list_c) !"- "
                    (!line-end 1)* line-end)*
                 /  (" "+ "- ")@list_c (!line-end 1)* line-end
                    (!(" "* list-num)
                    (" "+)@(>=list_c) !"- " (!line-end 1)* line-end)*
   numlist-line  ←  list-num@numlist_c (!line-end 1)* line-end
                    (!(" "* "- ")
                    (" "+)@(>numlist_c)
                    !list-num (!line-end 1)* line-end)*
                 /  (" "+ list-num)@numlist_c (!line-end 1)* line-end
                    (!(" "* "- ")
                    (" "+)@(>=numlist_c)
                    !list-num (!line-end 1)* line-end)*
     `list-num`  ←  [0-9]+ ". "

    handle-line  ←  handle (!line-end 1)* line-end

   hashtag-line  ←  hashtag (!line-end 1)* line-end

           note  ←  note-slug note-body line-end
      note-slug  ←  "{" (!" " !"\n" !"}" 1)+ "}: "
      note-body  ←  note-lines
   `note-lines`  ←  (note-line note-line-end)* note-line
    `note-line`  ←  (!"\n" 1)+
`note-line-end`  ←  "\n"+ "   " &note-line

      link-line  ←  link-open obelus link-close link line-end
      link-open  ←  "["
         obelus  ←  !("[" / "{" / "#") 1 (!"]" 1)*
     link-close  ←  "]: "
           link  ←  (!line-end 1)*

         drawer  ←  drawer-top line-end
                    ((structure "\n"* / (!drawer-bottom prose-line)+)+
                    / &drawer-bottom)
                    drawer-bottom
   `drawer-top`  ←  " "* ":[" (!"\n" !"]:" 1)*@drawer_c "]:" &"\n"
`drawer-bottom`  ←  " "* ":/[" (!"\n" !"]:" 1)*@(drawer_c) "]:" line-end

      paragraph  ←  (!header !structure par-line (!"\n\n" "\n")?)+
     `par-line`  ←  (!"\n" 1)+
     prose-line  ←  (!"\n" 1)* "\n"
       line-end  ←  (block-sep / "\n" / -1)
```

Now that we're using native PEG blocks we have to append the fragments in a
separate Lua block:

```lua
Doc_str = Doc_str .. fragments.symbol .. fragments.handle .. fragments.hashtag
```


### post\-parse actions

It would be inconvenient to arrange sections correctly during parsing\.

Instead, we iterate the sections, and assign them to the appropriate
subsection\.

```lua
local compact = assert(table.compact)

local function _parent(levels, section)
   local top = #levels
   if top == 0 then
      return section
   end
   local level = section :select "level"() :len()
   for i = top, 1, -1 do
      local p_level = levels[i] :select "level"() :len()
      if p_level < level then
         return levels[i]
      end
   end
   return section
end

local function post(doc)
   local levels = {}
   local top = #doc
   for i = 1, top do
      local section = doc[i]
      if section:select "section" () then
         local parent = _parent(levels, section)
         if parent ~= section then
            -- add to section
            section.parent = parent
            parent[#parent + 1] = section
            -- remove from doc
            doc[i] = nil
            -- adjust .last fields
            parent.last = section.last
            local under
            repeat
               under = parent
               parent = _parent(levels, under)
               parent.last = section.last
            until parent == under
         end
         levels[#levels + 1] = section
      end
   end
   compact(doc, top)
   return doc
end
```


### Doc metatables

This is a mix of actual metatables, and Grammar functions which produce the
subsidiary parsing structure of a given document\.


#### Linkline

  Our `link-line` rule is a bit of a special case, because it's handled inside
the associated `link` for the most part\.

If it turns out we need complex behavior, I'll move this inside its own
module\.

\#Todo
critical for Markdown, where, after all, we don't have stack traces\.

\#Todo

```lua
local Linkline = Twig:inherit "link_line"

Linkline.toMarkdown = Twig.nullstring
```


```lua
local DocMetas = { Twig,
                   header       = Header,
                   codeblock    = Codeblock,
                   table        = Table,
                   paragraph    = Prose,
                   blockquote   = Prose,
                   list         = List,
                   list_line    = Listline,
                   numlist_line = Listline,
                   note_body    = Prose,
                   link_line    = Linkline, }
```

```lua
local addall = assert(table.addall)

addall(DocMetas, require "orb:orb/metas/docmetas")
```

```lua
return Peg(Doc_str, DocMetas, nil, post)
```
