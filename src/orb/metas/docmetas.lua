





local Twig = require "orb:orb/metas/twig"
local Phrase = require "singletons:singletons/phrase"
local Deque = require "deque:deque"



local DocMetas = {}







local Doc_M = Twig:inherit "doc"
DocMetas.doc = Doc_M



function Doc_M.toMarkdown(doc, scroll, skein)
   for _, block in ipairs(doc) do
      block:toMarkdown(scroll, skein)
   end
end








local Skein;
function Doc_M.toSkein(doc)
   Skein = Skein or require "orb:skein/skein"
end



local Section_M = Twig:inherit "section"
DocMetas.section = Section_M













local insert = assert(table.insert)

local lua_chunker;

local function lua_codebodies(doc)
   local bodies = Deque()
   for codeblock in doc :select "codeblock" do
      if codeblock:select "code_type" () :span() == 'lua' then
         bodies:push(codeblock :select "code_body"() )
      end
   end
   return function()
      return bodies:pop()
   end
end

function Doc_M.parsedCodeblocks(doc)
   lua_chunker = lua_chunker or require "lun:lua-parser"
                                   :ruleOfName "chunk"
                                   :toPeg() . parse
   local parse_info = {}
   for lua in lua_codebodies(doc) do
      local code_line = lua:linePos()
      local chunk = lua_chunker(lua:span())
      local err, col = chunk:errorAt()
      if err then
         insert(parse_info, { error = true,
                              code_line = code_line,
                              line = err,
                              col  = col })
      else
         insert(parse_info, { error = false,
                              code_line = code_line })
      end
   end
   return parse_info
end



function Section_M.toMarkdown(section, scroll, skein)
   for _, block in ipairs(section) do
      block:toMarkdown(scroll, skein)
   end
end



return DocMetas

