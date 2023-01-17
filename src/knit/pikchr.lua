





local Pikchr = use "orb:knit/knitter" 'pikchr'


















local spawn;

function Pikchr.knit(pikchr, skein, codeblock, scroll)
   spawn = spawn or require "proc:spawn"
   local proc = spawn("pikchr", {"--svg-only", "-"})
   if proc.didnotrun then
      s:warn "pikchr didn't run, is it installed?"
      return
   end
   s:verb "writing pikchr"
   proc:write(codeblock :select "code_body"() :span())
   local reddit = assert(proc:read(), debug.traceback())
   s:chat(reddit)
   scroll:add(reddit)
   proc:exit() -- we can do better than this
end

