@tool
class_name Skydome
extends Node

signal time_changed(day: int, time: float)
signal day_changed(day: int)

const SUN_SHAFTS_EFFECT_SCRIPT := preload("res://addons/gnd_skydome/SunShaftsCompositorEffect.gd")
const FILMIC_SKY_SHADER := preload("res://addons/gnd_skydome/filmic_procedural_sky.gdshader")
const EDITOR_ACCESS_SCRIPT_PATH := "res://addons/gnd_skydome/EditorAccess.gd"

var _environment: Environment
var _rendered_day: int = 180
var _rendered_time: float = 12.0
var _time_transition_active: bool = false
var _time_transition_wrapped: bool = false
var _time_transition_target_total_hours: float = 0.0
var _time_transition_target_unwrapped_time: float = 0.0
var _time_transition_speed_hours_per_second: float = 0.0
var _last_cloud_total_hours: float = 0.0
var _cloud_motion_time: float = 0.0
var _cloud_evolution_time: float = 0.0
var _sky_material: ShaderMaterial
var _compositor_effect: CompositorEffect
var _light: DirectionalLight3D
var _is_ready: bool = false
var _is_daytime: bool = true
var _day_blend: float = 1.0
var _sunset_blend: float = 0.0
var _cloud_texture_a: Texture2D
var _cloud_texture_b: Texture2D
var _camera: Camera3D
var _viewport_size: Vector2 = Vector2.ZERO
var _editor_access = null

func _error(x):
    push_error("[Skydome] "+x)

func _success(x):
    print_rich("[color=green][Skydome][/color] "+x)

@export_node_path("DirectionalLight3D") var directional_light_path: NodePath:
    set(v):
        directional_light_path = v
        _refresh()
@export_node_path("WorldEnvironment") var world_environment_path: NodePath:
    set(v):
        world_environment_path = v
        _refresh()

@export_group("Time & Date")
@export_range(1, 365) var day_of_year: int = 180:
    set(v):
        day_of_year = v
        _request_time_update()
@export_range(0.0, 24.0) var time_of_day: float = 12.0:
    set(v):
        time_of_day = v
        _request_time_update()
@export_range(-90.0, 90.0) var latitude: float = 50.0:
    set(v):
        latitude = v
        _update_sun_transform()
@export var time_transition_duration: float = 1.0

@export_group("Sunset", "sunset")
@export_subgroup("Light", "sunset_light")
@export var sunset_light_color: Color = Color(1.0, 0.45, 0.15):
    set(v):
        sunset_light_color = v
        _update_sun_transform()
@export_subgroup("Sky", "shader")
@export var shader_sunset_bottom_color: Color = Color(1.0, 0.5, 0.2, 1):
    set(v): shader_sunset_bottom_color = v; _set_shader_param("sunset_bottom_color", v)
@export var shader_sunset_horizon_color: Color = Color(0.8, 0.2, 0.05, 1):
    set(v): shader_sunset_horizon_color = v; _set_shader_param("sunset_horizon_color", v)
@export var shader_sunset_zenith_color: Color = Color(0.4, 0.3, 0.5, 1):
    set(v): shader_sunset_zenith_color = v; _set_shader_param("sunset_zenith_color", v)
@export var shader_sunset_cloud_color: Color = Color(1.0, 0.4, 0.15, 1):
    set(v): shader_sunset_cloud_color = v; _set_shader_param("sunset_cloud_color", v)

@export_group("Day", "day")
@export_subgroup("Light", "day_light")
@export var day_light_energy: float = 1.28:
    set(v):
        day_light_energy = v
        _update_sun_transform()
@export var day_light_color: Color = Color(1.0, 0.93, 0.85):
    set(v):
        day_light_color = v
        _update_sun_transform()
@export_subgroup("Sky", "shader")
@export var shader_lower_sky_color: Color = Color(0.655, 0.706, 0.79, 1):
    set(v):
        shader_lower_sky_color = v
        _set_shader_param("lower_sky_color", v)
@export var shader_horizon_color: Color = Color(0.832, 0.86, 0.886, 1):
    set(v):
        shader_horizon_color = v
        _set_shader_param("horizon_color", v)
@export var shader_zenith_color: Color = Color(0.2373352, 0.4190016, 0.7890625, 1):
    set(v):
        shader_zenith_color = v
        _set_shader_param("zenith_color", v)
@export var shader_sky_energy: float = 1.0:
    set(v):
        shader_sky_energy = v
        _set_shader_param("sky_energy", v)
@export var shader_horizon_height: float = 0.05:
    set(v):
        shader_horizon_height = v
        _set_shader_param("horizon_height", v)
@export var shader_horizon_softness: float = 0.24:
    set(v):
        shader_horizon_softness = v
        _set_shader_param("horizon_softness", v)
@export var shader_zenith_curve: float = 0.405:
    set(v):
        shader_zenith_curve = v
        _set_shader_param("zenith_curve", v)
@export var shader_horizon_glow_strength: float = 1.004:
    set(v):
        shader_horizon_glow_strength = v
        _set_shader_param("horizon_glow_strength", v)
@export_subgroup("Rainbow", "rainbow")
@export_range(0.0, 2.0, 0.001) var rainbow_intensity: float = 0.0:
    set(v):
        rainbow_intensity = clampf(v, 0.0, 2.0)
        _set_shader_param("rainbow_intensity", rainbow_intensity)
@export_range(0.0, 2.0, 0.001) var rainbow_secondary_intensity: float = 0.35:
    set(v):
        rainbow_secondary_intensity = clampf(v, 0.0, 2.0)
        _set_shader_param("rainbow_secondary_intensity", rainbow_secondary_intensity)
@export_subgroup("Ambient", "day_ambient")
@export var day_ambient_color: Color = Color(0.91, 0.85, 0.69):
    set(v):  day_ambient_color = v; _update_sun_transform()
@export var day_ambient_energy: float = 1.5:
    set(v):  day_ambient_energy = v; _update_sun_transform()
@export var day_ambient_sky_contribution: float = 0.25:
    set(v):  day_ambient_sky_contribution = v; _update_sun_transform()
@export_subgroup("Fog", "day_fog")
@export var day_fog_color: Color = Color(1.0, 0.95, 0.91):
    set(v):  day_fog_color = v; _update_sun_transform()
@export var day_fog_density: float = 0.005:
    set(v):  day_fog_density = v; _update_sun_transform()
@export var day_fog_sky_affect: float = 0.15:
    set(v):  day_fog_sky_affect = v; _update_sun_transform()
@export var day_fog_distance_begin: float = 2.6:
    set(v):  day_fog_distance_begin = v; _update_sun_transform()
@export var day_fog_distance: float = 470.0:
    set(v):  day_fog_distance = v; _update_sun_transform()
@export_subgroup("Volumetric fog", "day_vol_fog")
@export var day_vol_fog_albedo: Color = Color(0.77, 0.74, 0.7):
    set(v):  day_vol_fog_albedo = v; _update_sun_transform()
@export var day_vol_fog_density: float = 0.001:
    set(v):  day_vol_fog_density = v; _update_sun_transform()
@export var day_vol_fog_sky_affect: float = 0.5:
    set(v):  day_vol_fog_sky_affect = v; _update_sun_transform()
@export var day_vol_fog_length: float = 8.0:
    set(v):  day_vol_fog_length = v; _update_sun_transform()
@export var day_vol_fog_ambient_inject: float = 0.04:
    set(v):  day_vol_fog_ambient_inject = v; _update_sun_transform()

@export_group("Night", "night")
@export_subgroup("Light", "night_light")
@export var night_light_color: Color = Color(0.6, 0.8, 1.0):
    set(v):
        night_light_color = v
        _update_sun_transform()
@export var night_light_energy: float = 0.2:
    set(v):
        night_light_energy = v
        _update_sun_transform()
@export_subgroup("Sky", "shader")
@export var shader_night_lower_sky_color: Color = Color(0.03, 0.05, 0.09, 1):
    set(v):
        shader_night_lower_sky_color = v
        _set_shader_param("night_lower_sky_color", v)
@export var shader_night_horizon_color: Color = Color(0.03, 0.05, 0.09, 1):
    set(v):
        shader_night_horizon_color = v
        _set_shader_param("night_horizon_color", v)
@export var shader_night_zenith_color: Color = Color(0.069, 0.08, 0.109, 1.0):
    set(v):
        shader_night_zenith_color = v
        _set_shader_param("night_zenith_color", v)
@export var shader_night_sky_energy: float = 0.3:
    set(v):
        shader_night_sky_energy = v
        _set_shader_param("night_sky_energy", v)
@export var shader_stars_color: Color = Color(1.0, 1.0, 1.0, 1):
    set(v):
        shader_stars_color = v
        _set_shader_param("stars_color", v)
@export var shader_stars_energy: float = 2.0:
    set(v):
        shader_stars_energy = v
        _set_shader_param("stars_energy", v)
@export var shader_stars_size_min: float = 0.01:
    set(v):
        shader_stars_size_min = v
        _set_shader_param("stars_size_min", v)
@export var shader_stars_size_max: float = 0.03:
    set(v):
        shader_stars_size_max = v
        _set_shader_param("stars_size_max", v)
@export var shader_stars_edge_softness: float = 0.25:
    set(v):
        shader_stars_edge_softness = v
        _set_shader_param("stars_edge_softness", v)
@export_subgroup("Ambient", "night_ambient")
@export var night_ambient_color: Color = Color(0.02, 0.03, 0.06):
    set(v):  night_ambient_color = v; _update_sun_transform()
@export var night_ambient_energy: float = 0.1:
    set(v):  night_ambient_energy = v; _update_sun_transform()
@export var night_ambient_sky_contribution: float = 0.8:
    set(v):  night_ambient_sky_contribution = v; _update_sun_transform()
@export_subgroup("Fog", "night_fog")
@export var night_fog_color: Color = Color(0.04, 0.06, 0.12):
    set(v):  night_fog_color = v; _update_sun_transform()
@export var night_fog_density: float = 0.02:
    set(v):  night_fog_density = v; _update_sun_transform()
@export var night_fog_sky_affect: float = 0.15:
    set(v):  night_fog_sky_affect = v; _update_sun_transform()
@export var night_fog_distance_begin: float = 2.6:
    set(v):  night_fog_distance_begin = v; _update_sun_transform()
@export var night_fog_distance: float = 200.0:
    set(v): night_fog_distance = v; _update_sun_transform()
@export_subgroup("Volumetric fog", "night_vol_fog")
@export var night_vol_fog_albedo: Color = Color(0.15, 0.18, 0.25):
    set(v):  night_vol_fog_albedo = v; _update_sun_transform()
@export var night_vol_fog_density: float = 0.05:
    set(v):  night_vol_fog_density = v; _update_sun_transform()
@export var night_vol_fog_ambient_inject: float = 0.1:
    set(v):  night_vol_fog_ambient_inject = v; _update_sun_transform()
@export var night_vol_fog_sky_affect: float = 0.5:
    set(v):  night_vol_fog_sky_affect = v; _update_sun_transform()
@export var night_vol_fog_length: float = 3.0:
    set(v):  night_vol_fog_length = v; _update_sun_transform()

@export_group("Clouds", "clouds")
@export var clouds_coverage: float = 0.25:
    set(v):
        clouds_coverage = clampf(v, 0.0, 1.0)
        _set_shader_param("cloud_coverage", clouds_coverage)
        _update_sun_transform()
@export var clouds_opacity: float = 0.85:
    set(v):
        clouds_opacity = v
        _set_shader_param("cloud_opacity", v)
@export var clouds_softness: float = 0.2:
    set(v):
        clouds_softness = v
        _set_shader_param("cloud_softness", v)
@export_range(0.0, 1.0, 0.001) var clouds_light_energy_overcast: float = 0.5:
    set(v):
        clouds_light_energy_overcast = clampf(v, 0.0, 1.0)
        _update_sun_transform()
@export_subgroup("Generator", "clouds_generator")
@export var clouds_generator_seed_a: int = 10:
    set(v):
        clouds_generator_seed_a = v
        _init_sky()
@export var clouds_generator_seed_b: int = 100:
    set(v):
        clouds_generator_seed_b = v
        _init_sky()
@export var clouds_generator_frequency_a: float = 1.0:
    set(v):
        clouds_generator_frequency_a = v
        _init_sky()
@export var clouds_generator_frequency_b: float = 0.8:
    set(v):
        clouds_generator_frequency_b = v
        _init_sky()

@export_subgroup("Colors", "clouds_color")
@export var clouds_color_light: Color = Color(1, 0.98, 0.95, 1):
    set(v):
        clouds_color_light = v
        _set_shader_param("cloud_light_color", v)
@export var clouds_color_shadow: Color = Color(0.4, 0.45, 0.55, 1.0):
    set(v):
        clouds_color_shadow = v
        _set_shader_param("cloud_shadow_color", v)
@export_subgroup("Shadow", "clouds_shadow")
@export var clouds_shadow_angular_distance_clear: float = 0.5:
    set(v):
        clouds_shadow_angular_distance_clear = maxf(v, 0.0)
        clouds_shadow_angular_distance_overcast = maxf(clouds_shadow_angular_distance_overcast, clouds_shadow_angular_distance_clear)
        _update_sun_transform()
@export var clouds_shadow_angular_distance_overcast: float = 15.0:
    set(v):
        clouds_shadow_angular_distance_overcast = maxf(v, clouds_shadow_angular_distance_clear)
        _update_sun_transform()
@export_range(0.0, 1.0, 0.001) var clouds_shadow_opacity_clear: float = 1.0:
    set(v):
        clouds_shadow_opacity_clear = clampf(v, 0.0, 1.0)
        _update_sun_transform()
@export_range(0.0, 1.0, 0.001) var clouds_shadow_opacity_overcast: float = 0.8:
    set(v):
        clouds_shadow_opacity_overcast = clampf(v, 0.0, 1.0)
        _update_sun_transform()
@export_range(0.0, 1.0, 0.001) var clouds_shadow_soften_start: float = 0.28:
    set(v):
        clouds_shadow_soften_start = clampf(v, 0.0, 1.0)
        _update_sun_transform()
@export_range(0.0, 1.0, 0.001) var clouds_shadow_soften_end: float = 0.9:
    set(v):
        clouds_shadow_soften_end = clampf(v, 0.0, 1.0)
        _update_sun_transform()
@export_subgroup("Motion", "clouds")
@export var clouds_time_scale: float = 6.0:
    set(v):
        clouds_time_scale = v
        _update_cloud_time()
@export var clouds_wind_direction: Vector2 = Vector2(0.8, 0.3):
    set(v):
        clouds_wind_direction = v
        _update_cloud_wind()
@export var clouds_wind_strength: float = 1.0:
    set(v):
        clouds_wind_strength = maxf(v, 0.0)
        _update_cloud_wind()
@export var clouds_wind_speed_multiplier: float = 1.0:
    set(v):
        clouds_wind_speed_multiplier = v
        _update_cloud_wind()
@export var clouds_motion_scale: float = 0.12:
    set(v):
        clouds_motion_scale = v
        _set_shader_param("cloud_motion_scale", v)
@export var clouds_evolution_speed: float = 0.04
@export var clouds_evolution_strength: float = 0.18:
    set(v):
        clouds_evolution_strength = v
        _set_shader_param("cloud_evolution_strength", v)
@export var clouds_evolution_scale: float = 0.018:
    set(v):
        clouds_evolution_scale = v
        _set_shader_param("cloud_evolution_scale", v)
@export var clouds_scroll_a: Vector2 = Vector2(0.0012, 0.00015):
    set(v):
        clouds_scroll_a = v
        _set_shader_param("cloud_scroll_a", v)
@export var clouds_scroll_b: Vector2 = Vector2(-0.0018, 0.0004):
    set(v):
        clouds_scroll_b = v
        _set_shader_param("cloud_scroll_b", v)
@export_subgroup("Size and shape", "clouds")
@export var clouds_scale_a: Vector2 = Vector2(0.045, 0.055):
    set(v):
        clouds_scale_a = v
        _set_shader_param("cloud_scale_a", v)
@export var clouds_scale_b: Vector2 = Vector2(0.082, 0.125):
    set(v):
        clouds_scale_b = v
        _set_shader_param("cloud_scale_b", v)
@export_subgroup("Advanced", "clouds")
@export var clouds_plane_height: float = 0.187:
    set(v):
        clouds_plane_height = v
        _set_shader_param("cloud_plane_height", v)
@export var clouds_plane_curve: float = 0.595:
    set(v):
        clouds_plane_curve = v
        _set_shader_param("cloud_plane_curve", v)
@export var clouds_warp_strength: float = 0.053:
    set(v):
        clouds_warp_strength = v
        _set_shader_param("cloud_warp_strength", v)
@export var clouds_horizon_fade: float = 0.481:
    set(v):
        clouds_horizon_fade = v
        _set_shader_param("cloud_horizon_fade", v)
@export var clouds_top_fade: float = 0.118:
    set(v):
        clouds_top_fade = v
        _set_shader_param("cloud_top_fade", v)
@export var clouds_forward_scatter: float = 1.5:
    set(v):
        clouds_forward_scatter = v
        _set_shader_param("cloud_forward_scatter", v)
@export var clouds_backscatter: float = 0.390:
    set(v):
        clouds_backscatter = v
        _set_shader_param("cloud_backscatter", v)
@export var clouds_sun_occlusion: float = 0.406:
    set(v):
        clouds_sun_occlusion = v
        _set_shader_param("sun_cloud_occlusion", v)

@export_group("Sun", "sun")
@export var sun_day_color: Color = Color(1, 0.98, 0.9, 1):
    set(v):
        sun_day_color = v
        _set_shader_param("sun_color", v)
@export var sun_sunset_color: Color = Color(1.0, 0.4, 0.1, 1):
    set(v): sun_sunset_color = v; _set_shader_param("sunset_sun_color", v)
@export var sun_disk_size: float = 0.04:
    set(v):
        sun_disk_size = v
        _set_shader_param("sun_disk_size", v)
@export_range(0.0, 50.0, 0.01) var sun_seasonal_size_variation: float = 30.0:
    set(v):
        sun_seasonal_size_variation = v
        _set_shader_param("sun_seasonal_size_variation", v)
@export var sun_disk_softness: float = 0.6:
    set(v):
        sun_disk_softness = v
        _set_shader_param("sun_disk_softness", v)
@export var sun_disk_strength: float = 0.6:
    set(v):
        sun_disk_strength = v
        _set_shader_param("sun_disk_strength", v)
@export var sun_halo_size: float = 0.2:
    set(v):
        sun_halo_size = v
        _set_shader_param("sun_halo_size", v)
@export var sun_halo_strength: float = 0.5:
    set(v):
        sun_halo_strength = v
        _set_shader_param("sun_halo_strength", v)
@export var sun_atmosphere_size: float = 0.4:
    set(v):
        sun_atmosphere_size = v
        _set_shader_param("sun_atmosphere_size", v)
@export var sun_atmosphere_strength: float = 0.2:
    set(v):
        sun_atmosphere_strength = v
        _set_shader_param("sun_atmosphere_strength", v)
@export var sun_energy_scale: float = 0.8:
    set(v):
        sun_energy_scale = v
        _set_shader_param("sun_energy_scale", v)

@export_group("Moon", "moon")
@export var moon_texture: Texture2D:
    set(v): moon_texture = v; _set_shader_param("moon_texture", v)
@export var moon_color: Color = Color(0.9, 0.95, 1.0, 1):
    set(v):
        moon_color = v
        _set_shader_param("moon_color", v)
@export var moon_size: float = 1.0:
    set(v):
        moon_size = v
        _set_shader_param("moon_size", v)
@export var moon_glow_strength: float = 0.1:
    set(v):
        moon_glow_strength = v
        _set_shader_param("moon_glow_strength", v)
@export var moon_eclipse_size: float = 0.8:
    set(v):
        moon_eclipse_size = v
        _set_shader_param("moon_eclipse_size", v)
@export_range(0.1, 4.0) var moon_glow_size: float = 1.0:
    set(v):
        moon_glow_size = v
        _set_shader_param("moon_glow_size", v)

@export_group("Sunshafts", "sunshafts")
@export var sunshafts_enabled: bool = true:
    set(v):
        sunshafts_enabled = v
        _update_effect()
@export var sunshafts_distance: float = 3000.0
@export var sunshafts_moon_color: Color = Color(0.6, 0.7, 1.0, 1.0):
    set(v):
        sunshafts_moon_color = v
        _update_effect()
@export var sunshafts_shaft_color: Color = Color(0.718, 0.637, 0.379, 1):
    set(v):
        sunshafts_shaft_color = v
        _update_effect()
@export var sunshafts_density: float = 0.485:
    set(v):
        sunshafts_density = v
        _update_effect()
@export var sunshafts_bright_threshold: float = 0.182:
    set(v):
        sunshafts_bright_threshold = v
        _update_effect()
@export var sunshafts_weight: float = 0.0355:
    set(v):
        sunshafts_weight = v
        _update_effect()
@export var sunshafts_decay: float = 0.93:
    set(v):
        sunshafts_decay = v
        _update_effect()
@export var sunshafts_exposure: float = 1.59:
    set(v):
        sunshafts_exposure = v
        _update_effect()
@export var sunshafts_max_radius: float = 1.377:
    set(v):
        sunshafts_max_radius = v
        _update_effect()
@export_subgroup("Performance", "sunshafts_perf")
@export_range(4, 100) var sunshafts_perf_sample_count: int = 8:
    set(v):
        sunshafts_perf_sample_count = v
        _update_effect()
@export_range(0.0, 2.0, 0.001) var sunshafts_perf_dither_strength: float = 1.4:
    set(v):
        sunshafts_perf_dither_strength = v
        _update_effect()

@export_group("Storm")
@export_range(0.0, 2.0, 0.01) var storm_flash_sky_energy: float = 0.18:
    set(v):
        storm_flash_sky_energy = maxf(v, 0.0)
        _update_sun_transform()
@export_range(0.0, 2.0, 0.01) var storm_flash_night_sky_energy: float = 0.08:
    set(v):
        storm_flash_night_sky_energy = maxf(v, 0.0)
        _update_sun_transform()
@export_range(0.0, 10.0, 0.01) var storm_flash_light_energy_clear: float = 0.9:
    set(v):
        storm_flash_light_energy_clear = maxf(v, 0.0)
        _update_sun_transform()
@export_range(0.0, 10.0, 0.01) var storm_flash_light_energy_overcast: float = 5.6:
    set(v):
        storm_flash_light_energy_overcast = maxf(v, 0.0)
        _update_sun_transform()
@export var storm_flash_light_color: Color = Color(0.83, 0.89, 1.0, 1.0):
    set(v):
        storm_flash_light_color = v
        _update_sun_transform()
@export var storm_flash_ambient_color: Color = Color(0.76, 0.82, 0.96, 1.0):
    set(v):
        storm_flash_ambient_color = v
        _update_sun_transform()
@export_range(0.0, 2.0, 0.01) var storm_flash_ambient_energy_base: float = 0.28:
    set(v):
        storm_flash_ambient_energy_base = maxf(v, 0.0)
        _update_sun_transform()
@export_range(0.0, 2.0, 0.01) var storm_flash_ambient_energy_overcast_boost: float = 0.35:
    set(v):
        storm_flash_ambient_energy_overcast_boost = maxf(v, 0.0)
        _update_sun_transform()
@export_range(0.0, 1.0, 0.001) var storm_flash_ambient_blend: float = 0.4:
    set(v):
        storm_flash_ambient_blend = clampf(v, 0.0, 1.0)
        _update_sun_transform()
@export var storm_flash_fog_color: Color = Color(0.74, 0.82, 0.96, 1.0):
    set(v):
        storm_flash_fog_color = v
        _update_sun_transform()
@export var storm_flash_volumetric_color: Color = Color(0.58, 0.66, 0.82, 1.0):
    set(v):
        storm_flash_volumetric_color = v
        _update_sun_transform()
@export_range(0.0, 1.0, 0.001) var storm_flash_volumetric_blend: float = 0.35:
    set(v):
        storm_flash_volumetric_blend = clampf(v, 0.0, 1.0)
        _update_sun_transform()

@export_group("Fog")
@export_range(0.0, 1.0, 0.001) var fog_density: float = 0.0:
    set(v):
        var next := clampf(v, 0.0, 1.0)
        if absf(fog_density - next) <= 0.0001:
            return
        fog_density = next
        _update_sun_transform()
        _update_effect()
@export_range(0.0, 1.0, 0.001) var fog_sky_affect_intensity: float = 1.0:
    set(v):
        fog_sky_affect_intensity = v
        _update_sun_transform()
@export_range(0.0, 1.0, 0.001) var vol_fog_sky_affect_intensity: float = 1.0:
    set(v):
        vol_fog_sky_affect_intensity = v
        _update_sun_transform()
@export_range(0.0, 1.0, 0.001) var storm_fog_emission_scale: float = 1.0:
    set(v):
        storm_fog_emission_scale = v
        _update_sun_transform()
        _update_effect()
@export_range(0.0, 1.0, 0.001) var lightning_flash: float = 0.0:
    set(v):
        var next := clampf(v, 0.0, 1.0)
        if absf(lightning_flash - next) <= 0.0001:
            return
        lightning_flash = next
        _update_sun_transform()
        _update_effect()

@export_group("Debug")
@export var force_refresh: bool = false:
    set(v):
        if v:
            _refresh()
            force_refresh = false
@export_range(0.0, 1.0) var moon_phase_debug: float

@export_group("Sky Shader: Atmosphere")
@export var shader_atmosphere_horizon_level: float = -0.035:
    set(v):
        shader_atmosphere_horizon_level = clampf(v, -0.2, 0.2)
        _set_shader_param("atmosphere_horizon_level", shader_atmosphere_horizon_level)
@export var shader_atmosphere_height: float = 0.24:
    set(v):
        shader_atmosphere_height = clampf(v, 0.02, 0.6)
        _set_shader_param("atmosphere_height", shader_atmosphere_height)
@export var shader_atmosphere_density: float = 0.46:
    set(v):
        shader_atmosphere_density = clampf(v, 0.0, 2.0)
        _set_shader_param("atmosphere_density", shader_atmosphere_density)
@export var shader_atmosphere_sun_scatter: float = 0.34:
    set(v):
        shader_atmosphere_sun_scatter = clampf(v, 0.0, 2.0)
        _set_shader_param("atmosphere_sun_scatter", shader_atmosphere_sun_scatter)
@export var shader_atmosphere_sunset_boost: float = 1.35:
    set(v):
        shader_atmosphere_sunset_boost = clampf(v, 0.0, 3.0)
        _set_shader_param("atmosphere_sunset_boost", shader_atmosphere_sunset_boost)

@export_group("Sky Shader: GI (SDFGI Fill)")
@export var gi_day_tint: Color = Color(0.8, 0.75, 0.7, 1.0):
    set(v):
        gi_day_tint = v
        _update_sun_transform()
@export var gi_day_energy: float = 0.6:
    set(v):
        gi_day_energy = v
        _update_sun_transform()
@export var gi_night_tint: Color = Color(0.2, 0.4, 0.8, 1.0):
    set(v):
        gi_night_tint = v
        _update_sun_transform()
@export var gi_night_energy: float = 2.0:
    set(v):
        gi_night_energy = v
        _update_sun_transform()



func _ready() -> void:
    _rendered_day = day_of_year
    _rendered_time = time_of_day
    _is_ready = true

    _refresh()
    set_process(true)


func _exit_tree():
    _remove_sunshafts_compositor_effect()

func _process(_delta: float) -> void:
    _advance_time_transition(_delta)
    _process_sunshafts()


func apply_now() -> void:
    _init_sky()
    _request_time_update(true)
    _update_effect()


func apply_wind_now() -> void:
    _update_cloud_wind()

func _refresh() -> void:
    if not is_inside_tree():
        return

    _camera = _find_active_camera()
    _environment = _get_environment()
    _light = _get_directional_light()

    _remove_sunshafts_compositor_effect()
    _install_sunshafts_compositor_effect()
    _init_sky()
    _update_sun_transform()
    _update_cloud_time()
    _update_cloud_wind()
    _update_effect()

    _success("(Re)Initialized")


func _get_final_cloud_density() -> float:
    var base_cloud_density := clouds_coverage
    var current_cloud_overcast_intensity := 0.0
    var cloud_overcast_mix := clampf(current_cloud_overcast_intensity, 0.0, 1.0)
    if base_cloud_density <= 0.0001:
        return 0.0
    return lerpf(base_cloud_density, maxf(base_cloud_density, 0.88), cloud_overcast_mix)


func _apply_cloud_light_response(light: DirectionalLight3D) -> void:
    if not light:
        return
    var final_cloud_density := _get_final_cloud_density()
    var soften_start := minf(clouds_shadow_soften_start, clouds_shadow_soften_end)
    var soften_end := maxf(clouds_shadow_soften_start, clouds_shadow_soften_end)
    var shadow_soften := smoothstep(soften_start, soften_end, final_cloud_density)
    light.light_angular_distance = lerpf(
        clouds_shadow_angular_distance_clear,
        clouds_shadow_angular_distance_overcast,
        shadow_soften
    )
    light.shadow_opacity = lerpf(
        clouds_shadow_opacity_clear,
        clouds_shadow_opacity_overcast,
        shadow_soften
    )



func _get_directional_light() -> DirectionalLight3D:
    if not is_inside_tree(): return null
    if not directional_light_path.is_empty():
        return get_node_or_null(directional_light_path) as DirectionalLight3D
    else:
        return null

func _get_world_environment() -> WorldEnvironment:
    if not world_environment_path.is_empty():
        return get_node_or_null(world_environment_path)
    return null

func _get_environment() -> Environment:
    var world_environment := _get_world_environment()
    if world_environment:
        return world_environment.environment
    return null


func _get_editor_access():
    if _editor_access != null:
        return _editor_access
    if not Engine.is_editor_hint():
        return null
    _editor_access = load(EDITOR_ACCESS_SCRIPT_PATH)
    return _editor_access

func _get_compositor() -> Compositor:
    var we := _get_world_environment()
    if we and "compositor" in we:
        if we.compositor: return we.compositor

    if Engine.is_editor_hint():
        var editor_camera = _get_editor_access().get_editor_camera_3d(0) if _get_editor_access() != null else null
        if editor_camera and "compositor" in editor_camera:
            return editor_camera.compositor
        return null

    var vp := get_viewport()
    if vp:
        var cam := vp.get_camera_3d()
        if cam and "compositor" in cam:
            return cam.compositor

    var camera := _find_active_camera()
    return camera.compositor if camera else null

func _set_compositor(compositor: Compositor):
    var we := _get_world_environment()
    if we and "compositor" in we:
        we.compositor = compositor
        return

    if Engine.is_editor_hint():
        var editor_camera = _get_editor_access().get_editor_camera_3d(0) if _get_editor_access() != null else null
        if editor_camera and "compositor" in editor_camera:
            editor_camera.compositor = compositor
        return

    var vp := get_viewport()
    if vp:
        var cam := vp.get_camera_3d()
        if cam and "compositor" in cam:
            cam.compositor = compositor
            return

    var camera := _find_active_camera()
    if camera and "compositor" in camera:
        camera.compositor = compositor
func _init_sky() -> void:
    if not _environment:
        return

    _environment.sky = Sky.new()
    _environment.background_mode = Environment.BG_SKY

    if not _sky_material:
        _sky_material = ShaderMaterial.new()
        _sky_material.shader = FILMIC_SKY_SHADER

    if not _cloud_texture_a:
        _cloud_texture_a = NoiseTexture2D.new()
        _cloud_texture_a.seamless = true
        var noise := FastNoiseLite.new()
        _cloud_texture_a.noise = noise

    if not _cloud_texture_b:
        _cloud_texture_b = NoiseTexture2D.new()
        _cloud_texture_b.seamless = true
        var noise := FastNoiseLite.new()
        _cloud_texture_b.noise = noise

    _cloud_texture_a.noise.seed = clouds_generator_seed_a
    _cloud_texture_a.noise.frequency = clouds_generator_frequency_a * 0.01
    _cloud_texture_b.noise.seed = clouds_generator_seed_b
    _cloud_texture_b.noise.frequency = clouds_generator_frequency_b * 0.01

    _environment.sky.sky_material = _sky_material

    if not _compositor_effect:
        _install_sunshafts_compositor_effect()

    _sync_sky_shader_params()
    _reset_cloud_time_tracking()


func _set_shader_param(param_name: String, value: Variant) -> void:
    if _sky_material:
        _sky_material.set_shader_parameter(param_name, value)

func _sync_sky_shader_params() -> void:
    if not _sky_material:
        return

    _sky_material.set_shader_parameter("lower_sky_color", shader_lower_sky_color)
    _sky_material.set_shader_parameter("horizon_color", shader_horizon_color)
    _sky_material.set_shader_parameter("zenith_color", shader_zenith_color)
    _sky_material.set_shader_parameter("sky_energy", shader_sky_energy)
    _sky_material.set_shader_parameter("horizon_height", shader_horizon_height)
    _sky_material.set_shader_parameter("horizon_softness", shader_horizon_softness)
    _sky_material.set_shader_parameter("zenith_curve", shader_zenith_curve)
    _sky_material.set_shader_parameter("horizon_glow_strength", shader_horizon_glow_strength)
    _sky_material.set_shader_parameter("atmosphere_horizon_level", shader_atmosphere_horizon_level)
    _sky_material.set_shader_parameter("atmosphere_height", shader_atmosphere_height)
    _sky_material.set_shader_parameter("atmosphere_density", shader_atmosphere_density)
    _sky_material.set_shader_parameter("atmosphere_sun_scatter", shader_atmosphere_sun_scatter)
    _sky_material.set_shader_parameter("atmosphere_sunset_boost", shader_atmosphere_sunset_boost)
    _sky_material.set_shader_parameter("rainbow_intensity", rainbow_intensity)
    _sky_material.set_shader_parameter("rainbow_secondary_intensity", rainbow_secondary_intensity)

    _sky_material.set_shader_parameter("sunset_bottom_color", shader_sunset_bottom_color)
    _sky_material.set_shader_parameter("sunset_horizon_color", shader_sunset_horizon_color)
    _sky_material.set_shader_parameter("sunset_zenith_color", shader_sunset_zenith_color)
    _sky_material.set_shader_parameter("sunset_cloud_color", shader_sunset_cloud_color)
    _sky_material.set_shader_parameter("sunset_sun_color", sun_sunset_color)

    _sky_material.set_shader_parameter("night_lower_sky_color", shader_night_lower_sky_color)
    _sky_material.set_shader_parameter("night_horizon_color", shader_night_horizon_color)
    _sky_material.set_shader_parameter("night_zenith_color", shader_night_zenith_color)
    _sky_material.set_shader_parameter("night_sky_energy", shader_night_sky_energy)
    _sky_material.set_shader_parameter("stars_color", shader_stars_color)
    _sky_material.set_shader_parameter("stars_energy", shader_stars_energy)
    _sky_material.set_shader_parameter("stars_size_min", shader_stars_size_min)
    _sky_material.set_shader_parameter("stars_size_max", shader_stars_size_max)
    _sky_material.set_shader_parameter("stars_edge_softness", shader_stars_edge_softness)

    _sky_material.set_shader_parameter("sun_color", sun_day_color)
    _sky_material.set_shader_parameter("sun_disk_size", sun_disk_size)
    _sky_material.set_shader_parameter("sun_seasonal_size_variation", sun_seasonal_size_variation)
    _sky_material.set_shader_parameter("sun_disk_softness", sun_disk_softness)
    _sky_material.set_shader_parameter("sun_disk_strength", sun_disk_strength)
    _sky_material.set_shader_parameter("sun_halo_size", sun_halo_size)
    _sky_material.set_shader_parameter("sun_halo_strength", sun_halo_strength)
    _sky_material.set_shader_parameter("sun_atmosphere_size", sun_atmosphere_size)
    _sky_material.set_shader_parameter("sun_atmosphere_strength", sun_atmosphere_strength)
    _sky_material.set_shader_parameter("sun_energy_scale", sun_energy_scale)

    _sky_material.set_shader_parameter("moon_color", moon_color)
    _sky_material.set_shader_parameter("moon_size", moon_size)
    _sky_material.set_shader_parameter("moon_glow_strength", moon_glow_strength)
    _sky_material.set_shader_parameter("moon_eclipse_size", moon_eclipse_size)
    _sky_material.set_shader_parameter("moon_glow_size", moon_glow_size)
    _sky_material.set_shader_parameter("moon_texture", moon_texture)

    _sky_material.set_shader_parameter("cloud_tex_a", _cloud_texture_a)
    _sky_material.set_shader_parameter("cloud_tex_b", _cloud_texture_b)
    _sky_material.set_shader_parameter("cloud_scroll_a", clouds_scroll_a)
    _sky_material.set_shader_parameter("cloud_scroll_b", clouds_scroll_b)
    _sky_material.set_shader_parameter("cloud_scale_a", clouds_scale_a)
    _sky_material.set_shader_parameter("cloud_scale_b", clouds_scale_b)
    _sky_material.set_shader_parameter("cloud_plane_height", clouds_plane_height)
    _sky_material.set_shader_parameter("cloud_plane_curve", clouds_plane_curve)
    _sky_material.set_shader_parameter("cloud_warp_strength", clouds_warp_strength)
    _sky_material.set_shader_parameter("cloud_coverage", clouds_coverage)
    _sky_material.set_shader_parameter("cloud_softness", clouds_softness)
    _sky_material.set_shader_parameter("cloud_opacity", clouds_opacity)
    _sky_material.set_shader_parameter("cloud_horizon_fade", clouds_horizon_fade)
    _sky_material.set_shader_parameter("cloud_top_fade", clouds_top_fade)
    _sky_material.set_shader_parameter("cloud_light_color", clouds_color_light)
    _sky_material.set_shader_parameter("cloud_shadow_color", clouds_color_shadow)
    _sky_material.set_shader_parameter("cloud_forward_scatter", clouds_forward_scatter)
    _sky_material.set_shader_parameter("cloud_backscatter", clouds_backscatter)
    _sky_material.set_shader_parameter("sun_cloud_occlusion", clouds_sun_occlusion)

    _sky_material.set_shader_parameter("cloud_time", _get_cloud_time_value())
    _sky_material.set_shader_parameter("cloud_motion_time", _cloud_motion_time)
    _sky_material.set_shader_parameter("cloud_evolution_time", _cloud_evolution_time)
    _sky_material.set_shader_parameter("cloud_motion_scale", clouds_motion_scale)
    _sky_material.set_shader_parameter("cloud_evolution_strength", clouds_evolution_strength)
    _sky_material.set_shader_parameter("cloud_evolution_scale", clouds_evolution_scale)
    _apply_cloud_wind_params()

func _get_cloud_time_value() -> float:
    return ((float(_rendered_day - 1) * 24.0) + _rendered_time) * clouds_time_scale


func _get_rendered_total_hours() -> float:
    return float(_rendered_day) * 24.0 + _rendered_time


func _reset_cloud_time_tracking() -> void:
    _last_cloud_total_hours = _get_rendered_total_hours()
    _set_shader_param("cloud_motion_time", _cloud_motion_time)
    _set_shader_param("cloud_evolution_time", _cloud_evolution_time)


func _update_cloud_time(current_total_hours: float = INF) -> void:
    if is_inf(current_total_hours):
        current_total_hours = _get_rendered_total_hours()
    var delta_hours := current_total_hours - _last_cloud_total_hours
    _last_cloud_total_hours = current_total_hours
    var delta_world_seconds := delta_hours * 3600.0

    if absf(delta_world_seconds) > 0.0001:
        _cloud_motion_time += delta_world_seconds * _get_cloud_wind_speed() * clouds_motion_scale
        _cloud_evolution_time += delta_world_seconds * clouds_evolution_speed

    _set_shader_param("cloud_time", _get_cloud_time_value())
    _set_shader_param("cloud_motion_time", _cloud_motion_time)
    _set_shader_param("cloud_evolution_time", _cloud_evolution_time)


func _get_cloud_wind_speed() -> float:
    return maxf(clouds_wind_strength, 0.0) * clouds_wind_speed_multiplier


func _get_cloud_wind_direction() -> Vector2:
    if clouds_wind_direction.length_squared() <= 0.000001:
        return Vector2(1.0, 0.0)
    return clouds_wind_direction.normalized()


func _apply_cloud_wind_params() -> void:
    _sky_material.set_shader_parameter("cloud_wind_direction", _get_cloud_wind_direction())
    _sky_material.set_shader_parameter("cloud_wind_speed", _get_cloud_wind_speed())


func _update_cloud_wind() -> void:
    if _sky_material:
        _apply_cloud_wind_params()


func _request_time_update(snap: bool = false) -> void:
    if not is_inside_tree():
        return
    var target_hours := float(day_of_year) * 24.0 + time_of_day
    var current_hours := float(_rendered_day) * 24.0 + _rendered_time
    var same_day_wrap := day_of_year == _rendered_day and absf(time_of_day - _rendered_time) > 12.0

    if Engine.is_editor_hint() or time_transition_duration <= 0.0 or snap:
        _stop_time_transition()
        _apply_total_hours(target_hours)
        return

    if same_day_wrap:
        var wrapped_target_time := _rendered_time + _get_wrapped_time_delta(_rendered_time, time_of_day)
        var wrapped_delta := wrapped_target_time - _rendered_time
        if absf(wrapped_delta) <= 0.0001:
            _stop_time_transition()
            _apply_wrapped_time_of_day(wrapped_target_time)
            return
        _time_transition_wrapped = true
        _time_transition_target_unwrapped_time = wrapped_target_time
        _time_transition_speed_hours_per_second = wrapped_delta / time_transition_duration
        _time_transition_active = true
        return

    var total_delta := target_hours - current_hours
    if absf(total_delta) <= 0.0001:
        _stop_time_transition()
        _apply_total_hours(target_hours)
        return
    _time_transition_wrapped = false
    _time_transition_target_total_hours = target_hours
    _time_transition_speed_hours_per_second = total_delta / time_transition_duration
    _time_transition_active = true


func _get_wrapped_time_delta(from_time: float, to_time: float) -> float:
    return wrapf((to_time - from_time) + 12.0, 0.0, 24.0) - 12.0


func _advance_time_transition(delta: float) -> void:
    if not _time_transition_active or delta <= 0.0:
        return

    var step := absf(_time_transition_speed_hours_per_second) * delta
    if _time_transition_wrapped:
        var next_unwrapped_time := move_toward(_rendered_time, _time_transition_target_unwrapped_time, step)
        _apply_wrapped_time_of_day(next_unwrapped_time)
        if absf(next_unwrapped_time - _time_transition_target_unwrapped_time) <= 0.0001:
            _stop_time_transition()
        return

    var current_hours := float(_rendered_day) * 24.0 + _rendered_time
    var next_total_hours := move_toward(current_hours, _time_transition_target_total_hours, step)
    _apply_total_hours(next_total_hours)
    if absf(next_total_hours - _time_transition_target_total_hours) <= 0.0001:
        _stop_time_transition()


func _stop_time_transition() -> void:
    _time_transition_active = false
    _time_transition_wrapped = false
    _time_transition_speed_hours_per_second = 0.0


func _apply_wrapped_time_of_day(unwrapped_time: float) -> void:
    _rendered_day = day_of_year
    _rendered_time = wrapf(unwrapped_time, 0.0, 24.0)
    _update_sun_transform()
    _update_cloud_time(float(day_of_year) * 24.0 + unwrapped_time)
    time_changed.emit(_rendered_day, _rendered_time)

func _apply_total_hours(total_hours: float) -> void:
    var day_new = int(floor(total_hours / 24.0))
    var new_time = fmod(total_hours, 24.0)
    if day_new != _rendered_day:
        day_changed.emit(day_new)
    _rendered_day = day_new
    _rendered_time = new_time

    _update_sun_transform()
    _update_cloud_time(total_hours)
    time_changed.emit(_rendered_day, _rendered_time)

func _update_sun_transform() -> void:
    if not is_inside_tree():
        return

    var light = _get_directional_light()
    var day_current = float(_rendered_day) + _rendered_time / 24.0
    var moon_phase = fmod( day_current / 29.53, 1.0)
    moon_phase_debug = moon_phase

    var theta_sun = deg_to_rad(360.0 / 365.0 * ( day_current + 10.0))
    var declination_sun = deg_to_rad(-23.45) * cos(theta_sun)

    var theta_moon = theta_sun - moon_phase * TAU
    var declination_moon = deg_to_rad(-23.45) * cos(theta_moon) + deg_to_rad(5.14) * sin(theta_moon)

    var hour_angle = deg_to_rad(15.0 * (_rendered_time - 12.0))
    var lat_rad = deg_to_rad(latitude)

    var get_dir = func(ha: float, dec: float) -> Vector3:
        var y = sin(lat_rad) * sin(dec) + cos(lat_rad) * cos(dec) * cos(ha)
        var x = -cos(dec) * sin(ha)
        var z = sin(lat_rad) * cos(dec) * cos(ha) - cos(lat_rad) * sin(dec)
        return Vector3(x, y, z).normalized()


    var sun_dir = get_dir.call(hour_angle, declination_sun)
    var moon_hour_angle = hour_angle - moon_phase * TAU
    var moon_dir = get_dir.call(moon_hour_angle, declination_moon)

    var sidereal_time = deg_to_rad( day_current * 360.0 + _rendered_time * 15.0)
    var celestial_basis = Basis()
    celestial_basis = celestial_basis.rotated(Vector3.RIGHT, lat_rad - PI / 2.0)
    celestial_basis = celestial_basis.rotated(Vector3.UP, -sidereal_time)

    _set_shader_param("custom_sun_dir", sun_dir)
    _set_shader_param("custom_moon_dir", moon_dir)
    _set_shader_param("celestial_matrix", celestial_basis)
    _set_shader_param("rendered_day_of_year", float(_rendered_day))
    _set_shader_param("rendered_time_of_day", _rendered_time)
    _set_shader_param("observer_latitude_deg", latitude)

    var dir_to_basis = func(dir: Vector3) -> Basis:
        var up = Vector3.UP
        if abs(dir.y) > 0.999:
            up = Vector3.RIGHT
        var right = up.cross(dir).normalized()
        var new_up = dir.cross(right).normalized()
        return Basis(right, new_up, dir)

    var s_alt = sun_dir.y
    var m_alt = moon_dir.y

    _day_blend = smoothstep(-0.2, 0.3, s_alt)
    _sunset_blend = smoothstep(-0.2, 0.05, s_alt) * (1.0 - smoothstep(0.1, 0.4, s_alt))

    var sun_energy = day_light_energy * smoothstep(-0.05, 0.08, s_alt)
    var moon_energy = night_light_energy * smoothstep(0.0, 0.05, m_alt) * (1.0 - smoothstep(-0.1, 0.0, s_alt))

    if sun_energy >= moon_energy:
        if light:
            light.global_transform.basis = dir_to_basis.call(sun_dir)
            light.light_color = day_light_color.lerp(sunset_light_color, _sunset_blend)
            light.light_energy = sun_energy
        _is_daytime = true
    else:
        if light:
            light.global_transform.basis = dir_to_basis.call(moon_dir)
            light.light_color = night_light_color
            light.light_energy = moon_energy
        _is_daytime = false

    _set_shader_param("gi_tint", gi_night_tint.lerp(gi_day_tint, _day_blend))
    _set_shader_param("gi_energy_multiplier", lerp(gi_night_energy, gi_day_energy, _day_blend) + _sunset_blend * 0.5)

    if _environment:
        var env = _environment
        env.ambient_light_color =  night_ambient_color.lerp( day_ambient_color, _day_blend)
        env.ambient_light_energy = lerp( night_ambient_energy,  day_ambient_energy, pow(_day_blend, 0.5)) + _sunset_blend * 0.8

        var fog_day_mix =  night_fog_color.lerp( day_fog_color, _day_blend)
        env.fog_light_color = fog_day_mix.lerp(sunset_light_color, _sunset_blend * 0.5)
        env.fog_density = lerp( night_fog_density,  day_fog_density, _day_blend)
        env.fog_sky_affect = lerp( night_fog_sky_affect,  day_fog_sky_affect, _day_blend)
        env.fog_depth_begin = lerp( night_fog_distance_begin,  day_fog_distance_begin, _day_blend)
        env.fog_depth_end = lerp(night_fog_distance,  day_fog_distance, _day_blend)

        var vol_day_mix =  night_vol_fog_albedo.lerp( day_vol_fog_albedo, _day_blend)
        env.volumetric_fog_albedo = vol_day_mix.lerp(sunset_light_color, _sunset_blend * 0.3)

        var current_vol_fog_density = lerp( night_vol_fog_density,  day_vol_fog_density, _day_blend)
        env.volumetric_fog_density = current_vol_fog_density

        env.volumetric_fog_sky_affect = lerp( night_vol_fog_sky_affect,  day_vol_fog_sky_affect, _day_blend)
        env.volumetric_fog_length = lerp( night_vol_fog_length,  day_vol_fog_length, _day_blend)
        env.volumetric_fog_ambient_inject = lerp( night_vol_fog_ambient_inject,  day_vol_fog_ambient_inject, _day_blend)

        _apply_state_params(env, light)
    else:
        _apply_state_params(null, light)
    _apply_cloud_light_response(light)


func _apply_state_params(env: Environment, light: DirectionalLight3D) -> void:
    var current_lightning_flash := clampf(lightning_flash, 0.0, 1.0)
    var current_storm_fog_emission_scale := clampf(storm_fog_emission_scale, 0.0, 1.0)

    var current_cloud_overcast_intensity := 0.0
    var base_fog_density := lerpf(night_fog_density, day_fog_density, _day_blend)
    var base_vol_fog_density := lerpf(night_vol_fog_density, day_vol_fog_density, _day_blend)

    var fog_density_boost := clampf(fog_density, 0.0, 1.0)
    var vol_fog_density_boost := clampf(fog_density * 0.05, 0.0, 1.0)
    var current_fog_density := clampf(base_fog_density + fog_density_boost, 0.0, 1.5)
    var current_vol_fog_density := clampf(base_vol_fog_density + vol_fog_density_boost, 0.0, 1.0)

    var cloud_mix := clampf(current_cloud_overcast_intensity * 0.8, 0.0, 1.0)
    var final_cloud_density := _get_final_cloud_density()
    var sky_overcast := clampf(maxf(final_cloud_density, cloud_mix), 0.0, 1.0)
    var overcast_cooling := clampf(sky_overcast * 0.78, 0.0, 1.0)

    _set_shader_param("cloud_coverage", final_cloud_density)
    _set_shader_param("cloud_opacity", lerpf(clouds_opacity, maxf(clouds_opacity, 0.95), clampf(sky_overcast * 0.85, 0.0, 1.0)))
    _set_shader_param("cloud_shadow_color", clouds_color_shadow)
    _set_shader_param("cloud_light_color", clouds_color_light.lerp(Color(0.66, 0.7, 0.78, 1.0), clampf(sky_overcast * 0.35, 0.0, 1.0)))
    _set_shader_param("sun_cloud_occlusion", clampf(clouds_sun_occlusion + sky_overcast * 0.42, 0.0, 0.98))
    _set_shader_param("sky_energy", maxf(0.02, shader_sky_energy * (1.0 - sky_overcast * 0.46) + current_lightning_flash * storm_flash_sky_energy))
    _set_shader_param("night_sky_energy", maxf(0.02, shader_night_sky_energy * (1.0 - sky_overcast * 0.34) + current_lightning_flash * storm_flash_night_sky_energy))
    _set_shader_param("stars_energy", maxf(0.0, shader_stars_energy * (1.0 - cloud_mix * 0.98)))
    _set_shader_param("moon_color", moon_color.lerp(Color(0.045, 0.05, 0.06, 1.0), cloud_mix * 0.96))
    _set_shader_param("moon_size", lerpf(moon_size, moon_size * 0.72, cloud_mix * 0.85))
    _set_shader_param("moon_glow_strength", maxf(0.0, moon_glow_strength * (1.0 - cloud_mix * 0.96)))

    if light:
        light.light_energy += current_lightning_flash * lerpf(storm_flash_light_energy_clear, storm_flash_light_energy_overcast, sky_overcast)
        light.light_color = light.light_color.lerp(Color(0.58, 0.62, 0.68, 1.0), overcast_cooling * 0.94)
        light.light_color = light.light_color.lerp(storm_flash_light_color, current_lightning_flash * 0.8)

    if env == null:
        return

    env.ambient_light_color = env.ambient_light_color.lerp(Color(0.38, 0.41, 0.46, 1.0), overcast_cooling * 0.82)
    env.ambient_light_energy *= maxf(0.18, 1.0 - (sky_overcast * 0.24))

    env.fog_density = current_fog_density
    env.fog_sky_affect = lerpf(env.fog_sky_affect, 1.0, fog_sky_affect_intensity * fog_density_boost)

    env.volumetric_fog_density = current_vol_fog_density

    env.volumetric_fog_sky_affect = lerpf(env.volumetric_fog_sky_affect, 1.0, vol_fog_sky_affect_intensity * fog_density_boost)
    env.volumetric_fog_length = maxf(2.0, env.volumetric_fog_length * (1.0 - fog_density_boost * 0.8))

    var base_emission := Color(0, 0, 0)
    var volumetric_emission := base_emission * current_storm_fog_emission_scale
    if current_lightning_flash > 0.0:
        volumetric_emission = volumetric_emission.lerp(storm_flash_volumetric_color * (current_lightning_flash * 0.55), current_lightning_flash * storm_flash_volumetric_blend)
    env.volumetric_fog_emission = volumetric_emission

    if current_lightning_flash > 0.0:
        env.ambient_light_color = env.ambient_light_color.lerp(storm_flash_ambient_color, current_lightning_flash * storm_flash_ambient_blend)
        env.ambient_light_energy += current_lightning_flash * (storm_flash_ambient_energy_base + sky_overcast * storm_flash_ambient_energy_overcast_boost)
        env.fog_light_color = env.fog_light_color.lerp(storm_flash_fog_color, current_lightning_flash * 0.7)
        env.volumetric_fog_albedo = env.volumetric_fog_albedo.lerp(storm_flash_volumetric_color, current_lightning_flash * storm_flash_volumetric_blend)


func _get_all_compositors() -> Array[Compositor]:
    var compositors: Array[Compositor] = []

    var we := _get_world_environment()
    if we and "compositor" in we and we.compositor:
        compositors.append(we.compositor)

    if Engine.is_editor_hint():
        var editor_camera = _get_editor_access().get_editor_camera_3d(0) if _get_editor_access() != null else null
        if editor_camera and "compositor" in editor_camera and editor_camera.compositor:
            if not compositors.has(editor_camera.compositor):
                compositors.append(editor_camera.compositor)

    var vp := get_viewport()
    if vp:
        var cam := vp.get_camera_3d()
        if cam and "compositor" in cam and cam.compositor:
            if not compositors.has(cam.compositor):
                compositors.append(cam.compositor)

    var camera := _find_active_camera()
    if camera and "compositor" in camera and camera.compositor:
        if not compositors.has(camera.compositor):
            compositors.append(camera.compositor)

    return compositors

func _install_sunshafts_compositor_effect() -> void:
    _remove_sunshafts_compositor_effect()

    var compositor := _get_compositor()
    if not compositor:
        var has_target := false
        if _get_world_environment():
            has_target = true
        elif Engine.is_editor_hint():
            var editor_camera = _get_editor_access().get_editor_camera_3d(0) if _get_editor_access() != null else null
            if editor_camera:
                has_target = true
        else:
            var vp := get_viewport()
            if vp and vp.get_camera_3d(): has_target = true
            elif _find_active_camera(): has_target = true

        if has_target:
            compositor = Compositor.new()
            _set_compositor(compositor)
        else:
            return

    if not compositor.resource_path.is_empty():
        compositor = compositor.duplicate(true) as Compositor
        _set_compositor(compositor)

    _compositor_effect = SUN_SHAFTS_EFFECT_SCRIPT.new()
    _compositor_effect.set("sun_visible", true)
    var effects = compositor.compositor_effects
    effects.insert(0, _compositor_effect)
    compositor.compositor_effects = effects
    _success("Installed sunshafts compositor effect")


func _remove_sunshafts_compositor_effect() -> void:
    for comp in _get_all_compositors():
        var effects = comp.compositor_effects
        var changed = false
        var i := effects.size() - 1
        while i >= 0:
            if effects[i] != null and effects[i].get_script() == SUN_SHAFTS_EFFECT_SCRIPT:
                effects.remove_at(i)
                changed = true
            i -= 1
        if changed:
            comp.compositor_effects = effects

    _compositor_effect = null

func _update_effect() -> void:
    if not _compositor_effect:
        return
    _viewport_size = _get_active_viewport_size()
    _camera = _find_active_camera()
    _light = _get_directional_light()

    var current_base_color = sunshafts_moon_color.lerp(sunshafts_shaft_color, _day_blend)

    var cloud_occlusion := clampf(_get_final_cloud_density() * 0.85, 0.0, 0.96)
    var shafts_visibility := 1.0 - cloud_occlusion

    _compositor_effect.set("shaft_color", current_base_color.lerp(Color(0.72, 0.74, 0.78, 1.0), cloud_occlusion * 0.5))
    _compositor_effect.set("density", sunshafts_density * shafts_visibility * lerpf(0.7, 1.0, _day_blend))
    _compositor_effect.set("bright_threshold", sunshafts_bright_threshold)
    _compositor_effect.set("weight", sunshafts_weight * shafts_visibility * lerpf(1.5, 1.0, _day_blend))
    _compositor_effect.set("decay", sunshafts_decay)
    _compositor_effect.set("exposure", sunshafts_exposure * shafts_visibility * lerpf(1.3, 1.0, _day_blend))
    _compositor_effect.set("max_radius", sunshafts_max_radius)
    _compositor_effect.set("sample_count", sunshafts_perf_sample_count)
    _compositor_effect.set("dither_strength", sunshafts_perf_dither_strength)

func _process_sunshafts() -> void:
    if _compositor_effect and _camera and _light:
        var sun_dir = _light.global_transform.basis.z.normalized()
        var sun_world_pos = _camera.global_position + (sun_dir * sunshafts_distance)
        var screen_pos = _camera.unproject_position(sun_world_pos)
        _compositor_effect.set("sun_screen_uv", Vector2(screen_pos.x / _viewport_size.x, screen_pos.y / _viewport_size.y))

func _find_active_camera() -> Camera3D:
    if not is_inside_tree(): return null
    if Engine.is_editor_hint():
        var editor_access = _get_editor_access()
        if editor_access != null:
            return editor_access.get_editor_camera_3d(0)
    var vp = get_viewport()
    return vp.get_camera_3d() if vp else null

func _get_active_viewport_size() -> Vector2:
    if not is_inside_tree(): return Vector2.ZERO
    if Engine.is_editor_hint():
        var editor_access = _get_editor_access()
        if editor_access != null:
            return editor_access.get_editor_viewport_size(0)
    var vp = get_viewport()
    return vp.get_visible_rect().size if vp else Vector2.ZERO


func get_day_blend() -> float:
    return _day_blend
