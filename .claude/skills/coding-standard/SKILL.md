---
name: coding-standard
description: The rules every server, registry, manager, backend and plugin of gnd-skydome keeps - a server is a singleton, never a class of static functions; nothing is loaded in a constructor nor by a lazy cache. Use before writing or reviewing such a class, before adding a static func or a static var, before loading a resource in a constructor, _init(), a registration or on first use, and when a game of more needs to extend a server.
---

# gnd-skydome - the coding standard

Read `CODE_STYLE.md` (the reasons and the examples) before writing a server or anything that loads
a resource. The rules:

* **A server is a singleton, never a class of static functions.** A C++ Engine singleton or a
  GDScript autoload the addon's plugin adds (`add_autoload_singleton()`). Never a `class_name` of
  `static func`s and `static var`s: nothing can extend it, replace it or start it afresh. A game of
  more extends a server by its subclass registered under the same name in its own project, or by
  components set on it. Never add a static function or variable to such a class; one found is
  reported to the operator, with a proposal to make it a singleton - not worked around.
* **Nothing is loaded in a constructor, and no lazy cache stands in for it.** Whoever makes or
  owns an object hands it what it needs through an explicit API (`*_set_*`), set by the scene
  that owns it.

Before committing: no new `static var` or `static func` on a server, registry or manager; no
`load()` / `preload()` / `ResourceLoader` in a constructor, `_init()`, a registration or a
first-use branch of one.
