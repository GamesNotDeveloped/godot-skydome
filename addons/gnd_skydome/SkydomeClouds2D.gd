@tool
class_name SkydomeClouds2D
extends SkydomeClouds

## Skydome's own clouds: two noise layers drawn on a curved plane over the sky
## (clouds_2d.gdshaderinc), shaped, moved and coloured by Skydome's clouds_* parameters. The clouds a
## Skydome draws when no clouds_renderer is set - through the same SkydomeClouds a renderer of
## another kind is.

const SKY_SHADER := preload("res://addons/gnd_skydome/filmic_procedural_sky.gdshader")
# The noise's frequency per unit of clouds_generator_frequency_*
const NOISE_FREQUENCY_SCALE := 0.01

var _texture_a: NoiseTexture2D
var _texture_b: NoiseTexture2D


func get_sky_shader() -> Shader:
    return SKY_SHADER


## The noise of the two layers, by clouds_generator_seed_* and clouds_generator_frequency_*
func setup(skydome: SkydomeSky, material: ShaderMaterial) -> void:
    if not _texture_a:
        _texture_a = _create_noise_texture()
    if not _texture_b:
        _texture_b = _create_noise_texture()
    _texture_a.noise.seed = skydome.clouds_generator_seed_a
    _texture_a.noise.frequency = skydome.clouds_generator_frequency_a * NOISE_FREQUENCY_SCALE
    _texture_b.noise.seed = skydome.clouds_generator_seed_b
    _texture_b.noise.frequency = skydome.clouds_generator_frequency_b * NOISE_FREQUENCY_SCALE
    material.set_shader_parameter("cloud_tex_a", _texture_a)
    material.set_shader_parameter("cloud_tex_b", _texture_b)


## Their shape, their cover and their motion, of Skydome's parameters and its clouds' time
func sync(skydome: SkydomeSky, material: ShaderMaterial) -> void:
    material.set_shader_parameter("cloud_coverage", skydome.get_cloud_cover())
    material.set_shader_parameter("cloud_softness", skydome.clouds_softness)
    material.set_shader_parameter("cloud_scroll_a", skydome.clouds_scroll_a)
    material.set_shader_parameter("cloud_scroll_b", skydome.clouds_scroll_b)
    material.set_shader_parameter("cloud_scale_a", skydome.clouds_scale_a)
    material.set_shader_parameter("cloud_scale_b", skydome.clouds_scale_b)
    material.set_shader_parameter("cloud_plane_height", skydome.clouds_plane_height)
    material.set_shader_parameter("cloud_plane_curve", skydome.clouds_plane_curve)
    material.set_shader_parameter("cloud_warp_strength", skydome.clouds_warp_strength)
    material.set_shader_parameter("cloud_horizon_fade", skydome.clouds_horizon_fade)
    material.set_shader_parameter("cloud_top_fade", skydome.clouds_top_fade)
    material.set_shader_parameter("cloud_forward_scatter", skydome.clouds_forward_scatter)
    material.set_shader_parameter("cloud_backscatter", skydome.clouds_backscatter)
    material.set_shader_parameter("cloud_wind_direction", skydome.get_cloud_wind_direction())
    material.set_shader_parameter("cloud_wind_speed", skydome.get_cloud_wind_speed())
    material.set_shader_parameter("cloud_motion_scale", skydome.clouds_motion_scale)
    material.set_shader_parameter("cloud_motion_time", skydome.get_cloud_motion_time())
    material.set_shader_parameter("cloud_evolution_strength", skydome.clouds_evolution_strength)
    material.set_shader_parameter("cloud_evolution_scale", skydome.clouds_evolution_scale)
    material.set_shader_parameter("cloud_evolution_time", skydome.get_cloud_evolution_time())


## Skydome's clouds_coverage
func get_cover(skydome: SkydomeSky) -> float:
    return skydome.clouds_coverage


func _create_noise_texture() -> NoiseTexture2D:
    var texture := NoiseTexture2D.new()
    texture.seamless = true
    texture.noise = FastNoiseLite.new()
    return texture
