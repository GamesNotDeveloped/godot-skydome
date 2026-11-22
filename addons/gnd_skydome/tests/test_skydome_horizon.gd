extends GutTest

## The project setting whether a sky draws the sun, the moon and the stars below the horizon
## (SkydomeSettings.SHOW_BELOW_HORIZON) reaching the sky's shader

var world_environment: WorldEnvironment
var light: DirectionalLight3D
var rid: RID
var _setting_was_set: bool
var _setting_before: Variant


func before_each() -> void:
    _setting_was_set = ProjectSettings.has_setting(SkydomeSettings.SHOW_BELOW_HORIZON)
    _setting_before = ProjectSettings.get_setting(SkydomeSettings.SHOW_BELOW_HORIZON)
    world_environment = WorldEnvironment.new()
    world_environment.environment = Environment.new()
    world_environment.environment.sky = Sky.new()
    add_child_autofree(world_environment)
    light = DirectionalLight3D.new()
    add_child_autofree(light)
    rid = SkydomeServer.skydome_create()


func after_each() -> void:
    SkydomeServer.skydome_free(rid)
    ProjectSettings.set_setting(SkydomeSettings.SHOW_BELOW_HORIZON,
            _setting_before if _setting_was_set else null)


func test_the_sky_shows_its_bodies_below_the_horizon_by_default() -> void:
    ProjectSettings.set_setting(SkydomeSettings.SHOW_BELOW_HORIZON, null)
    SkydomeServer.skydome_bind(rid, world_environment, light)

    assert_true(_get_shader_show_below_horizon())


func test_the_setting_off_hides_them() -> void:
    ProjectSettings.set_setting(SkydomeSettings.SHOW_BELOW_HORIZON, false)
    SkydomeServer.skydome_bind(rid, world_environment, light)

    assert_false(_get_shader_show_below_horizon())


func _get_shader_show_below_horizon() -> bool:
    var material := world_environment.environment.sky.sky_material as ShaderMaterial
    return material.get_shader_parameter("show_below_horizon")
