## Code style

The rules every line of gnd-skydome keeps, whatever the language; `AGENTS.md` names them, here is why and
how.

### A server is a singleton, never a class of static functions

A server, a registry, a manager or any system asked for by its name is one instance: a C++ class
registered as an Engine singleton, or a GDScript autoload the addon's plugin adds
(`add_autoload_singleton()`). Never a `class_name` of `static func`s and `static var`s: every call
of such a class is bound to it, so nothing can extend it, replace it or start it afresh. A
singleton can be extended - a game of more registers its subclass under the same name in its own
project, or sets components on it (a ground model, a wind model) - it can be freed with its world,
and a test gets a fresh one. A static function or a static variable is never added to such a class;
one found is reported, with a proposal to make it a singleton. A static function that keeps no
state and serves no one by name - a pure helper - is not a server.

```gdscript
# not this - a server nobody can extend, replace or start afresh
class_name WeatherServer
extends RefCounted
static var _states := {}
static func get_weather_state(world_3d: World3D) -> Dictionary:

# this - the plugin adds it: add_autoload_singleton("WeatherServer", "res://addons/gnd_weather/weather_server.gd"),
# and a game of more registers its subclass under the same name
extends Node
var _states := {}
func get_weather_state(world_3d: World3D) -> Dictionary:
```

### Nothing is loaded in a constructor, and no lazy cache stands in for it

A server, a backend, a plugin - anything made as the library or the game starts - loads no
resource as it is made (its constructor, `_init()`, its registration), nor the first time it is
asked for one. Whoever makes or owns an object hands it what it needs through an explicit API
(`*_set_*`), set by the scene that owns it. A material loaded as a server
is made compiles its shader before the project's shader globals exist ("Global uniform ... does not
exist" in an editor's or an export's import); a cache filled on the first call hides when, where
and by whose rule the thing was chosen.

```cpp
// not this - loaded as the server is made
WeatherRenderingServer::WeatherRenderingServer() {
    snow_overlay = ResourceLoader::get_singleton()->load(SNOW_OVERLAY_PATH);
}
// nor this - the same load, the first time it is asked for
if (snow_overlay.is_null()) {
    snow_overlay = ResourceLoader::get_singleton()->load(SNOW_OVERLAY_PATH);
}
// this - the scene hands each surface what its snow is drawn with:
// WeatherRenderingServer.surface_set_snow_material(surface, material)
```
