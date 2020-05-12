





local Twig = require "orb:orb/metas/twig"
local Phrase = require "singletons:singletons/phrase"



local DocMetas = {}







local Doc_M = Twig:inherit "doc"
DocMetas.doc = Doc_M



function Doc_M.toMarkdown(doc, skein)
   local phrase = Phrase ""
   for _, block in ipairs(doc) do
      phrase = phrase .. block:toMarkdown(skein)
   end
   return phrase
end



local Section_M = Twig:inherit "section"
DocMetas.section = Section_M



function Section_M.toMarkdown(section, skein)
   local phrase = Phrase ""
   for _, block in ipairs(section) do
      phrase = phrase .. block:toMarkdown(skein)
   end
   return phrase
end



return DocMetas