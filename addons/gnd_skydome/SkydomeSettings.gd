@tool
class_name SkydomeSettings

## Project settings (PREFIX + property) with the look of every Skydome that has
## apply_project_settings enabled. Registered by the plugin with Skydome's own defaults.

const PREFIX := "gnd_skydome/"
const PROPERTIES: Array[StringName] = [
    &"day_light_energy",
    &"shader_zenith_color",
    &"shader_horizon_height",
    &"day_ambient_energy",
    &"day_ambient_sky_contribution",
    &"day_vol_fog_density",
    &"shader_night_sky_energy",
    &"night_vol_fog_density",
    &"vol_fog_density_boost",
    &"clouds_light_occlusion",
    &"clouds_color_shadow",
    &"clouds_shadow_angular_distance_clear",
    &"clouds_evolution_strength",
    &"clouds_evolution_scale",
    &"clouds_scroll_b",
    &"sun_halo_strength",
    &"sun_atmosphere_strength",
    &"moon_glow_strength",
    &"moon_glow_size",
    &"shader_atmosphere_sunset_boost",
    &"day_full_elevation",
    &"sunset_fade_start_elevation",
    &"sunset_fade_end_elevation",
    &"sunshafts_enabled",
    &"sunshafts_intensity",
]


static func register() -> void:
    var skydome_script: Script = load("res://addons/gnd_skydome/Skydome.gd")
    for property in PROPERTIES:
        var setting := PREFIX + property
        var default_value: Variant = skydome_script.get_property_default_value(property)
        if not ProjectSettings.has_setting(setting):
            ProjectSettings.set_setting(setting, default_value)
        ProjectSettings.add_property_info({"name": setting, "type": typeof(default_value)})
        ProjectSettings.set_initial_value(setting, default_value)


## Project setting value, or [param fallback] when it isn't set.
##
## The settings only exist where register() has run, which is the editor - an EditorPlugin is the
## only kind Godot loads, so an exported game has none of them unless they were written into
## project.godot, and set_initial_value() deliberately keeps the untouched ones out of that file.
## The fallback must therefore not come from Script.get_property_default_value(): that returns
## **null** for every property of a script compiled into an exported pck, because the default only
## exists in the source. Callers pass their own current value, which is the property's initialiser.
static func get_value(property: StringName, fallback: Variant = null) -> Variant:
    return ProjectSettings.get_setting(PREFIX + property, fallback)
