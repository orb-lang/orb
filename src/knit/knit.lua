





local L = require "lpeg"

local s = require "status" ()
local a = require "ansi"
s.chatty = true
s.verbose = false

local pl_file = require "pl.file"
local pl_dir = require "pl.dir"
local pl_path = require "pl.path"
local getfiles = pl_dir.getfiles
local getdirectories = pl_dir.getdirectories
local makepath = pl_dir.makepath
local extension = pl_path.extension
local dirname = pl_path.dirname
local basename = pl_path.basename
local read = pl_file.read
local write = pl_file.write
local delete = pl_file.delete
local isdir = pl_path.isdir


local knitter = require "knit/knitter"

local walk = require "walk"
local Dir, Path, File = walk.Dir, walk.Path, walk.File
local strHas = walk.strHas
local endsWith = walk.endsWith
local subLastFor = walk.subLastFor
local writeOnChange = walk.writeOnChange

local Doc = require "Orbit/doc"













local function knit_dir(knitter, orb_dir, pwd)
    local knits = {}
    for dir in pl_dir.walk(orb_dir.path.str, false, false) do
        if not strHas(".git", dir) and isdir(dir)
            and not strHas("src/lib", dir) then

            local files = getfiles(dir)
            s:chat("  * " .. dir)
            local subdirs = getdirectories(dir)
            for _, f in ipairs(files) do
                if extension(f) == ".orb" then
                    -- read and knit
                    s:verb("    - " .. f)
                    local orb_f = read(f)
                    local knitted = knitter:knit(Doc(orb_f))
                    local src_dir = subLastFor("/orb", "/src", dirname(f))
                    makepath(src_dir)
                    local bare_name = basename(f):sub(1, -5) -- 4 == #".orb"
                    local out_name = src_dir .. "/" .. bare_name .. ".lua"
                    local current_src = read(out_name) or ""
                    local changed = writeOnChange(knitted, current_src, out_name, 0)
                    if changed then
                        local tmp_dir = "../tmp" .. src_dir
                        makepath(tmp_dir)
                        local tmp_out = "../tmp" .. out_name
                        write(tmp_out, current_src)
                        knits[#knits + 1] = out_name
                    end
                end
            end
        end
    end

    -- collect changed files if any
    local orbbacks = ""
    for _, v in ipairs(knits) do
        orbbacks = orbbacks .. v .. "\n"
    end
    if orbbacks ~= "" then
        s:chat("orbbacks: \n" .. orbbacks)
    end
    -- if nothing changes, no rollback is needed, empty file
    write(tostring(pwd) .. "/.orbback", orbbacks)
    return true
end

















local function knit_all(knitter, pwd_str)
    local did_knit = false
    local pwd = Dir(pwd_str)
    pwd.codex_type = "base"
    for dir_str in pl_dir.walk(pwd.path.str, false, false) do
        -- #todo this should be an internal criterion of
        -- the Dir class which attaches the type.
        if not strHas(".git", dir_str)
            and not strHas("/tmp", dir_str)
            and endsWith("orb", dir_str) then

            -- this is a terrible haque
            if isdir(dir_str .. "/orb") then
                    dir_str = dir_str .. "/orb"
            end

            s:chat(a.cyan("Knit: " .. dir_str))
            local dir = Dir(dir_str)
            dir.codex_type = "home"
            did_knit = knit_dir(knitter, dir, pwd)
        end
    end
    if not did_knit then
        s:chat("No orb directory to knit. No action taken.")
    end
    return did_knit
end

knitter.knit_all = knit_all


return knitter
