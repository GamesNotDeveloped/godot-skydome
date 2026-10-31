@tool
class_name Skydome
extends Node

## A sky in the scene, as a Light3D is a light: it keeps the parameters it is tuned with in the
## inspector, saved with the scene, and sets them on its SkydomeServer sky (get_rid()), which draws
## it. The game and the weather set theirs on that sky as they go, past the node
## (SkydomeServer.skydome_set_param()), so nothing of theirs reaches the scene; a parameter set here
## anew takes the place of theirs, and param_changed tells them to set theirs again.

## [param name] set here
signal param_changed(name: StringName)

## What the sky draws into; both empty - whoever owns the sky binds it (SkydomeServer.skydome_bind())
@export_node_path("WorldEnvironment") var world_environment_path: NodePath:
    set(v):
        world_environment_path = v
        _bind()
@export_node_path("DirectionalLight3D") var directional_light_path: NodePath:
    set(v):
        directional_light_path = v
        _bind()

var _rid: RID = SkydomeServer.skydome_create()

@export_group("Time & Date")
@export_range(1, 365) var day_of_year: int = 180:
    set(v):
        day_of_year = v
        _set_param(&"day_of_year", v)
@export_range(0.0, 24.0) var time_of_day: float = 12.0:
    set(v):
        time_of_day = v
        _set_param(&"time_of_day", v)
@export_range(-90.0, 90.0) var latitude: float = 50.0:
    set(v):
        latitude = v
        _set_param(&"latitude", v)
@export var time_transition_duration: float = 1.0:
    set(v):
        time_transition_duration = v
        _set_param(&"time_transition_duration", v)

@export_group("Performance")
@export var shader_high_quality_sky: bool = true:
    set(v):
        shader_high_quality_sky = v
        _set_param(&"shader_high_quality_sky", v)

@export_group("Sunset", "sunset")
## Sun elevation the sunset colours start to fade at and are gone above. Light reddens noticeably
## only below a few degrees; a wide window (it used to reach 23.6 degrees) keeps a whole winter day
## at mid latitudes orange, where the sun never climbs higher - and 4 to 10 degrees had the whole sky
## pink with the sun still 4 degrees up, when only the horizon under it yellows.
@export_range(0.0, 45.0, 0.1, "suffix:°") var sunset_fade_start_elevation: float = 1.0:
    set(v):
        sunset_fade_start_elevation = v
        _set_param(&"sunset_fade_start_elevation", v)
@export_range(0.0, 45.0, 0.1, "suffix:°") var sunset_fade_end_elevation: float = 8.0:
    set(v):
        sunset_fade_end_elevation = v
        _set_param(&"sunset_fade_end_elevation", v)
## Sun elevation the sun's disc starts to redden at and keeps the day's colour above - its own
## window, higher than the sky's: following the sky's the disc stood pale pink 3 to 8 degrees up
@export_range(0.0, 45.0, 0.1, "suffix:°") var sunset_disc_fade_start_elevation: float = 4.0:
    set(v):
        sunset_disc_fade_start_elevation = v
        _set_param(&"sunset_disc_fade_start_elevation", v)
@export_range(0.0, 45.0, 0.1, "suffix:°") var sunset_disc_fade_end_elevation: float = 10.0:
    set(v):
        sunset_disc_fade_end_elevation = v
        _set_param(&"sunset_disc_fade_end_elevation", v)
@export_subgroup("Light", "sunset_light")
@export var sunset_light_color: Color = Color(1.0, 0.45, 0.15):
    set(v):
        sunset_light_color = v
        _set_param(&"sunset_light_color", v)
@export_subgroup("Sky", "shader")
@export var shader_sunset_bottom_color: Color = Color(1.0, 0.5, 0.2, 1):
    set(v):
        shader_sunset_bottom_color = v
        _set_param(&"shader_sunset_bottom_color", v)
@export var shader_sunset_horizon_color: Color = Color(0.8, 0.2, 0.05, 1):
    set(v):
        shader_sunset_horizon_color = v
        _set_param(&"shader_sunset_horizon_color", v)
@export var shader_sunset_zenith_color: Color = Color(0.4, 0.3, 0.5, 1):
    set(v):
        shader_sunset_zenith_color = v
        _set_param(&"shader_sunset_zenith_color", v)
@export var shader_sunset_cloud_color: Color = Color(1.0, 0.4, 0.15, 1):
    set(v):
        shader_sunset_cloud_color = v
        _set_param(&"shader_sunset_cloud_color", v)
## The sky under a heavy cover (sky_overcast), lighter towards the horizon and darker overhead: it
## takes the place of the day's and the sunset's colours as the cover thickens
@export var shader_overcast_sky_color: Color = Color(0.55, 0.58, 0.62, 1):
    set(v):
        shader_overcast_sky_color = v
        _set_param(&"shader_overcast_sky_color", v)

@export_group("Day", "day")
## Sun elevation the day values are reached in full at; below it they blend with the night ones
## (down to 11.5 degrees under the horizon). It used to be 17.5 degrees, which a winter sun at mid
## latitudes stays under for most of the day - an early afternoon then already took a share of the
## night fog, which is many times denser.
@export_range(0.0, 45.0, 0.1, "suffix:°") var day_full_elevation: float = 6.0:
    set(v):
        day_full_elevation = v
        _set_param(&"day_full_elevation", v)
@export_subgroup("Light", "day_light")
@export var day_light_energy: float = 1.28:
    set(v):
        day_light_energy = v
        _set_param(&"day_light_energy", v)
@export var day_light_color: Color = Color(1.0, 0.93, 0.85):
    set(v):
        day_light_color = v
        _set_param(&"day_light_color", v)
@export_subgroup("Sky", "shader")
@export var shader_lower_sky_color: Color = Color(0.655, 0.706, 0.79, 1):
    set(v):
        shader_lower_sky_color = v
        _set_param(&"shader_lower_sky_color", v)
@export var shader_horizon_color: Color = Color(0.832, 0.86, 0.886, 1):
    set(v):
        shader_horizon_color = v
        _set_param(&"shader_horizon_color", v)
@export var shader_zenith_color: Color = Color(0.2373352, 0.4190016, 0.7890625, 1):
    set(v):
        shader_zenith_color = v
        _set_param(&"shader_zenith_color", v)
@export var shader_sky_energy: float = 1.0:
    set(v):
        shader_sky_energy = v
        _set_param(&"shader_sky_energy", v)
@export var shader_horizon_height: float = 0.05:
    set(v):
        shader_horizon_height = v
        _set_param(&"shader_horizon_height", v)
@export var shader_horizon_softness: float = 0.24:
    set(v):
        shader_horizon_softness = v
        _set_param(&"shader_horizon_softness", v)
@export var shader_zenith_curve: float = 0.405:
    set(v):
        shader_zenith_curve = v
        _set_param(&"shader_zenith_curve", v)
@export var shader_horizon_glow_strength: float = 1.004:
    set(v):
        shader_horizon_glow_strength = v
        _set_param(&"shader_horizon_glow_strength", v)
@export_subgroup("Rainbow", "rainbow")
@export_range(0.0, 2.0, 0.001) var rainbow_intensity: float = 0.0:
    set(v):
        rainbow_intensity = v
        _set_param(&"rainbow_intensity", v)
@export_range(0.0, 2.0, 0.001) var rainbow_secondary_intensity: float = 0.35:
    set(v):
        rainbow_secondary_intensity = v
        _set_param(&"rainbow_secondary_intensity", v)
@export_subgroup("Ambient", "day_ambient")
@export var day_ambient_color: Color = Color(0.91, 0.85, 0.69):
    set(v):
        day_ambient_color = v
        _set_param(&"day_ambient_color", v)
@export var day_ambient_energy: float = 1.5:
    set(v):
        day_ambient_energy = v
        _set_param(&"day_ambient_energy", v)
@export var day_ambient_sky_contribution: float = 0.25:
    set(v):
        day_ambient_sky_contribution = v
        _set_param(&"day_ambient_sky_contribution", v)
@export_subgroup("Fog", "day_fog")
@export var day_fog_color: Color = Color(1.0, 0.95, 0.91):
    set(v):
        day_fog_color = v
        _set_param(&"day_fog_color", v)
@export var day_fog_density: float = 0.005:
    set(v):
        day_fog_density = v
        _set_param(&"day_fog_density", v)
@export var day_fog_sky_affect: float = 0.15:
    set(v):
        day_fog_sky_affect = v
        _set_param(&"day_fog_sky_affect", v)
@export var day_fog_distance_begin: float = 2.6:
    set(v):
        day_fog_distance_begin = v
        _set_param(&"day_fog_distance_begin", v)
@export var day_fog_distance: float = 470.0:
    set(v):
        day_fog_distance = v
        _set_param(&"day_fog_distance", v)
@export_subgroup("Volumetric fog", "day_vol_fog")
@export var day_vol_fog_albedo: Color = Color(0.77, 0.74, 0.7):
    set(v):
        day_vol_fog_albedo = v
        _set_param(&"day_vol_fog_albedo", v)
@export var day_vol_fog_density: float = 0.001:
    set(v):
        day_vol_fog_density = v
        _set_param(&"day_vol_fog_density", v)
@export var day_vol_fog_sky_affect: float = 0.5:
    set(v):
        day_vol_fog_sky_affect = v
        _set_param(&"day_vol_fog_sky_affect", v)
@export var day_vol_fog_length: float = 8.0:
    set(v):
        day_vol_fog_length = v
        _set_param(&"day_vol_fog_length", v)
@export var day_vol_fog_ambient_inject: float = 0.04:
    set(v):
        day_vol_fog_ambient_inject = v
        _set_param(&"day_vol_fog_ambient_inject", v)

@export_group("Night", "night")
@export_subgroup("Light", "night_light")
@export var night_light_color: Color = Color(0.6, 0.8, 1.0):
    set(v):
        night_light_color = v
        _set_param(&"night_light_color", v)
@export var night_light_energy: float = 0.2:
    set(v):
        night_light_energy = v
        _set_param(&"night_light_energy", v)
@export_subgroup("Sky", "shader")
@export var shader_night_lower_sky_color: Color = Color(0.03, 0.05, 0.09, 1):
    set(v):
        shader_night_lower_sky_color = v
        _set_param(&"shader_night_lower_sky_color", v)
@export var shader_night_horizon_color: Color = Color(0.03, 0.05, 0.09, 1):
    set(v):
        shader_night_horizon_color = v
        _set_param(&"shader_night_horizon_color", v)
@export var shader_night_zenith_color: Color = Color(0.069, 0.08, 0.109, 1.0):
    set(v):
        shader_night_zenith_color = v
        _set_param(&"shader_night_zenith_color", v)
@export var shader_night_sky_energy: float = 0.3:
    set(v):
        shader_night_sky_energy = v
        _set_param(&"shader_night_sky_energy", v)
@export var shader_stars_color: Color = Color(1.0, 1.0, 1.0, 1):
    set(v):
        shader_stars_color = v
        _set_param(&"shader_stars_color", v)
@export var shader_stars_energy: float = 2.0:
    set(v):
        shader_stars_energy = v
        _set_param(&"shader_stars_energy", v)
@export var shader_stars_size_min: float = 0.01:
    set(v):
        shader_stars_size_min = v
        _set_param(&"shader_stars_size_min", v)
@export var shader_stars_size_max: float = 0.03:
    set(v):
        shader_stars_size_max = v
        _set_param(&"shader_stars_size_max", v)
@export var shader_stars_edge_softness: float = 0.25:
    set(v):
        shader_stars_edge_softness = v
        _set_param(&"shader_stars_edge_softness", v)
@export_subgroup("Ambient", "night_ambient")
@export var night_ambient_color: Color = Color(0.02, 0.03, 0.06):
    set(v):
        night_ambient_color = v
        _set_param(&"night_ambient_color", v)
@export var night_ambient_energy: float = 0.1:
    set(v):
        night_ambient_energy = v
        _set_param(&"night_ambient_energy", v)
@export var night_ambient_sky_contribution: float = 0.8:
    set(v):
        night_ambient_sky_contribution = v
        _set_param(&"night_ambient_sky_contribution", v)
@export_subgroup("Fog", "night_fog")
@export var night_fog_color: Color = Color(0.04, 0.06, 0.12):
    set(v):
        night_fog_color = v
        _set_param(&"night_fog_color", v)
@export var night_fog_density: float = 0.02:
    set(v):
        night_fog_density = v
        _set_param(&"night_fog_density", v)
@export var night_fog_sky_affect: float = 0.15:
    set(v):
        night_fog_sky_affect = v
        _set_param(&"night_fog_sky_affect", v)
@export var night_fog_distance_begin: float = 2.6:
    set(v):
        night_fog_distance_begin = v
        _set_param(&"night_fog_distance_begin", v)
@export var night_fog_distance: float = 200.0:
    set(v):
        night_fog_distance = v
        _set_param(&"night_fog_distance", v)
@export_subgroup("Volumetric fog", "night_vol_fog")
@export var night_vol_fog_albedo: Color = Color(0.15, 0.18, 0.25):
    set(v):
        night_vol_fog_albedo = v
        _set_param(&"night_vol_fog_albedo", v)
@export var night_vol_fog_density: float = 0.05:
    set(v):
        night_vol_fog_density = v
        _set_param(&"night_vol_fog_density", v)
@export var night_vol_fog_ambient_inject: float = 0.1:
    set(v):
        night_vol_fog_ambient_inject = v
        _set_param(&"night_vol_fog_ambient_inject", v)
@export var night_vol_fog_sky_affect: float = 0.5:
    set(v):
        night_vol_fog_sky_affect = v
        _set_param(&"night_vol_fog_sky_affect", v)
@export var night_vol_fog_length: float = 3.0:
    set(v):
        night_vol_fog_length = v
        _set_param(&"night_vol_fog_length", v)

@export_group("Clouds", "clouds")
## Clouds of another kind drawn in the sky (a SkydomeClouds: their shader, their uniforms, their
## effects) instead of Skydome's own, which the clouds_* properties below are of
@export var clouds_renderer: SkydomeClouds:
    set(v):
        clouds_renderer = v
        _set_param(&"clouds_renderer", v)
@export var clouds_coverage: float = 0.405:
    set(v):
        clouds_coverage = v
        _set_param(&"clouds_coverage", v)
## How overcast a weather makes the sky besides the clouds drawn (0 - 1): the rain or the snow
## falling and their haze grey the sky, the sunset and the light as a cover does (sky_overcast), and
## dim the light in full - no cloud shadow on the ground takes a share of it
@export_range(0.0, 1.0, 0.001) var weather_overcast: float = 0.0:
    set(v):
        weather_overcast = v
        _set_param(&"weather_overcast", v)
@export var clouds_opacity: float = 0.85:
    set(v):
        clouds_opacity = v
        _set_param(&"clouds_opacity", v)
@export var clouds_softness: float = 0.2:
    set(v):
        clouds_softness = v
        _set_param(&"clouds_softness", v)
@export_range(0.0, 1.0, 0.001) var clouds_light_energy_overcast: float = 0.5:
    set(v):
        clouds_light_energy_overcast = v
        _set_param(&"clouds_light_energy_overcast", v)
@export_subgroup("Generator", "clouds_generator")
@export var clouds_generator_seed_a: int = 10:
    set(v):
        clouds_generator_seed_a = v
        _set_param(&"clouds_generator_seed_a", v)
@export var clouds_generator_seed_b: int = 100:
    set(v):
        clouds_generator_seed_b = v
        _set_param(&"clouds_generator_seed_b", v)
@export var clouds_generator_frequency_a: float = 1.0:
    set(v):
        clouds_generator_frequency_a = v
        _set_param(&"clouds_generator_frequency_a", v)
@export var clouds_generator_frequency_b: float = 0.8:
    set(v):
        clouds_generator_frequency_b = v
        _set_param(&"clouds_generator_frequency_b", v)

@export_subgroup("Colors", "clouds_color")
@export var clouds_color_light: Color = Color(1, 0.98, 0.95, 1):
    set(v):
        clouds_color_light = v
        _set_param(&"clouds_color_light", v)
@export var clouds_color_shadow: Color = Color(0.4, 0.45, 0.55, 1.0):
    set(v):
        clouds_color_shadow = v
        _set_param(&"clouds_color_shadow", v)
@export_subgroup("Shadow", "clouds_shadow")
@export var clouds_shadow_angular_distance_clear: float = 0.5:
    set(v):
        clouds_shadow_angular_distance_clear = v
        _set_param(&"clouds_shadow_angular_distance_clear", v)
@export var clouds_shadow_angular_distance_overcast: float = 15.0:
    set(v):
        clouds_shadow_angular_distance_overcast = v
        _set_param(&"clouds_shadow_angular_distance_overcast", v)
@export_range(0.0, 1.0, 0.001) var clouds_shadow_opacity_clear: float = 1.0:
    set(v):
        clouds_shadow_opacity_clear = v
        _set_param(&"clouds_shadow_opacity_clear", v)
@export_range(0.0, 1.0, 0.001) var clouds_shadow_opacity_overcast: float = 0.8:
    set(v):
        clouds_shadow_opacity_overcast = v
        _set_param(&"clouds_shadow_opacity_overcast", v)
@export_range(0.0, 1.0, 0.001) var clouds_shadow_soften_start: float = 0.28:
    set(v):
        clouds_shadow_soften_start = v
        _set_param(&"clouds_shadow_soften_start", v)
@export_range(0.0, 1.0, 0.001) var clouds_shadow_soften_end: float = 0.9:
    set(v):
        clouds_shadow_soften_end = v
        _set_param(&"clouds_shadow_soften_end", v)
@export_subgroup("Motion", "clouds")
@export var clouds_time_scale: float = 6.0:
    set(v):
        clouds_time_scale = v
        _set_param(&"clouds_time_scale", v)
@export var clouds_wind_direction: Vector2 = Vector2(0.8, 0.3):
    set(v):
        clouds_wind_direction = v
        _set_param(&"clouds_wind_direction", v)
@export var clouds_wind_strength: float = 1.0:
    set(v):
        clouds_wind_strength = v
        _set_param(&"clouds_wind_strength", v)
@export var clouds_wind_speed_multiplier: float = 1.0:
    set(v):
        clouds_wind_speed_multiplier = v
        _set_param(&"clouds_wind_speed_multiplier", v)
@export var clouds_motion_scale: float = 0.12:
    set(v):
        clouds_motion_scale = v
        _set_param(&"clouds_motion_scale", v)
@export var clouds_evolution_speed: float = 0.04:
    set(v):
        clouds_evolution_speed = v
        _set_param(&"clouds_evolution_speed", v)
@export var clouds_evolution_strength: float = 0.18:
    set(v):
        clouds_evolution_strength = v
        _set_param(&"clouds_evolution_strength", v)
@export var clouds_evolution_scale: float = 0.018:
    set(v):
        clouds_evolution_scale = v
        _set_param(&"clouds_evolution_scale", v)
@export var clouds_scroll_a: Vector2 = Vector2(0.0012, 0.00015):
    set(v):
        clouds_scroll_a = v
        _set_param(&"clouds_scroll_a", v)
@export var clouds_scroll_b: Vector2 = Vector2(-0.0018, 0.0004):
    set(v):
        clouds_scroll_b = v
        _set_param(&"clouds_scroll_b", v)
@export_subgroup("Size and shape", "clouds")
@export var clouds_scale_a: Vector2 = Vector2(0.045, 0.055):
    set(v):
        clouds_scale_a = v
        _set_param(&"clouds_scale_a", v)
@export var clouds_scale_b: Vector2 = Vector2(0.082, 0.125):
    set(v):
        clouds_scale_b = v
        _set_param(&"clouds_scale_b", v)
@export_subgroup("Advanced", "clouds")
@export var clouds_plane_height: float = 0.187:
    set(v):
        clouds_plane_height = v
        _set_param(&"clouds_plane_height", v)
@export var clouds_plane_curve: float = 0.595:
    set(v):
        clouds_plane_curve = v
        _set_param(&"clouds_plane_curve", v)
@export var clouds_warp_strength: float = 0.053:
    set(v):
        clouds_warp_strength = v
        _set_param(&"clouds_warp_strength", v)
@export var clouds_horizon_fade: float = 0.481:
    set(v):
        clouds_horizon_fade = v
        _set_param(&"clouds_horizon_fade", v)
@export var clouds_top_fade: float = 0.118:
    set(v):
        clouds_top_fade = v
        _set_param(&"clouds_top_fade", v)
@export var clouds_forward_scatter: float = 1.5:
    set(v):
        clouds_forward_scatter = v
        _set_param(&"clouds_forward_scatter", v)
@export var clouds_backscatter: float = 0.390:
    set(v):
        clouds_backscatter = v
        _set_param(&"clouds_backscatter", v)
## Share of the sun's or the moon's light a full cloud cover takes away. Without it an overcast
## night stays moonlit: the clouds cooled the light and softened its shadows, but never dimmed it.
@export_range(0.0, 1.0, 0.01) var clouds_light_occlusion: float = 0.65:
    set(v):
        clouds_light_occlusion = v
        _set_param(&"clouds_light_occlusion", v)
## Share of the ambient light a full cloud cover takes away - the sky's light, which an overcast dims
## far less than the sun's
@export_range(0.0, 1.0, 0.01) var clouds_ambient_occlusion: float = 0.24:
    set(v):
        clouds_ambient_occlusion = v
        _set_param(&"clouds_ambient_occlusion", v)
## Share of the sky's own brightness a full cloud cover takes away, by day and by night
@export_range(0.0, 1.0, 0.01) var clouds_sky_occlusion: float = 0.46:
    set(v):
        clouds_sky_occlusion = v
        _set_param(&"clouds_sky_occlusion", v)
@export_range(0.0, 1.0, 0.01) var clouds_night_sky_occlusion: float = 0.34:
    set(v):
        clouds_night_sky_occlusion = v
        _set_param(&"clouds_night_sky_occlusion", v)
## The fog's light under a full cloud cover by day - the grey of the clouds at the horizon, which the
## clear day's fog colour gives way to as the cover grows; at night as dim as the night's fog is
@export var clouds_fog_color: Color = Color(0.66, 0.69, 0.73):
    set(v):
        clouds_fog_color = v
        _set_param(&"clouds_fog_color", v)
@export var clouds_sun_occlusion: float = 0.406:
    set(v):
        clouds_sun_occlusion = v
        _set_param(&"clouds_sun_occlusion", v)

@export_group("Sun", "sun")
@export var sun_day_color: Color = Color(1, 0.98, 0.9, 1):
    set(v):
        sun_day_color = v
        _set_param(&"sun_day_color", v)
@export var sun_sunset_color: Color = Color(1.0, 0.4, 0.1, 1):
    set(v):
        sun_sunset_color = v
        _set_param(&"sun_sunset_color", v)
@export var sun_disk_size: float = 0.04:
    set(v):
        sun_disk_size = v
        _set_param(&"sun_disk_size", v)
@export_range(0.0, 50.0, 0.01) var sun_seasonal_size_variation: float = 30.0:
    set(v):
        sun_seasonal_size_variation = v
        _set_param(&"sun_seasonal_size_variation", v)
@export var sun_disk_softness: float = 0.2:
    set(v):
        sun_disk_softness = v
        _set_param(&"sun_disk_softness", v)
@export var sun_disk_strength: float = 2.0:
    set(v):
        sun_disk_strength = v
        _set_param(&"sun_disk_strength", v)
@export var sun_halo_size: float = 0.2:
    set(v):
        sun_halo_size = v
        _set_param(&"sun_halo_size", v)
@export var sun_halo_strength: float = 0.5:
    set(v):
        sun_halo_strength = v
        _set_param(&"sun_halo_strength", v)
@export var sun_atmosphere_size: float = 0.4:
    set(v):
        sun_atmosphere_size = v
        _set_param(&"sun_atmosphere_size", v)
@export var sun_atmosphere_strength: float = 0.2:
    set(v):
        sun_atmosphere_strength = v
        _set_param(&"sun_atmosphere_strength", v)
@export var sun_energy_scale: float = 0.8:
    set(v):
        sun_energy_scale = v
        _set_param(&"sun_energy_scale", v)

@export_group("Moon", "moon")
@export var moon_texture: Texture2D:
    set(v):
        moon_texture = v
        _set_param(&"moon_texture", v)
@export var moon_color: Color = Color(0.9, 0.95, 1.0, 1):
    set(v):
        moon_color = v
        _set_param(&"moon_color", v)
@export var moon_size: float = 1.0:
    set(v):
        moon_size = v
        _set_param(&"moon_size", v)
@export var moon_glow_strength: float = 0.1:
    set(v):
        moon_glow_strength = v
        _set_param(&"moon_glow_strength", v)
## The soft corona a thin cloud in front of the moon glows with, gone under a thick cover
@export var moon_corona_strength: float = 0.2:
    set(v):
        moon_corona_strength = v
        _set_param(&"moon_corona_strength", v)
@export var moon_eclipse_size: float = 0.8:
    set(v):
        moon_eclipse_size = v
        _set_param(&"moon_eclipse_size", v)
@export_range(0.1, 4.0) var moon_glow_size: float = 1.0:
    set(v):
        moon_glow_size = v
        _set_param(&"moon_glow_size", v)

@export_group("Sunshafts", "sunshafts")
@export var sunshafts_enabled: bool = true:
    set(v):
        sunshafts_enabled = v
        _set_param(&"sunshafts_enabled", v)
@export var sunshafts_distance: float = 3000.0:
    set(v):
        sunshafts_distance = v
        _set_param(&"sunshafts_distance", v)
@export_range(0.0, 4.0, 0.01, "or_greater") var sunshafts_intensity: float = 1.0:
    set(v):
        sunshafts_intensity = v
        _set_param(&"sunshafts_intensity", v)
@export var sunshafts_moon_color: Color = Color(0.6, 0.7, 1.0, 1.0):
    set(v):
        sunshafts_moon_color = v
        _set_param(&"sunshafts_moon_color", v)
@export var sunshafts_shaft_color: Color = Color(0.718, 0.637, 0.379, 1):
    set(v):
        sunshafts_shaft_color = v
        _set_param(&"sunshafts_shaft_color", v)
@export var sunshafts_density: float = 0.485:
    set(v):
        sunshafts_density = v
        _set_param(&"sunshafts_density", v)
@export var sunshafts_bright_threshold: float = 0.182:
    set(v):
        sunshafts_bright_threshold = v
        _set_param(&"sunshafts_bright_threshold", v)
@export var sunshafts_weight: float = 0.0355:
    set(v):
        sunshafts_weight = v
        _set_param(&"sunshafts_weight", v)
@export var sunshafts_decay: float = 0.93:
    set(v):
        sunshafts_decay = v
        _set_param(&"sunshafts_decay", v)
@export var sunshafts_exposure: float = 1.59:
    set(v):
        sunshafts_exposure = v
        _set_param(&"sunshafts_exposure", v)
@export var sunshafts_max_radius: float = 1.377:
    set(v):
        sunshafts_max_radius = v
        _set_param(&"sunshafts_max_radius", v)
@export_subgroup("Clouds", "sunshafts_cloud")
## How much full cloud cover dims the shafts (0 - not at all, 1 - almost completely)
@export_range(0.0, 1.0, 0.001) var sunshafts_cloud_occlusion: float = 0.85:
    set(v):
        sunshafts_cloud_occlusion = v
        _set_param(&"sunshafts_cloud_occlusion", v)
## Shape of that dimming: 1 is linear, below 1 keeps the shafts visible longer under clouds,
## above 1 makes them disappear sooner
@export_range(0.1, 4.0, 0.01) var sunshafts_cloud_falloff: float = 1.0:
    set(v):
        sunshafts_cloud_falloff = v
        _set_param(&"sunshafts_cloud_falloff", v)

@export_subgroup("Performance", "sunshafts_perf")
@export_range(4, 100) var sunshafts_perf_sample_count: int = 8:
    set(v):
        sunshafts_perf_sample_count = v
        _set_param(&"sunshafts_perf_sample_count", v)
@export_range(0.0, 2.0, 0.001) var sunshafts_perf_dither_strength: float = 1.4:
    set(v):
        sunshafts_perf_dither_strength = v
        _set_param(&"sunshafts_perf_dither_strength", v)

@export_group("Storm")
@export_range(0.0, 2.0, 0.01) var storm_flash_sky_energy: float = 0.18:
    set(v):
        storm_flash_sky_energy = v
        _set_param(&"storm_flash_sky_energy", v)
@export_range(0.0, 2.0, 0.01) var storm_flash_night_sky_energy: float = 0.08:
    set(v):
        storm_flash_night_sky_energy = v
        _set_param(&"storm_flash_night_sky_energy", v)
@export_range(0.0, 10.0, 0.01) var storm_flash_light_energy_clear: float = 0.9:
    set(v):
        storm_flash_light_energy_clear = v
        _set_param(&"storm_flash_light_energy_clear", v)
@export_range(0.0, 10.0, 0.01) var storm_flash_light_energy_overcast: float = 5.6:
    set(v):
        storm_flash_light_energy_overcast = v
        _set_param(&"storm_flash_light_energy_overcast", v)
@export var storm_flash_light_color: Color = Color(0.83, 0.89, 1.0, 1.0):
    set(v):
        storm_flash_light_color = v
        _set_param(&"storm_flash_light_color", v)
@export var storm_flash_ambient_color: Color = Color(0.76, 0.82, 0.96, 1.0):
    set(v):
        storm_flash_ambient_color = v
        _set_param(&"storm_flash_ambient_color", v)
@export_range(0.0, 2.0, 0.01) var storm_flash_ambient_energy_base: float = 0.28:
    set(v):
        storm_flash_ambient_energy_base = v
        _set_param(&"storm_flash_ambient_energy_base", v)
@export_range(0.0, 2.0, 0.01) var storm_flash_ambient_energy_overcast_boost: float = 0.35:
    set(v):
        storm_flash_ambient_energy_overcast_boost = v
        _set_param(&"storm_flash_ambient_energy_overcast_boost", v)
@export_range(0.0, 1.0, 0.001) var storm_flash_ambient_blend: float = 0.4:
    set(v):
        storm_flash_ambient_blend = v
        _set_param(&"storm_flash_ambient_blend", v)
@export var storm_flash_fog_color: Color = Color(0.74, 0.82, 0.96, 1.0):
    set(v):
        storm_flash_fog_color = v
        _set_param(&"storm_flash_fog_color", v)
@export var storm_flash_volumetric_color: Color = Color(0.58, 0.66, 0.82, 1.0):
    set(v):
        storm_flash_volumetric_color = v
        _set_param(&"storm_flash_volumetric_color", v)
@export_range(0.0, 1.0, 0.001) var storm_flash_volumetric_blend: float = 0.35:
    set(v):
        storm_flash_volumetric_blend = v
        _set_param(&"storm_flash_volumetric_blend", v)

@export_group("Fog")
@export var fog_mode: SkydomeSky.FogModeOverride = SkydomeSky.FogModeOverride.UNMANAGED:
    set(v):
        fog_mode = v
        _set_param(&"fog_mode", v)
@export_range(0.0, 1.0, 0.001) var fog_density: float = 0.0:
    set(v):
        fog_density = v
        _set_param(&"fog_density", v)
## Extinction per metre a full fog_density adds to the volumetric fog, at the default fog distances
@export_range(0.0, 1.0, 0.001, "or_greater") var vol_fog_density_boost: float = 0.05:
    set(v):
        vol_fog_density_boost = v
        _set_param(&"vol_fog_density_boost", v)
@export_range(0.0, 1.0, 0.001) var fog_sky_affect_intensity: float = 1.0:
    set(v):
        fog_sky_affect_intensity = v
        _set_param(&"fog_sky_affect_intensity", v)
## The environment's fog_sun_scatter: the fog brightened by the sun's light towards it, the
## terrain's and the sky's alike (Godot's fog of both)
@export_range(0.0, 2.0, 0.001) var fog_sun_scatter: float = 0.0:
    set(v):
        fog_sun_scatter = v
        _set_param(&"fog_sun_scatter", v)
## What the sunrise and the sunset add to fog_sun_scatter: their light lies in the fog towards the
## sun, not all round - the fog over the whole sky took it and greyed the dome orange
@export_range(0.0, 2.0, 0.001) var fog_sunset_sun_scatter: float = 0.5:
    set(v):
        fog_sunset_sun_scatter = v
        _set_param(&"fog_sunset_sun_scatter", v)
@export_range(0.0, 1.0, 0.001) var vol_fog_sky_affect_intensity: float = 1.0:
    set(v):
        vol_fog_sky_affect_intensity = v
        _set_param(&"vol_fog_sky_affect_intensity", v)
@export_range(0.0, 1.0, 0.001) var storm_fog_emission_scale: float = 1.0:
    set(v):
        storm_fog_emission_scale = v
        _set_param(&"storm_fog_emission_scale", v)
@export_range(0.0, 1.0, 0.001) var lightning_flash: float = 0.0:
    set(v):
        lightning_flash = v
        _set_param(&"lightning_flash", v)

@export_group("Debug")
@export var force_refresh: bool = false:
    set(v):
        force_refresh = v
        _set_param(&"force_refresh", v)
@export_range(0.0, 1.0) var moon_phase_debug: float:
    set(v):
        moon_phase_debug = v
        _set_param(&"moon_phase_debug", v)

@export_group("Sky Shader: Atmosphere")
@export var shader_atmosphere_horizon_level: float = -0.035:
    set(v):
        shader_atmosphere_horizon_level = v
        _set_param(&"shader_atmosphere_horizon_level", v)
@export var shader_atmosphere_height: float = 0.24:
    set(v):
        shader_atmosphere_height = v
        _set_param(&"shader_atmosphere_height", v)
@export var shader_atmosphere_density: float = 0.46:
    set(v):
        shader_atmosphere_density = v
        _set_param(&"shader_atmosphere_density", v)
@export var shader_atmosphere_sun_scatter: float = 0.34:
    set(v):
        shader_atmosphere_sun_scatter = v
        _set_param(&"shader_atmosphere_sun_scatter", v)
@export var shader_atmosphere_sunset_boost: float = 1.35:
    set(v):
        shader_atmosphere_sunset_boost = v
        _set_param(&"shader_atmosphere_sunset_boost", v)



## The sky this node sets its parameters on
func get_rid() -> RID:
    return _rid


## [param name] set on the sky past this node (SkydomeServer.skydome_set_param()): what the
## weather sets as it goes, which the scene never saves, until set here anew
func set_sky_param(name: StringName, value: Variant) -> void:
    SkydomeServer.skydome_set_param(_rid, name, value)


## [param name] as the sky draws it
func get_sky_param(name: StringName) -> Variant:
    return SkydomeServer.skydome_get_param(_rid, name)


## The clouds' wind taken at once, not eased into
func apply_wind_now() -> void:
    SkydomeServer.skydome_apply_wind_now(_rid)


func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        SkydomeServer.skydome_free(_rid)


func _enter_tree() -> void:
    _bind()


func _bind() -> void:
    if not is_inside_tree() or (world_environment_path.is_empty() and directional_light_path.is_empty()):
        return
    SkydomeServer.skydome_bind(_rid, get_node_or_null(world_environment_path) as WorldEnvironment,
        get_node_or_null(directional_light_path) as DirectionalLight3D)


func _set_param(name: StringName, value: Variant) -> void:
    SkydomeServer.skydome_set_param(_rid, name, value)
    param_changed.emit(name)
