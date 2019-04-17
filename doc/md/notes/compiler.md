# Compiler


I decided awhile back that the best format for storing libraries and
applications is as a SQLite database full of blobs and metadata.


Dependencies in ``bridgetools`` are getting out of control, so it's time to
actually make this happen.


The actual process of compiling is admirably straightforward; we ``load`` a
string, giving it a name, and then use ``string.dump`` to create bytecode of it.


Another invocation of ``load`` turns this back into a function, which we
execute.  Simple as that.


Here I intend to design the database table structure, and continue to flesh
out the full system, while hopefully avoiding my lamentable tendency to
overspecify.


## SQLite tables


### code

  The ``code`` table has a key ``id``, a ``blob`` field ``binary``, and a
``hash`` field.  I think the ``hash`` field should be SHA3, just as a
best-practices sort of thing. As it turns out, after running a test, SHA512 is
substantially faster.  Now, this may or may not be true of SHA512 in pure
LuaJIT, but that's less important.


So we want to open/create with:

```sql
CREATE TABLE IF NOT EXISTS code (
   code_id INTEGER PRIMARY KEY AUTOINCREMENT,
   hash TEXT UNIQUE NOT NULL,
   binary BLOB NOT NULL
);
```

strictly speaking ``blob`` should also be UNIQUE but that's comparatively
expensive to check and guaranteed by the hash.


### module

  The ``modules`` table has all the metadata about a given blob. Let's mock it
up first.

```sql
CREATE TABLE IF NOT EXISTS module (
   module_id INTEGER PRIMARY KEY AUTOINCREMENT,
   time DATETIME DEFAULT CURRENT_TIMESTAMP,
   snapshot INTEGER DEFAULT 1,
   version STRING DEFAULT 'SNAPSHOT',
   name STRING NOT NULL,
   type STRING DEFAULT 'luaJIT-bytecode',
   branch STRING,
   commit STRING,
   project INTEGER NOT NULL,
   code INTEGER,
   FOREIGN KEY (project)
      REFERENCES project (project_id)
      ON DELETE RESTRICT
   FOREIGN KEY (code)
      REFERENCES code (code_id)
);
```

Most of this is self-describing. ``snapshot`` is a boolean, if false this is a
versioned module.  We'll be adding that later, so everything is configured so
that by default we have a snapshot.  ``version`` is expected to be set to
something if ``version`` is true.


Thought: I may want to enforse semver, in which case it would make sense for
``version`` to be a foreign key to a table containing major, minor, and patch
fields.


``name`` is the string used to ``require`` the module, stripped of any project
header.  ``name`` is not unique except when combined with a ``project``, which
is.


``type`` is for future compatibility. Eventually we'll want to store C shared
libraries in the codex, and Orb is in principle language-agnostic, so there's
no natural limit to what types we might have.


``branch`` and ``commit`` are optional fields for version-control purposes.
Optional because release software doesn't need them.


``project`` is the foreign key to the ``project`` table, described next.


We don't want to delete any projects which still have modules, so we use
``ON DELETE RESTRICT`` to prevent this from succeeding.


``code`` is, of course, the key for the actual binary blob and its hash.


Not sure whether to de-normalize the hash, and since I'm not sure, we won't
for now.  It doesn't seem necessary since we'll ``JOIN`` against the ``code``
table in all cases.


It might be useful to add at least the hash of the source Orb file, I'm
trying to stay focused for now.


### project

This table describes projects.


Our ``require`` will, at first, just add a function to ``package.loader``.
Additionally we'll use some sort of manifest to resolve dependencies,
but that comes later.


I _think_ the best way to separate fully-qualified from relative module names
is like so: ``modname/submod``, ``fully.qualified.project:modname/submod``.


Any ``fully.qualified.project`` needs to be **globally** unique across all bridge
projects.  There has never in the history of ever been a good way to do this.
Having project manifests at least keeps this from leaking into codebases.


Note that we're just going to split on ``:``, there's no expectation that either
side is formatted in any special way.

```sql
CREATE TABLE IF NOT EXISTS project (
   project_id INTEGER PRIMARY KEY AUTOINCREMENT,
   name STRING UNIQUE NOT NULL,
   repo STRING,
   repo_type STRING DEFAULT 'git',
   repo_alternates STRING,
   home STRING,
   website STRING
);
```

This is a simple table. The ``name`` field is most important and must be unique,
as we've indicated, globally unique. ``repo``, ``home``, and ``website`` are all
URIs; I think ``repo`` and ``website`` are fairly self-explanatory.


``home`` is intended to serve content, probably in JSON format, which can be
placed into a ``codex`` without having to compile a repo.  This will be added
(much) later.


``repo_alternates`` is just what it says: if the main repo isn't available for
any reason, this is a list of URIs which can be checked for the repo.  Format
TBD.


This scheme isn't 100% satisfactory, since ``repo`` can be ``NULL``, but
``repo_type`` would be ``git`` anyway. I think that's fine in practice.


## Future

  This is an initial and (almost) minimal specification of what will
eventually be the ``codex`` format.  One thing Orb is trying to do better, is
that there is always a bunch of metadata associated with codebases, and no
obvious place to store it.  We're compelled to think of code as a
pile-of-files, and this breaks down badly when we're doing literate
programming.


Nor do I just want to recreate version control, badly. At various points in
this journey I wanted to use fossil-scm as a library, and I still think that's
about the best way to do things, but it's not practical for now, given the
resources I have available.


What _is_ practical is to solve my case of dependency hell, and get to where
I can use my REPL on any of my projects without everything breaking.


After I do that, we want a native HTML representation of Orb files, and a
simple server for it.


Then we start breaking the most serious current limitation of Orb: it's
basically a fancy comment system, from Lua's perspective.  The load-and-dump
scheme does strip all the extraneous whitespace and keep the line numbers,
but we do want source mapping, which generalizes better.


Those source maps should of course be stored in the codex.


One leap at a time.






