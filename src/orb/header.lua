



local Twig = require "orb:orb/metas/twig"
local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"



local header_str = [[
        header  ←  " "* level (head-line / -1)
         level  ←  "*"+
     head-line  ←  (" " header-text)
   header-text  ←  1*
]]



local header_grammar = Peg(header_str, {Twig})




return subGrammar(header_grammar.parse, "header-nomatch")
