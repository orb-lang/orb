# Pikchr

Richard Hipp's extension of the PIC language\.


```lua
local Pikchr = use "orb:knit/knitter" 'pikchr'
```


### Notes on Knitting Artifacts

These are an example of something which will become increasingly common: many
artifacts of knitting aren't source code and have no business ending up in
the sorcery directory\.

This we want to handle with tags, naturally\. For Pikchr the tag should be
`#inline`, indicating that the output is suitable for direct inclusion in the
weave, which should be simple to do to an SVG, for both Markdown and HTML\.

Artifacts want to end up managed by the skein and findable directly off
relevant blocks of the document\.


```lua
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
```
