


local Path = require "walk/path"
local Dir  = require "walk/directory"

local Spec = {}

Spec.folder = "walk"

function Spec.path()
  local a = Path "/core/build/"
  local b = a .. "codex.orb"
  local c = a .. "orb/"
  local d = Path "/core/build/orb/"
  local a1, b1
  -- new way
  b, b1 = b: it "file-path"
     : must "have some fields"
        : have "str"
        : equalTo "/core/build/codex.orb"
        : ofLen(#b.str)
     : must ("return the requested directory path")
        : have "isPath"
        : equalTo(Path)
        : have "parentDir"
        : calling ("build")
        : gives (Path "/core/build/")
     : must()
        : have "filename"
        : equalTo "codex.orb"
        : fin()()

  c = c : it "equals-d"
        : must ()
            : equal(d)
            : have "isDir"
            : equalTo(true)
        : mustnt ()
            : have "filename"
            : fin()()

  a, a1 = a: it "a well-behaved Path"
             : mustnt ()
                : have "brack"
                : have "broil"
             : shouldnt()
                : have "badAttitude"
                : fin()()
end



function Spec.dir()
  a = Dir "/usr/"
         : it ("the /usr/ directory")
            : has ("exists")
            : calling()
            : gives(true)
            : fin()

  b = Dir "/imaginary-in-almost-any-conceivable-case/"
         : it("imaginary directory")
              : calledWith "exists"
              : should()
              : give(false)
              : fin()

   c = Dir "/usr/tmp/"
          : it "swap-directory"
         : must "swap /usr/ for /tmp/"
          : have "swapDirFor"
          : calling("/usr/", "/tmp/")
          : gives(Dir "/tmp/tmp/")
          : fin()

end




function Spec.file()
  a = File "/orb/orb.orb"
      : it "orb-file"
      : must "have path"
        : have "path"
        : equalTo(Path "/orb/orb.orb")
        : passedTo(tostring)
        : gives("/orb/orb.orb")
        : fin()
        : allReports()
   b = File "/bin/sh"
       : it("shell")
         : has "exists"
         : calling ()
         : gives (true)
         : fin()
         : allReports()
end



return function()
          Spec.path()
          Spec.dir()
          Spec.file()
       end
