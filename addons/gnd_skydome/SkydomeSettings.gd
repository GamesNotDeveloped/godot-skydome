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


## Project setting value, or the Skydome property default when it isn't set.
static func get_value(property: StringName) -> Variant:
    var skydome_script: Script = load("res://addons/gnd_skydome/Skydome.gd")
    return ProjectSettings.get_setting(PREFIX + property, skydome_script.get_property_default_value(property))
