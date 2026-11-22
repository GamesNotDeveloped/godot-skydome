@tool
class_name SkydomeSettings
extends RefCounted

## The project settings of the skies (SkydomeSky), with their defaults. The plugin registers them in
## the editor (register()); an exported game has one only if it was written into project.godot, so
## each is read with its default. A pure helper, it keeps no state.

## Whether the sky draws the sun, the moon and the stars below the horizon too, where the ground
## hides them - seen where nothing covers the lower half of the sky, through a see-through water
## with no bed under it, for one
const SHOW_BELOW_HORIZON := "gnd_skydome/sky/show_below_horizon"
const SHOW_BELOW_HORIZON_DEFAULT := true


## The settings in the editor's Project Settings; one left at its default stays out of
## project.godot
static func register() -> void:
    if not ProjectSettings.has_setting(SHOW_BELOW_HORIZON):
        ProjectSettings.set_setting(SHOW_BELOW_HORIZON, SHOW_BELOW_HORIZON_DEFAULT)
    ProjectSettings.add_property_info({"name": SHOW_BELOW_HORIZON, "type": TYPE_BOOL})
    ProjectSettings.set_initial_value(SHOW_BELOW_HORIZON, SHOW_BELOW_HORIZON_DEFAULT)


static func get_show_below_horizon() -> bool:
    return ProjectSettings.get_setting(SHOW_BELOW_HORIZON, SHOW_BELOW_HORIZON_DEFAULT)
