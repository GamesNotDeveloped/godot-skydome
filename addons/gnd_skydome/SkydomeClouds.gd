@tool
@abstract
class_name SkydomeClouds
extends Resource

## Clouds of another kind drawn in a Skydome's sky (Skydome.clouds_renderer) instead of its own: a
## sky shader with them - sky_common.gdshaderinc, the clouds' own include with its uniforms and
## vec4 clouds(vec3 dir, vec2 pixel, float day_blend, float sunset_blend) (their colour premultiplied
## by their cover), then sky_atmosphere.gdshaderinc - their uniforms, and the compositor effects
## they bring. Skydome keeps the sky, the sun, the moon, the fog and the light; it asks the clouds
## how much of the sky they cover. Emitting changed sets the sky up again.


## The sky shader with these clouds
@abstract func get_sky_shader() -> Shader


## Once the sky's material has this shader: what the clouds need of it set up (textures, ...)
func setup(_skydome: SkydomeSky, _material: ShaderMaterial) -> void:
    pass


## Their uniforms set, as the sky's are: as the sky is set up and as its state changes (the time,
## the cover, the wind, the weather)
func sync(_skydome: SkydomeSky, _material: ShaderMaterial) -> void:
    pass


## Each frame (their motion, their effects' state)
func process(_skydome: SkydomeSky, _material: ShaderMaterial, _delta: float) -> void:
    pass


## How much of the sky they cover (0 - 1), which the light, the fog and the sun shafts follow;
## below 0 - Skydome's clouds_coverage
func get_cover(_skydome: SkydomeSky) -> float:
    return -1.0


## How much darker than their cover alone they make the sky (0 - 1): a storm's clouds
func get_storm_darkening(_skydome: SkydomeSky) -> float:
    return 0.0


## Share of Skydome's clouds_light_occlusion the sun's and the moon's light loses to the cover: less
## where the clouds' own shadows on the ground take the light where they are
func get_light_occlusion_share(_skydome: SkydomeSky) -> float:
    return 1.0


## The compositor effects they bring, added after Skydome's own and taken out with them
func get_compositor_effects(_skydome: SkydomeSky) -> Array[CompositorEffect]:
    return []
