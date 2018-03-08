local lpeg = require "lpeg"
local epeg = require "../peg/epeg"
local epnf = require "../peg/epnf"

local match = lpeg.match -- match a pattern against a string
local P = lpeg.P -- match a string literally
local S = lpeg.S  -- match anything in a set
local R = epeg.R  -- match anything in a range
local B = lpeg.B  -- match iff the pattern precedes the use of B
local C = lpeg.C  -- captures a match
local Csp = epeg.Csp -- captures start and end position of match
local Cg = lpeg.Cg -- named capture group (for **balanced highlighting**)
local Cb = lpeg.Cb -- Mysterious! TODO make not mysterious
local Cmt = lpeg.Cmt -- match-time capture
local Ct = lpeg.Ct -- a table with all captures from the pattern
local V = lpeg.V -- create a variable within a grammar

local letter = R"AZ" + R"az"   
local digit = R"09"

local punctuation = S"!?,.:;\\^%~"

local interior = S"*_-/@#"
local sym = letter + digit + punctuation + interior
local first_letter = letter + digit + punctuation
local WS = P' ' + P',' + P'\09' -- Not accurate, refine (needs Unicode spaces)
local NL = P"\n"

local function equal_strings(s, i, a, b)
   -- Returns true if a and b are equal.
   -- s and i are not used, provided because expected by Cb.
   return a == b
end

local function bookends(sigil)
   -- Returns a pair of patterns, _open and _close,
   -- which will match a brace of sigil.
   -- sigil must be a string. 
   local _open = Cg(C(P(sigil)^1), sigil .. "_init")
   local _close =  Cmt(C(P(sigil)^1) * Cb(sigil .. "_init"), equal_strings)
   return _open, _close
end

local _grym_fn = function ()
   local function grymmyr (_ENV)
      START "grym"
      SUPPRESS ("structure", "structured")

      local prose_word = first_letter * (sym^1)^0
      local prose_span = (prose_word + WS^1)^1
      local NEOL = NL + -P(1)
      local LS = B("\n") + -B(1)

      grym      =  V"section"^1 * V"unparsed"^0

      section   =  (V"header" * V"block"^0) + V"block"^1

      structure =  V"blank_line" -- list, table, json, comment...

      header     =  LS * V"lead_ws" * V"lead_tar" * V"prose_line"
      lead_ws    =  Csp(P" "^0)
      lead_tar   =  Csp(P"*"^-6 * P" ")
      prose_line =  Csp(prose_span * NEOL)

      block =  (V"structure"^1 + V"prose"^1)^1 * #V"block_end"

      prose        =  (V"structured" + V"unstructured")^1
      unstructured =  Csp(V"prose_line"^1 * prose_span + V"prose_line"^1
                     + prose_span -V"header")
      structured   =  V"bold" + V"italic" + V"underscore" + V"strikethrough"
                     + V"literal" + V"quoted"

      unparsed = Csp(P(1)^1)

      -- Highlighting
      -- These inner blocks will need to be re-parsed to render, e.g., links
      -- or multiple layers of highlight. 
      local bold_open, bold_close     =  bookends("*")
      local italic_open, italic_close =  bookends("/")
      local under_open, under_close   =  bookends("_")
      local strike_open, strike_close =  bookends("-")
      local lit_open, lit_close       =  bookends("=")
      bold   =  Csp(bold_open * (P(1) - bold_close)^0 * bold_close / 1) - V"header"
      italic =  Csp(italic_open * (P(1) - italic_close)^0 * italic_close / 1)
      underscore = Csp(under_open * (P(1) - under_close)^0 * under_close / 1)
      strikethrough = Csp(strike_open * (P(1) - strike_close)^0 * strike_close / 1)
      literal = Csp(lit_open * (P(1) - lit_close)^0 * lit_close / 1)

      local quoted_open = Cg(C(P("\"")^2), "quoted_init")
      local quoted_close = Cmt(C(P("\"")^1) * Cb("quoted_init"), equal_strings)
      quoted = Csp(quoted_open * (P(1) - quoted_close)^0 * quoted_close / 1)

      block_end = V"blank_line"^1 + -P(1) + #V"header"

      blank_line = Csp((WS^0 * NL)^1)
   end

   return grymmyr
end

return epnf.define(_grym_fn(), nil, false)

