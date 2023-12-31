









local L = require "lpeg"

local s = require "status:status" ()
s.verbose = false

local pl_mini = require "orb:util/plmini"
local getfiles = pl_mini.dir.getfiles
local makepath = pl_mini.dir.makepath
local getdirectories = pl_mini.dir.getdirectories
local extension = pl_mini.path.extension
local dirname = pl_mini.path.dirname
local basename = pl_mini.path.basename
local read = pl_mini.file.read
local write = pl_mini.file.write
local isdir = pl_mini.path.isdir

local u = {}
function u.inherit(meta)
  local MT = meta or {}
  local M = setmetatable({}, MT)
  M.__index = M
  local m = setmetatable({}, M)
  m.__index = m
  return M, m
end
function u.export(mod, constructor)
  mod.__call = constructor
  return setmetatable({}, mod)
end

local a = require "anterm:anterm"

local m = require "orb:Orbit/morphemes"
local walk = require "orb:walk/walk"
local strHas = walk.strHas
local endsWith = walk.endsWith
local subLastFor = walk.subLastFor
local writeOnChange = walk.writeOnChange
local Path = require "fs:fs/path"
local Dir = require "fs:fs/directory"
local File = require "fs:fs/file"
local epeg = require "orb:util/epeg"

local Doc = require "orb:Orbit/doc"

local W, w = u.inherit()



function W.weaveMd(weaver, doc)
  return doc:toMarkdown()
end










local popen = io.popen
local function dotToSvg(dotted, out_file)
    local success, svg_file = pcall (popen,
                          "dot -Tsvg " .. tostring(out_file), "r")
    if success then
        return svg_file:read("*a")
    else
        -- #todo start using %d and format!
        s:complain("dotError", "dot failed with " .. success)
    end
end







local function weaveDeck(weaver, deck)
    local dir = deck.dir
    local codex = deck.codex
    local orbDir = codex.orb
    local docMdDir = codex.docMd
    s:verb ("weaving " .. tostring(deck.dir))
    s:verb ("into " .. tostring(docMdDir))
    for i, sub in ipairs(deck) do
        weaveDeck(weaver, sub)
    end
    for name, doc in pairs(deck.docs) do
        local woven = weaver:weaveMd(doc)
        if woven then
            -- add to docMds
            local docMdPath = Path(name):subFor(orbDir, docMdDir, ".md")
            s:verb("wove: " .. name)
            s:verb("into:    " .. tostring(docMdPath))
            deck.docMds[docMdPath] = woven
            codex.docMds[docMdPath] = woven
        end

    end
    return deck.docMds
end

W.weaveDeck = weaveDeck



function W.weaveCodex(weaver, codex)
   print "weaving CODEX"
   local orb = codex.orb
   weaveDeck(weaver, orb)
   for name, docMd in pairs(codex.docMds) do
      walk.writeOnChange(name, docMd)
   end
end



local function new(Weaver, doc)
    local weaver = setmetatable({}, W)


    return weaver
end



return W
