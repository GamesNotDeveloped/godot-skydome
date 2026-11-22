class_name SkydomeAstronomy
extends RefCounted

## Where the sun and the moon stand and how far the sky has turned (the local sidereal time) at a
## moment, from P. Schlyter's low precision formulas ("How to compute planetary positions",
## stjarnhimlen.se/comp/ppcomp.html): the sun to about an arc minute, the moon - its main
## perturbations and its parallax taken - to a few. A pure helper, it keeps no state.
##
## A moment is its day number (get_day_number()): the days from 2000 January 0.0 UT. Latitudes and
## longitudes are given in degrees (east positive), what is worked out is in radians.

## The day number of the year 0's January 0.0 in Schlyter's day count, which starts at 2000
## January 0.0 UT
const DAY_NUMBER_OFFSET := 730530
## Iterations of Kepler's equation for the moon's eccentric anomaly; it converges in two or three
const KEPLER_ITERATIONS := 5


## The day number of [param hours] from the start of [param year] (day_of_year * 24 + the time, as
## SkydomeSky counts the time it draws: day 1 at hour 0 is January 1st's midnight) of the local
## solar time at [param longitude] - the universal time is behind it by longitude / 15 hours
static func get_day_number(year: int, hours: float, longitude: float) -> float:
    # Schlyter's d = 367*y - 7*(y + (m+9)/12)/4 + 275*m/9 + D - 730530 of January 0th
    var january_zero: int = 367 * year - floori(7.0 * year / 4.0) + 30 - DAY_NUMBER_OFFSET
    return float(january_zero) + hours / 24.0 - longitude / 360.0


## The sun's right ascension (x) and declination (y)
static func get_sun_equatorial(d: float) -> Vector2:
    var sun_longitude := _get_sun_ecliptic_longitude(d)
    var obliquity := _get_obliquity(d)
    var x := _cosd(sun_longitude)
    var y := _sind(sun_longitude) * _cosd(obliquity)
    var z := _sind(sun_longitude) * _sind(obliquity)
    return Vector2(atan2(y, x), atan2(z, sqrt(x * x + y * y)))


## The local sidereal time at [param longitude]: how far the sky has turned there - the hour angle of
## what stands at its right ascension is this minus it
static func get_local_sidereal_time(d: float, longitude: float) -> float:
    var universal_hours := (d - floorf(d)) * 24.0
    # the sun's mean longitude taken at the moment itself holds the sidereal day's 0.27% more
    var sidereal_degrees := _get_sun_mean_longitude(d) + 180.0 + universal_hours * 15.0 + longitude
    return deg_to_rad(fposmod(sidereal_degrees, 360.0))


## The moon's right ascension (x) and declination (y) as seen from [param latitude] and
## [param longitude] on the Earth's surface - shifted from the Earth's centre's by its parallax, up
## to a degree
static func get_moon_equatorial(d: float, latitude: float, longitude: float) -> Vector2:
    var moon := _get_moon_ecliptic(d)
    var obliquity := _get_obliquity(d)
    var x := moon.z * _cosd(moon.x) * _cosd(moon.y)
    var y := moon.z * _sind(moon.x) * _cosd(moon.y)
    var z := moon.z * _sind(moon.y)
    var equatorial_y := y * _cosd(obliquity) - z * _sind(obliquity)
    var equatorial_z := y * _sind(obliquity) + z * _cosd(obliquity)
    var right_ascension := rad_to_deg(atan2(equatorial_y, x))
    var declination := rad_to_deg(atan2(equatorial_z, sqrt(x * x + equatorial_y * equatorial_y)))

    # the parallax, on the geocentric latitude and the distance from the Earth's centre of the
    # flattened Earth
    var parallax := rad_to_deg(asin(1.0 / moon.z))
    var geocentric_latitude := latitude - 0.1924 * _sind(2.0 * latitude)
    var centre_distance := 0.99833 + 0.00167 * _cosd(2.0 * latitude)
    var hour_angle := rad_to_deg(get_local_sidereal_time(d, longitude)) - right_ascension
    var topocentric_right_ascension := right_ascension \
            - parallax * centre_distance * _cosd(geocentric_latitude) * _sind(hour_angle) / _cosd(declination)
    var topocentric_declination: float
    if is_zero_approx(geocentric_latitude):
        topocentric_declination = declination \
                - parallax * centre_distance * _sind(-declination) * _cosd(hour_angle)
    else:
        var g := rad_to_deg(atan(tan(deg_to_rad(geocentric_latitude)) / _cosd(hour_angle)))
        topocentric_declination = declination \
                - parallax * centre_distance * _sind(geocentric_latitude) * _sind(g - declination) / _sind(g)
    return Vector2(deg_to_rad(topocentric_right_ascension), deg_to_rad(topocentric_declination))


## The moon's age as a share of its month: 0 new, 0.25 the first quarter, 0.5 full, 0.75 the last
## quarter - how far it is ahead of the sun along the ecliptic
static func get_moon_age(d: float) -> float:
    return fposmod(_get_moon_ecliptic(d).x - _get_sun_ecliptic_longitude(d), 360.0) / 360.0


static func _get_sun_mean_anomaly(d: float) -> float:
    return fposmod(356.0470 + 0.9856002585 * d, 360.0)


static func _get_sun_mean_longitude(d: float) -> float:
    return 282.9404 + 4.70935e-5 * d + _get_sun_mean_anomaly(d)


static func _get_obliquity(d: float) -> float:
    return 23.4393 - 3.563e-7 * d


static func _get_sun_ecliptic_longitude(d: float) -> float:
    var perihelion := 282.9404 + 4.70935e-5 * d
    var eccentricity := 0.016709 - 1.151e-9 * d
    var mean_anomaly := _get_sun_mean_anomaly(d)
    var eccentric_anomaly := mean_anomaly + rad_to_deg(
            eccentricity * _sind(mean_anomaly) * (1.0 + eccentricity * _cosd(mean_anomaly)))
    var x := _cosd(eccentric_anomaly) - eccentricity
    var y := _sind(eccentric_anomaly) * sqrt(1.0 - eccentricity * eccentricity)
    return fposmod(rad_to_deg(atan2(y, x)) + perihelion, 360.0)


## The moon's geocentric ecliptic longitude (x) and latitude (y) in degrees and its distance (z) in
## the Earth's radii
static func _get_moon_ecliptic(d: float) -> Vector3:
    var node := 125.1228 - 0.0529538083 * d
    var inclination := 5.1454
    var perigee := 318.0634 + 0.1643573223 * d
    var semi_major_axis := 60.2666
    var eccentricity := 0.054900
    var mean_anomaly := fposmod(115.3654 + 13.0649929509 * d, 360.0)

    var eccentric_anomaly := mean_anomaly + rad_to_deg(
            eccentricity * _sind(mean_anomaly) * (1.0 + eccentricity * _cosd(mean_anomaly)))
    for i in KEPLER_ITERATIONS:
        eccentric_anomaly -= (eccentric_anomaly - rad_to_deg(eccentricity * _sind(eccentric_anomaly)) - mean_anomaly) \
                / (1.0 - eccentricity * _cosd(eccentric_anomaly))
    var orbit_x := semi_major_axis * (_cosd(eccentric_anomaly) - eccentricity)
    var orbit_y := semi_major_axis * sqrt(1.0 - eccentricity * eccentricity) * _sind(eccentric_anomaly)
    var true_anomaly := rad_to_deg(atan2(orbit_y, orbit_x))
    var distance := sqrt(orbit_x * orbit_x + orbit_y * orbit_y)

    var argument := true_anomaly + perigee
    var x := distance * (_cosd(node) * _cosd(argument) - _sind(node) * _sind(argument) * _cosd(inclination))
    var y := distance * (_sind(node) * _cosd(argument) + _cosd(node) * _sind(argument) * _cosd(inclination))
    var z := distance * _sind(argument) * _sind(inclination)
    var longitude := rad_to_deg(atan2(y, x))
    var latitude := rad_to_deg(atan2(z, sqrt(x * x + y * y)))

    # the perturbations by the sun: of the sun's and the moon's mean anomalies (ms, mm), the moon's
    # mean elongation (e) and its argument of latitude (f)
    var ms := _get_sun_mean_anomaly(d)
    var mm := mean_anomaly
    var e := mean_anomaly + perigee + node - _get_sun_mean_longitude(d)
    var f := mean_anomaly + perigee
    longitude += -1.274 * _sind(mm - 2.0 * e) \
            + 0.658 * _sind(2.0 * e) \
            - 0.186 * _sind(ms) \
            - 0.059 * _sind(2.0 * mm - 2.0 * e) \
            - 0.057 * _sind(mm - 2.0 * e + ms) \
            + 0.053 * _sind(mm + 2.0 * e) \
            + 0.046 * _sind(2.0 * e - ms) \
            + 0.041 * _sind(mm - ms) \
            - 0.035 * _sind(e) \
            - 0.031 * _sind(mm + ms) \
            - 0.015 * _sind(2.0 * f - 2.0 * e) \
            + 0.011 * _sind(mm - 4.0 * e)
    latitude += -0.173 * _sind(f - 2.0 * e) \
            - 0.055 * _sind(mm - f - 2.0 * e) \
            - 0.046 * _sind(mm + f - 2.0 * e) \
            + 0.033 * _sind(f + 2.0 * e) \
            + 0.017 * _sind(2.0 * mm + f)
    distance += -0.58 * _cosd(mm - 2.0 * e) - 0.46 * _cosd(2.0 * e)
    return Vector3(fposmod(longitude, 360.0), latitude, distance)


static func _sind(degrees: float) -> float:
    return sin(deg_to_rad(degrees))


static func _cosd(degrees: float) -> float:
    return cos(deg_to_rad(degrees))
