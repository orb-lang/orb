# Knitter Module

   A knitter is the actor responsible for knitting together our source
 code\.  They are defined by language, which is to say that the unit of
 action is not a runtime or document, knitters will expand to be
 responsible for an arbitrary number of these\.

 The bootstrap knitter does what a knitter will do by default:  go through
 `.../org/*/*.gm` and generate `.../src/*.*.lang` for all code blocks in
 `#lang`\.

 It must do so through an interface which will let it grow up\.

## Design

   `grym invert` is an isolated module\.  It's a shim; if better tools
 succeeds, we'll stop using it within the Arc in fairly short order\.

 `grym knit`, by contrast, is part of the core system\.  Software tends
 to stick around, and a Grimoire is a language\-as\-in\-human\-language
 sort of project\.  An advantage we intend to offer over Org is a
 nice Unix\-flavor toolkit for munging flat files from your choice of
 editor\.

 `knit` methods receive a parsed document, not a string\.  The Knitter
 modules generates language specific transformers for various Nodes,
 and the Knit module uses them when called for\.

```lua
local u = {}

-- A helper function which takes an optional metatable,
-- returning a meta-ed table and a table meta-ed from
-- that.
-- The former can be filled with methods and the latter
-- made into a constructor with __call, as well as a
-- convenient place to put library functions which aren't
-- methods/self calls.
--
-- - meta: a base metatable
--
-- - returns:
--   - The class metatable
--   - Constructor and library table
--
function u.inherit(meta)
  local MT = meta or {}
  local M = setmetatable({}, MT)
  M.__index = M
  local m = setmetatable({}, M)
  m.__index = m
  return M, m
end

-- Function to export modules
--
-- The first argument of util.inherit being filled with methods,
-- the second argument is passed to util.export as =mod=, along
-- with a function =constructor= which will serve to create a
-- new instance.
--
function u.export(mod, constructor)
  mod.__call = constructor
  return setmetatable({}, mod)
end

local Phrase = require "singletons/phrase"

local K, k = u.inherit()
K.it = require "singletons/check"
```

## knit method

   This is where it all comes together\.

 We're still bootstrapping\.  The only language is lua, we don't know
 what hashtags are yet, and we go in simple linear order\.

 - knitter :  the knit module\. That is, K, rather than a given k in
     K\.langs\.
 - doc     :  a Doc\.

 - \#return : the knit file as a string\.


```lua
function K.knit(knitter, doc)
    local phrase = Phrase()
    local linum = 0
    for cb in doc:select("codeblock") do
        cb:check()
        if cb.lang == "lua" then
           -- Pad code with blank lines to line up errors
           local pad_count = cb.line_first - linum

           local pad = ("\n"):rep(pad_count)
           -- cat codeblock value
           phrase = phrase .. pad .. cb.val

           -- update linum
           linum = cb.line_last - 1
        else
          -- other languages
        end
    end

    return phrase, ".lua"
end

local function new(Knitter, lang)
    local knitter = setmetatable({}, K)
    knitter.lang = lang or "lua"
    return knitter
end

return u.export(k, new)
```
