# File


File is going to mutate a few times fairly rapidly.


Right now a File has a Path and isn't a Directory.


It has a Directory also.


It can tell if it ``exists()``, like the others, it doesn't have to.



Most importantly, a File is not just unique, but won't construct twice.


For a Path or a Dir, trying to create a new one just gets you the old one.


But files lock and otherwise hold resources open, so they only get created
once.


There is no protection against uniqueness of the resulting pointer, but it's
a cheap way to find out we may have contention.

```lua
local File = {}
```