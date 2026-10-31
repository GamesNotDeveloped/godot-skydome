// The sky's own: its uniforms and helpers, shared by the sky (sky_atmosphere.gdshaderinc) and by the
// clouds drawn in it (clouds_2d.gdshaderinc, or a SkydomeClouds' own), which come in between:
//
//     shader_type sky;
//     #include "res://addons/gnd_skydome/sky_common.gdshaderinc"
//     #include "<the clouds: uniforms and vec4 clouds(dir, pixel, day_blend, sunset_blend)>"
//     #include "res://addons/gnd_skydome/sky_atmosphere.gdshaderinc"

uniform sampler2D moon_tex : source_color, filter_linear_mipmap, repeat_disable;

group_uniforms DaySky;
	uniform vec3 lower_sky_color : source_color = vec3(0.66, 0.71, 0.8);
	uniform vec3 horizon_color : source_color = vec3(0.82, 0.86, 0.89);
	uniform vec3 zenith_color : source_color = vec3(0.12, 0.24, 0.48);
	uniform float sky_energy : hint_range(0.0, 10.0) = 1.0;
	uniform float horizon_height : hint_range(-0.4, 0.5) = 0.05;
	uniform float horizon_softness : hint_range(0.02, 1.0) = 0.24;
	uniform float zenith_curve : hint_range(0.1, 8.0) = 1.65;
	uniform float horizon_glow_strength : hint_range(0.0, 4.0) = 0.5;

group_uniforms Atmosphere;
	uniform float atmosphere_horizon_level : hint_range(-0.2, 0.2) = -0.035;
	uniform float atmosphere_height : hint_range(0.02, 0.6) = 0.24;
	uniform float atmosphere_density : hint_range(0.0, 2.0) = 0.46;
	uniform float atmosphere_sun_scatter : hint_range(0.0, 2.0) = 0.34;
	uniform float atmosphere_sunset_boost : hint_range(0.0, 3.0) = 1.35;
	// sine of the sun elevation the sunset colours start to fade at / are gone above (Skydome.gd)
	// sine of the sun elevation the day values are reached in full at (Skydome.gd)
	uniform float day_full_altitude = 0.1045;
	uniform float sunset_fade_start = 0.0175;
	uniform float sunset_fade_end = 0.1392;
	// ...and the sun's disc reddens at / keeps the day's colour above (Skydome.gd)
	uniform float sunset_disc_fade_start = 0.0698;
	uniform float sunset_disc_fade_end = 0.1736;

group_uniforms Rainbow;
	uniform float rainbow_intensity : hint_range(0.0, 2.0) = 0.0;
	uniform float rainbow_secondary_intensity : hint_range(0.0, 2.0) = 0.35;

group_uniforms Sunset;
	uniform vec3 sunset_bottom_color : source_color = vec3(1.0, 0.5, 0.2);
	uniform vec3 sunset_horizon_color : source_color = vec3(0.8, 0.2, 0.05);
	uniform vec3 sunset_zenith_color : source_color = vec3(0.4, 0.3, 0.5);
	uniform vec3 sunset_cloud_color : source_color = vec3(1.0, 0.4, 0.15);
	uniform vec3 sunset_sun_color : source_color = vec3(1.0, 0.4, 0.1);

group_uniforms Overcast;
	// How overcast the sky is (0 - 1, Skydome's sky_overcast): a heavy cover greys the sunset out
	uniform float overcast : hint_range(0.0, 1.0) = 0.0;
	// The sky under a cover, lighter towards the horizon and darker overhead
	uniform vec3 overcast_sky_color : source_color = vec3(0.55, 0.58, 0.62);

group_uniforms NightSky;
	uniform vec3 night_lower_sky_color : source_color = vec3(0.03, 0.05, 0.09);
	uniform vec3 night_horizon_color : source_color = vec3(0.06, 0.1, 0.18);
	uniform vec3 night_zenith_color : source_color = vec3(0.01, 0.015, 0.03);
	uniform float night_sky_energy : hint_range(0.0, 10.0) = 1.0;
	uniform vec3 stars_color : source_color = vec3(1.0, 1.0, 1.0);
	uniform float stars_energy : hint_range(0.0, 50.0) = 2.0;
	uniform float stars_size_min : hint_range(0.005, 0.25) = 0.05;
	uniform float stars_size_max : hint_range(0.005, 0.4) = 0.14;
	uniform float stars_edge_softness : hint_range(0.25, 4.0) = 1.5;

group_uniforms Sun;
	uniform vec3 sun_color : source_color = vec3(1.0, 0.95, 0.8);
	uniform float sun_disk_size : hint_range(0.0, 2.0) = 1.0;
	uniform float sun_disk_softness : hint_range(0.0, 1.0) = 0.5;
	uniform float sun_disk_strength : hint_range(0.0, 20.0) = 5.0;
	uniform float sun_seasonal_size_variation : hint_range(0.0, 10.0) = 1.0;
	uniform float sun_halo_size : hint_range(0.0, 2.0) = 1.0;
	uniform float sun_halo_strength : hint_range(0.0, 10.0) = 1.5;
	uniform float sun_atmosphere_size : hint_range(0.0, 4.0) = 1.0;
	uniform float sun_atmosphere_strength : hint_range(0.0, 10.0) = 1.0;
	uniform float sun_energy_scale : hint_range(0.0, 10.0) = 1.0;

group_uniforms Moon;
	uniform vec3 moon_color : source_color = vec3(0.9, 0.95, 1.0);
	uniform float moon_size : hint_range(0.0, 2.0) = 1.0;
	uniform float moon_glow_strength : hint_range(0.0, 10.0) = 1.0;
	uniform float moon_eclipse_size : hint_range(0.0, 4.0) = 2.5;
	uniform float moon_glow_size : hint_range(0.1, 4.0) = 1.0;
	// Moonlight through a thin cloud: a soft corona on the clouds around the moon
	uniform float moon_corona_strength : hint_range(0.0, 2.0) = 0.2;

uniform bool high_quality_sky = true;

// how much of the sun's light a cloud in front of it takes away (Skydome: clouds_sun_occlusion)
uniform float sun_cloud_occlusion : hint_range(0.0, 1.0) = 0.8;

uniform vec3 custom_sun_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 custom_moon_dir = vec3(0.0, -1.0, 0.0);
uniform mat3 celestial_matrix = mat3(1.0);
uniform float rendered_day_of_year = 180.0;
uniform float rendered_time_of_day = 12.0;
uniform float observer_latitude_deg = 21.0;
uniform float cloud_time = 0.0;

const float ASTRONOMICAL_UNIT_KM = 149597870.7;
const float SOLAR_RADIUS_KM = 695700.0;
const float EARTH_EQUATORIAL_RADIUS_KM = 6378.137;
const float EARTH_POLAR_RADIUS_KM = 6356.752314245;
const float EARTH_ORBITAL_ECCENTRICITY = 0.0167086;
const float EARTH_SIDEREAL_YEAR_DAYS = 365.256363004;
const float EARTH_PERIHELION_DAY = 3.0;

float saturate(float value) { return clamp(value, 0.0, 1.0); }

float hash(vec3 p) {
	p = fract(p * vec3(123.34, 456.21, 876.45));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float get_observer_radius_km(float latitude_rad) {
	float cos_lat = cos(latitude_rad);
	float sin_lat = sin(latitude_rad);
	float equatorial_num = EARTH_EQUATORIAL_RADIUS_KM * EARTH_EQUATORIAL_RADIUS_KM * cos_lat;
	float polar_num = EARTH_POLAR_RADIUS_KM * EARTH_POLAR_RADIUS_KM * sin_lat;
	float equatorial_den = EARTH_EQUATORIAL_RADIUS_KM * cos_lat;
	float polar_den = EARTH_POLAR_RADIUS_KM * sin_lat;
	return sqrt(
		(equatorial_num * equatorial_num + polar_num * polar_num) /
		(equatorial_den * equatorial_den + polar_den * polar_den)
	);
}

float get_solar_disk_scale(float sun_alt) {
	float day_current = rendered_day_of_year + rendered_time_of_day / 24.0;
	float mean_anomaly = TAU * mod((day_current - EARTH_PERIHELION_DAY) / EARTH_SIDEREAL_YEAR_DAYS, 1.0);

	// Seasonal size variation (Physics = 0.0167 amplitude). We scale the amplitude aggressively with the parameter.
	// When variation is 1.0, it behaves like physics (~3.3% change).
	// When it is 10.0, the amplitude becomes 0.167 (meaning sun is ~33% larger in winter!)
	float dist_factor = 1.0 + (EARTH_ORBITAL_ECCENTRICITY * sun_seasonal_size_variation) * cos(mean_anomaly);

	// Cinematic "Moon Illusion" magnification.
	// Real sun doesn't grow, but perceived size increases at horizon.
	// We use a smooth curve that doesn't feel like a "squeezed ellipsoid" transition.
	float sun_alt_clamped = saturate(sun_alt);
	float atmospheric_magnification = 0.45; // Max 45% larger
	float magnification_curve = pow(1.0 - sun_alt_clamped, 2.5);
	float atmospheric_scale = 1.0 + atmospheric_magnification * magnification_curve;

	return dist_factor * atmospheric_scale;
}

// FAST RAINBOW APPROXIMATION
vec3 get_fast_rainbow_color(float angle_deg, float center_deg, float width_deg) {
	float t = (angle_deg - center_deg) / width_deg;
	if (abs(t) > 1.0) return vec3(0.0);
	
	// Spectral color approximation
	vec3 c = clamp(vec3(
		smoothstep(0.0, 0.4, t) * (1.0 - smoothstep(0.7, 1.0, t)), // Red/Orange
		smoothstep(0.3, 0.6, t) * (1.0 - smoothstep(0.8, 0.9, t)), // Green
		smoothstep(0.6, 0.9, t)                                   // Blue/Violet
	), 0.0, 1.0);
	
	// Shape of the lobe
	float envelope = exp(-4.0 * t * t);
	return c * envelope;
}
