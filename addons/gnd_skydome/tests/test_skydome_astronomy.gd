extends GutTest

## Where a sky puts the sun and the moon and how far it turns its stars (SkydomeAstronomy), against
## PyEphem 4.2.1 (refraction off - the sky draws none) for the same date, time and place

## The low precision formulas keep within a few arc minutes; their worst here is 0.05 degrees
const POSITION_TOLERANCE_DEGREES: float = 0.2
## The moon's age at its new moon, its first quarter and its full moon to this share of its month
## (a third of a degree of its elongation)
const MOON_AGE_TOLERANCE: float = 0.001
## The sun crossing the meridian at its time to this hour angle (a minute of time)
const TRANSIT_TOLERANCE_DEGREES: float = 0.25
## A sidereal day's length in solar days: the stars turn once round in it
const SIDEREAL_DAY_DAYS: float = 0.99726957
## The stars standing again as they stood to this angle [rad]
const SAME_TURN_TOLERANCE: float = 1.0e-4

## The date, the local solar time and the place of a moment, the sun's and the moon's altitude and
## azimuth (from the north through the east) there [deg]
const MOMENTS: Dictionary = {
    "Warsaw, a summer evening": {
        "year": 2026, "day": 172, "time": 16.784, "latitude": 52.23, "longitude": 21.01,
        "sun": Vector2(29.641, 270.730), "moon": Vector2(34.740, 161.683),
    },
    "Warsaw, a November night": {
        "year": 2026, "day": 326, "time": 20.400667, "latitude": 52.23, "longitude": 21.01,
        "sun": Vector2(-39.706, 289.698), "moon": Vector2(50.220, 142.903),
    },
    "Sydney, a January evening": {
        "year": 2026, "day": 10, "time": 20.080667, "latitude": -33.87, "longitude": 151.21,
        "sun": Vector2(-9.752, 235.137), "moon": Vector2(-35.208, 135.025),
    },
    "New York, a September morning": {
        "year": 2027, "day": 248, "time": 9.066, "latitude": 40.71, "longitude": -74.01,
        "sun": Vector2(38.384, 118.926), "moon": Vector2(-24.162, 99.486),
    },
    "Greenwich, a leap year's last noon": {
        "year": 2028, "day": 366, "time": 12.0, "latitude": 51.48, "longitude": 0.0,
        "sun": Vector2(15.481, 179.228), "moon": Vector2(-15.656, 1.790),
    },
}

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
    SkydomeServer.skydome_bind(rid, world_environment, light)


func after_each() -> void:
    SkydomeServer.skydome_free(rid)


func test_the_sun_and_the_moon_stand_where_they_are_on_the_date_and_place() -> void:
    for moment_name: String in MOMENTS:
        var moment: Dictionary = MOMENTS[moment_name]
        for param: StringName in [&"year", &"latitude", &"longitude"]:
            SkydomeServer.skydome_set_param(rid, param, moment[param])
        SkydomeServer.skydome_set_param(rid, &"day_of_year", moment["day"])
        SkydomeServer.skydome_set_param(rid, &"time_of_day", moment["time"])
        var sky: SkydomeSky = SkydomeServer.skydome_get_sky(rid)

        assert_lt(rad_to_deg(sky.get_sun_direction().angle_to(_get_direction(moment["sun"]))),
                POSITION_TOLERANCE_DEGREES, "the sun - %s" % moment_name)
        assert_lt(rad_to_deg(sky.get_moon_direction().angle_to(_get_direction(moment["moon"]))),
                POSITION_TOLERANCE_DEGREES, "the moon - %s" % moment_name)


## 2026's new moon of 15 June 02:54 UT, its first quarter of 21 June 21:55 UT and its full moon of
## 29 June 23:57 UT
func test_the_moon_is_as_old_as_it_is_on_the_date() -> void:
    var new_moon := SkydomeAstronomy.get_day_number(2026, 166 * 24.0 + 2.901111, 0.0)
    var first_quarter := SkydomeAstronomy.get_day_number(2026, 172 * 24.0 + 21.921944, 0.0)
    var full_moon := SkydomeAstronomy.get_day_number(2026, 180 * 24.0 + 23.943056, 0.0)

    var new_moon_age := SkydomeAstronomy.get_moon_age(new_moon)
    assert_lt(minf(new_moon_age, 1.0 - new_moon_age), MOON_AGE_TOLERANCE, "the new moon")
    assert_almost_eq(SkydomeAstronomy.get_moon_age(first_quarter), 0.25, MOON_AGE_TOLERANCE)
    assert_almost_eq(SkydomeAstronomy.get_moon_age(full_moon), 0.5, MOON_AGE_TOLERANCE)


## The sun crosses Warsaw's meridian a quarter of an hour after the solar noon in February and a
## quarter before it in November (the equation of time), not at noon itself
func test_the_sun_crosses_the_meridian_when_it_does_on_the_date() -> void:
    var warsaw_longitude := 21.01
    for transit: Vector2 in [Vector2(45, 12.235111), Vector2(307, 11.725667)]:
        var d := SkydomeAstronomy.get_day_number(2026, transit.x * 24.0 + transit.y, warsaw_longitude)
        var hour_angle := SkydomeAstronomy.get_local_sidereal_time(d, warsaw_longitude) \
                - SkydomeAstronomy.get_sun_equatorial(d).x
        assert_lt(absf(rad_to_deg(wrapf(hour_angle, -PI, PI))), TRANSIT_TOLERANCE_DEGREES,
                "the sun's transit on the day %d" % int(transit.x))


## The stars turn once round in a sidereal day, and so stand a degree further on a solar day later
func test_the_stars_turn_once_in_a_sidereal_day() -> void:
    var d := SkydomeAstronomy.get_day_number(2026, 172 * 24.0 + 22.0, 21.01)
    var turn := SkydomeAstronomy.get_local_sidereal_time(d, 21.01)

    var after_sidereal_day := SkydomeAstronomy.get_local_sidereal_time(d + SIDEREAL_DAY_DAYS, 21.01)
    var after_solar_day := SkydomeAstronomy.get_local_sidereal_time(d + 1.0, 21.01)

    assert_lt(absf(wrapf(after_sidereal_day - turn, -PI, PI)), SAME_TURN_TOLERANCE)
    assert_almost_eq(rad_to_deg(wrapf(after_solar_day - turn, -PI, PI)), 0.9856, 0.001)


## The direction a sky puts what stands at [param altitude_azimuth] (degrees, the azimuth from the
## north through the east): the north is -Z, the east +X
func _get_direction(altitude_azimuth: Vector2) -> Vector3:
    var altitude := deg_to_rad(altitude_azimuth.x)
    var azimuth := deg_to_rad(altitude_azimuth.y)
    return Vector3(cos(altitude) * sin(azimuth), sin(altitude), -cos(altitude) * cos(azimuth))
