extends GutTest

## How the light a sky is bound to turns with the time (SkydomeSky.light_update_mode): the sky follows
## every change of the time, the light every change, by steps or when asked

const DAY_OF_YEAR: int = 180
const NOON: float = 12.0
## Directions the same to this angle are taken as one
const SAME_DIRECTION_ANGLE: float = 1.0e-6

var world_environment: WorldEnvironment
var light: DirectionalLight3D
var rid: RID


func before_each() -> void:
    world_environment = WorldEnvironment.new()
    world_environment.environment = Environment.new()
    world_environment.environment.sky = Sky.new()
    add_child_autofree(world_environment)
    light = DirectionalLight3D.new()
    add_child_autofree(light)
    rid = SkydomeServer.skydome_create()
    # the time taken at once, not eased into
    SkydomeServer.skydome_set_param(rid, &"time_transition_duration", 0.0)
    SkydomeServer.skydome_set_param(rid, &"day_of_year", DAY_OF_YEAR)
    SkydomeServer.skydome_set_param(rid, &"time_of_day", NOON)
    SkydomeServer.skydome_bind(rid, world_environment, light)


func after_each() -> void:
    SkydomeServer.skydome_free(rid)


func _set_time(hours: float, seconds: float = 0.0) -> void:
    SkydomeServer.skydome_set_param(rid, &"time_of_day", hours + seconds / 3600.0)


func _set_mode(mode: SkydomeSky.LightUpdateMode) -> void:
    SkydomeServer.skydome_set_param(rid, &"light_update_mode", mode)


func _light_direction() -> Vector3:
    return light.global_basis.z


func _drawn_sun() -> Vector3:
    return SkydomeServer.skydome_get_sky(rid).get_sun_direction()


func _assert_same(a: Vector3, b: Vector3, text: String) -> void:
    assert_lt(a.angle_to(b), SAME_DIRECTION_ANGLE, text)


func _assert_apart(a: Vector3, b: Vector3, text: String) -> void:
    assert_gt(a.angle_to(b), SAME_DIRECTION_ANGLE, text)


func test_continuous_light_follows_every_time_change() -> void:
    _set_time(NOON, 30.0)
    _assert_same(_light_direction(), _drawn_sun(), "the light stands where the sun is drawn")
    var before: Vector3 = _light_direction()
    _set_time(NOON, 50.0)
    _assert_apart(_light_direction(), before, "the light turned with the time")
    _assert_same(_light_direction(), _drawn_sun(), "the light stands where the sun is drawn")


func test_stepped_light_stands_within_a_step() -> void:
    _set_mode(SkydomeSky.LightUpdateMode.STEPPED)
    _set_time(NOON, 30.0)
    var before: Vector3 = _light_direction()
    _set_time(NOON, 50.0)
    _assert_same(_light_direction(), before, "the light stands still within a minute")
    _assert_apart(_drawn_sun(), before, "the sky's sun moved on")


func test_stepped_light_takes_the_step_start() -> void:
    _set_time(NOON, 60.0)
    var step_start: Vector3 = _drawn_sun()
    _set_mode(SkydomeSky.LightUpdateMode.STEPPED)
    _set_time(NOON, 90.0)
    _assert_same(_light_direction(), step_start, "the light stands where the sun was as the minute began")
    _set_time(NOON, 130.0)
    _assert_apart(_light_direction(), step_start, "the light turned as the next minute began")


func test_stepped_light_takes_the_step_set() -> void:
    _set_mode(SkydomeSky.LightUpdateMode.STEPPED)
    SkydomeServer.skydome_set_param(rid, &"light_update_step_seconds", 300.0)
    _set_time(NOON, 70.0)
    var before: Vector3 = _light_direction()
    _set_time(NOON, 250.0)
    _assert_same(_light_direction(), before, "the light stands still within five minutes")


func test_manual_light_waits_for_update_light() -> void:
    var before: Vector3 = _light_direction()
    _set_mode(SkydomeSky.LightUpdateMode.MANUAL)
    _set_time(NOON + 2.0)
    _assert_same(_light_direction(), before, "the light stands still until asked")
    SkydomeServer.skydome_update_light(rid)
    _assert_same(_light_direction(), _drawn_sun(), "the light turned to the time drawn")


func test_apply_now_turns_a_manual_light() -> void:
    _set_mode(SkydomeSky.LightUpdateMode.MANUAL)
    _set_time(NOON + 2.0)
    SkydomeServer.skydome_get_sky(rid).apply_now()
    _assert_same(_light_direction(), _drawn_sun(), "a sky applied at once turns its light at once")


func test_continuous_mode_takes_the_drawn_time() -> void:
    _set_mode(SkydomeSky.LightUpdateMode.MANUAL)
    _set_time(NOON + 2.0)
    _set_mode(SkydomeSky.LightUpdateMode.CONTINUOUS)
    _assert_same(_light_direction(), _drawn_sun(), "the light turned to the time drawn")
