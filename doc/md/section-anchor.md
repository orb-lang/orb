# Section Anchor


```peg
section <- (ws / word / invalid)+
ws <- { \t}
word <- (valid/invalid)+
valid <- [A-Z] / [a-z] / [0-9] ; I think that's it?
`invalid` <- !valid 1
```

```lua
local function toSectionAnchor(str)
   
end
```
