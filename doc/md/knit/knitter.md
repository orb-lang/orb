# Knitter


  The base genus for language\-specific Orb knitters\.


#### imports

```lua
local core = require "qor:core"
local cluster = require "cluster:cluster"
```


## Knitter

```lua
local new, Knitter, Knit_M = cluster.genus()
```


## fields


### code\_type: string

  A Knitter must have a `code_type`, which is a string\.

```lua
Knitter.code_type = nil
```

This might be a good genus to apply a cluster `mold` once I get around to
writing them\.

Knitters might turn out to be a `clade`, although I'd need to work out a
method of runtime extension because we want knitters to be user extensible
packages\.


## builder

```lua
cluster.construct(new, function(_new, knitter, code_type)
   knitter.code_type = code_type
   return knitter
end)
```


## Methods

This is streamlined down to a predicate to decide if we're going to knit a
codeblock, and a knitter\.

We'll need to be smarter than this, since it doesn't scale, but we'll get that
flexibility back when we have knitters specialized from a common genus\.

### Knitter:examine\(skein, codeblock\)

A predicate, returning `true` if the codeblock is to be knit\.

We pass the skein first because this is, practically speaking, a method call
against both the knitter and the skein\.

The default answer is `false`:

```lua
Knitter.examine = assert(cluster.ur.no)
```


### Knitter:knit\(skein, codeblock, scroll\)

This might not be the right interface, but it's the one we're using right now\.

It precludes more than one artifact per code type, which is probably invalid\.

It should be an error to call this without implementing it:

```lua
Knitter.knit = assert(cluster.ur.NYI)
```



