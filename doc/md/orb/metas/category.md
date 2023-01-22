# Categories

Looks like this: ::A\-category:another:again::\.

The first `::` is mandatory, the last is just good style\.

AKA user tags\.


### Normalization

The first and last category must touch the colon delimiters, space marks are
otherwise allowed\.  Padding on either side of the colon is a style violation,
the category is treated as though the spaces don't exist, linters remove them\.

Spaces, hyphens, and underscores, are all treated as underscores, and the
remaining glyphs \(other than hyphen and space, that is\) which are illegal in
LuaJIT symbols \(rather few in fact\) are not allowed, nor a leading digit,
underscore, or hyphen\.


## Inheritance

Capitalized categories inherit into subsections, like hashtags\.

This is based on the ASCII case of the first letter\.

As we expand Orb to its proper domain of all the world's languages, this will
not suffice\.  What we will do: define a single canonical casing for character
sets where this is meaningful, and anoint a 'majuscule mark' to lead any
category, even an ASCII one, to enforce inheritance\.  This will be paired
with a minuscule mark for those occasions when, for one example, the category
is a proper name, but we don't want it to inherit\.  This may be elided for
any leading character not explicitly capital, which will be a subset of those
which have a capital appearance \(looking at you, Fraktur\)\.

What we will not do is get language\-specific casing or character order mixed
up with categories\.  Orb's syntax is for human languages, not based on them,
but rather, Unicode\.


## The Categorical Graph

Tree\-structured ontologies are inherently artificial, so this mistake, we
decline to make\.

That a category may have a general\-specific relation to another category is
uncontroversial\.  We reflect this as inclusion: ::meat:: includes ::beef::,
and ::food:: also includes ::beef::\.

Does ::food:: include ::meat::? Well, I wouldn't, I consider meat a category
of food, not a food itself\.  Someone who eats all foods described as meats
might differ in this\.

These references are directed, one\-to\-one, and may be cyclic, since these
relations are unrolled from the category of interest\.

This is composable, there being no way for such a graph to contradict itself\.
Which cooperates nicely with the local effect of manifests and drawers: a
weird choice of inclusion relationship will show up in the data found within
the document defining that relationsip, but it won't leak to other documents:
references to the British Royals might show up under ::lizard::, but only in
the document which is convinced they shapeshift\.


## Category qualifiers

This should be sufficient and correct for the general case, but we want a
mechanism to determine the exception\.

These are qualifiers\. Example: ::beef/vegan:: would hide the category frombeef::, but show it under ::vegan::, as though ::vegan:: were
cross\-tagged
:: with ::beef::\.

A vegan, of course, might tag their recipe ::vegan:beef::, and a recipe for
brisket as ::beef/carnist::, so as not to pollute searches\.

A category may have any number of qualifiers, all of which apply to the
category\.  Order is not important, ::beef/carnist/uncle ted:: shows up as
Uncle Ted's beef, it doesn't associate Ted with carnism or vice versa\.

These are also useful in inline categories, where most references might be
interpreted as Wiki\-style self\-links, but some might be tagged ::word/g:: with
the qualifier used to point the word at the glossary instead\.

For that specific use, we should support an empty qualifier, which negates the
semantics of disincluding the category in itself\. So ::word//g:: means that
word is glossary\-qualified, but also has the category ::word::, so shorthand
for ::word:word//g::\.  The latter is no longer lightweight enough for a fluent
inline markup\.  This must be the first category to count: ::word/g/:: is too
likely a typo, we'll warn and lint that sort of thing\.

As a final point, a category may point at a qualified tag\.  The qualifiers
behave as though all of them are applied separately to the category, so even
if there was only ::boat/sushi/ceramic::, pointing ::japanese art::
at ::boat/ceramic:: would work\.

This should be all we need\.  Categories primarily evaluate to themselves, we
aren't going to make them Turing Complete\.

I should probably come back and pick examples that are less edgy\. I was
hungry\.


### Synonyms

  I expect this will be particularly useful for qualifiers, we want a way to
say that a short tag is just a way of spelling a longer one\. So ::widget/c::
instead of having to spell out ::widget/class: every time\.

I in fact treated ::word/g:: as an example of this in the above\.

I'm wondering if maybe **only** qualifiers should get short synonyms, or rather,
short synonyms only expand when they're qualifiers\.