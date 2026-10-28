# Skydome architecture

- Controls Environment
- Controls DirectionalLight
- Adds/removes custom compositor effects
- Has no dependencies on other plugins/addons/systems

* REQUIRED, ABSOLUTE: **a server is a singleton, never a class of static functions** - a C++
  Engine singleton or a GDScript autoload its plugin adds, never a `class_name` of `static func`s
  and `static var`s; none is added to such a class, one found is reported - see `CODE_STYLE.md`
* REQUIRED, ABSOLUTE: **nothing is loaded in a constructor, and no lazy cache stands in for it**:
  whoever makes or owns an object hands it what it needs through an explicit API (`*_set_*`) - see
  `CODE_STYLE.md`
