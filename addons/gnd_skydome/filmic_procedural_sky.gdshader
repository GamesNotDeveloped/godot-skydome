shader_type sky;

uniform sampler2D cloud_tex_a : source_color, filter_linear, repeat_enable;
uniform sampler2D cloud_tex_b : source_color, filter_linear, repeat_enable;
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

group_uniforms Rainbow;
	uniform float rainbow_intensity : hint_range(0.0, 2.0) = 0.0;
	uniform float rainbow_secondary_intensity : hint_range(0.0, 2.0) = 0.35;

group_uniforms Sunset;
	uniform vec3 sunset_bottom_color : source_color = vec3(1.0, 0.5, 0.2);
	uniform vec3 sunset_horizon_color : source_color = vec3(0.8, 0.2, 0.05);
	uniform vec3 sunset_zenith_color : source_color = vec3(0.4, 0.3, 0.5);
	uniform vec3 sunset_cloud_color : source_color = vec3(1.0, 0.4, 0.15);
	uniform vec3 sunset_sun_color : source_color = vec3(1.0, 0.4, 0.1);

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

group_uniforms GI;
	uniform vec3 gi_tint : source_color = vec3(1.0, 1.0, 1.0);
	uniform float gi_energy_multiplier : hint_range(0.0, 10.0) = 1.0;

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

uniform bool high_quality_sky = true;

group_uniforms Clouds;
	uniform vec2 cloud_scroll_a = vec2(0.0012, 0.00015);
	uniform vec2 cloud_scroll_b = vec2(-0.0018, 0.0004);
	uniform vec2 cloud_scale_a = vec2(0.045, 0.055);
	uniform vec2 cloud_scale_b = vec2(0.082, 0.125);
	uniform float cloud_plane_height : hint_range(0.02, 4.0) = 0.25;
	uniform float cloud_plane_curve : hint_range(0.0, 1.0) = 0.15;
	uniform float cloud_warp_strength : hint_range(0.0, 1.0) = 0.14;
	uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.5;
	uniform float cloud_softness : hint_range(0.01, 1.0) = 0.2;
	uniform float cloud_opacity : hint_range(0.0, 1.0) = 0.6;
	uniform float cloud_horizon_fade : hint_range(0.0, 1.0) = 0.3;
	uniform float cloud_top_fade : hint_range(0.0, 1.0) = 0.2;
	uniform vec3 cloud_light_color : source_color = vec3(1.0, 0.98, 0.95);
	uniform vec3 cloud_shadow_color : source_color = vec3(0.4, 0.45, 0.55);
	uniform float cloud_forward_scatter : hint_range(0.0, 4.0) = 1.5;
	uniform float cloud_backscatter : hint_range(0.0, 1.0) = 0.2;
	uniform float sun_cloud_occlusion : hint_range(0.0, 1.0) = 0.8;

uniform vec3 custom_sun_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 custom_moon_dir = vec3(0.0, -1.0, 0.0);
uniform mat3 celestial_matrix = mat3(1.0);
uniform float rendered_day_of_year = 180.0;
uniform float rendered_time_of_day = 12.0;
uniform float observer_latitude_deg = 21.0;
uniform float cloud_time = 0.0;
uniform vec2 cloud_wind_direction = vec2(0.8, 0.3);
uniform float cloud_wind_speed = 1.0;
uniform float cloud_motion_time = 0.0;
uniform float cloud_motion_scale = 0.12;
uniform float cloud_evolution_time = 0.0;
uniform float cloud_evolution_strength : hint_range(0.0, 1.0) = 0.18;
uniform float cloud_evolution_scale : hint_range(0.001, 0.25) = 0.018;

const float ASTRONOMICAL_UNIT_KM = 149597870.7;
const float SOLAR_RADIUS_KM = 695700.0;
const float EARTH_EQUATORIAL_RADIUS_KM = 6378.137;
const float EARTH_POLAR_RADIUS_KM = 6356.752314245;
const float EARTH_ORBITAL_ECCENTRICITY = 0.0167086;
const float EARTH_SIDEREAL_YEAR_DAYS = 365.256363004;
const float EARTH_PERIHELION_DAY = 3.0;

vec2 dir_to_cloud_plane_uv(vec3 dir, float plane_height, float curve) {
	float denom = max(dir.y + plane_height, 0.05);
	vec2 uv = dir.xz / denom;
	float dist = length(uv);
	uv *= 1.0 + dist * curve;
	return uv;
}

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

void sky() {
	vec3 dir = normalize(EYEDIR);

	float sun_alt = custom_sun_dir.y;

	// ALIGNED WITH GDSCRIPT FOR BETTER DAWN/DUSK
	float day_blend = smoothstep(-0.2, 0.3, sun_alt);
	float sunset_blend = smoothstep(-0.2, 0.05, sun_alt) * (1.0 - smoothstep(0.1, 0.4, sun_alt));

	float horizon_t = smoothstep(horizon_height - horizon_softness, horizon_height + horizon_softness, dir.y);
	float zenith_t = pow(saturate(max(dir.y, 0.0)), zenith_curve);

	// Day
	vec3 day_base = mix(lower_sky_color, horizon_color, horizon_t);
	day_base = mix(day_base, zenith_color, zenith_t);
	float day_glow = pow(1.0 - saturate(abs(dir.y - horizon_height) * 2.5), 4.0);
	day_base += horizon_color * day_glow * horizon_glow_strength;

	// Sunset
	vec3 sunset_base = mix(sunset_bottom_color, sunset_horizon_color, horizon_t);
	sunset_base = mix(sunset_base, sunset_zenith_color, zenith_t);
	float sunset_glow = pow(1.0 - saturate(abs(dir.y - horizon_height) * 2.5), 4.0);
	sunset_base += sunset_horizon_color * sunset_glow * horizon_glow_strength * 1.5;

	// Mix Day and Sunset
	day_base = mix(day_base, sunset_base, sunset_blend);
	day_base *= sky_energy;

	// Night
	vec3 night_base = mix(night_lower_sky_color, night_horizon_color, horizon_t);
	night_base = mix(night_base, night_zenith_color, zenith_t);
	float night_glow = pow(1.0 - saturate(abs(dir.y - horizon_height) * 2.5), 4.0);
	night_base += night_horizon_color * night_glow * horizon_glow_strength;
	night_base *= night_sky_energy;

	vec3 final_color = mix(night_base, day_base, day_blend);
	float sun_dot = dot(dir, custom_sun_dir);

	if (!high_quality_sky) {
		float sun_disk = smoothstep(0.998, 1.0, sun_dot);
		final_color += sun_color * sun_disk * 5.0;
	} else {

	vec3 active_sun_color = mix(sun_color, sunset_sun_color, sunset_blend);

	vec3 celestial_dir = celestial_matrix * dir;
	if (day_blend < 0.99 && stars_energy > 0.001) {
		vec3 star_p = celestial_dir * 250.0;
		vec3 star_i = floor(star_p);
		vec3 star_f = fract(star_p);
		float star_h = fract(sin(dot(star_i, vec3(12.9898, 78.233, 45.164))) * 43758.5453);
		vec3 star_pos = vec3(fract(star_h * 34.34), fract(star_h * 12.34), fract(star_h * 45.34));
		float star_d = length(star_f - star_pos);
		float star_size = mix(stars_size_min, stars_size_max, fract(star_h * 11.11));
		float star_aa = max(fwidth(star_d) * stars_edge_softness, 0.003);
		float star_core = 1.0 - smoothstep(star_size - star_aa, star_size + star_aa, star_d);
		float star_intensity = star_core * smoothstep(0.95, 0.96, star_h);
		float twinkle = mix(0.3, 1.0, sin(cloud_time * 3.0 + star_h * 100.0) * 0.5 + 0.5);
		float sun_star_occlusion = smoothstep(0.92, 0.9985, sun_dot);
		float stars = star_intensity * twinkle * 8.0 * pow(1.0 - zenith_t, 2.0) * (1.0 - sun_star_occlusion);
		final_color += stars_color * stars * stars_energy * (1.0 - day_blend);
	}

	vec2 cloud_uv = dir_to_cloud_plane_uv(dir, cloud_plane_height, cloud_plane_curve);
	float cloud_mask = 0.0;
	float cloud_shape = 0.0;
	float evolution_a = 0.0;
	float evolution_b = 0.0;

	if (cloud_opacity > 0.001) {
		vec2 wind_dir = normalize(max(abs(cloud_wind_direction.x) + abs(cloud_wind_direction.y), 0.0001) * cloud_wind_direction);
		float motion_time = cloud_motion_time;
		vec2 scroll_a = wind_dir * length(cloud_scroll_a);
		vec2 scroll_b = wind_dir * length(cloud_scroll_b) * 1.35;

		if (high_quality_sky) {
			vec2 warp = texture(cloud_tex_b, cloud_uv * 0.01).rg * 2.0 - 1.0;
			cloud_uv += warp * cloud_warp_strength;

			vec2 evolution_uv = cloud_uv * cloud_evolution_scale;
			vec2 evolution_flow_a = vec2(0.011, -0.007) * cloud_evolution_time;
			vec2 evolution_flow_b = vec2(-0.009, 0.013) * cloud_evolution_time;
			evolution_a = texture(cloud_tex_a, evolution_uv + evolution_flow_a).r;
			evolution_b = texture(cloud_tex_b, evolution_uv * 1.83 + evolution_flow_b).r;
			vec2 evolution_warp = (vec2(evolution_a, evolution_b) - 0.5) * cloud_evolution_strength;
			cloud_uv += evolution_warp;
		}

		float cloud_a = texture(cloud_tex_a, cloud_uv * cloud_scale_a + scroll_a * motion_time).r;
		float cloud_b = texture(cloud_tex_b, cloud_uv * cloud_scale_b + scroll_b * motion_time).r;
		
		if (high_quality_sky) {
			float breakup = texture(cloud_tex_b, cloud_uv * 0.04).r;
			cloud_shape = mix(cloud_a, cloud_b, 0.5);
			cloud_shape = mix(cloud_shape, cloud_shape * breakup, 0.4);
		} else {
			cloud_shape = mix(cloud_a, cloud_b, 0.5);
		}

		float evolution_signed = 0.0;
		if (high_quality_sky) {
			evolution_signed = (mix(evolution_a, evolution_b, 0.45) * 2.0 - 1.0) * cloud_evolution_strength;
		}
		float evolved_coverage = clamp(cloud_coverage + evolution_signed * (cloud_softness * 1.4 + 0.08), 0.0, 1.0);
		
		if (evolved_coverage >= 0.9999) {
			cloud_mask = 1.0;
		} else if (evolved_coverage > 0.0001) {
			float cloud_threshold = 1.0 - evolved_coverage;
			cloud_mask = smoothstep(cloud_threshold - cloud_softness, cloud_threshold + cloud_softness, cloud_shape);
		}

		float horizon_mask = smoothstep(-0.1, cloud_horizon_fade, dir.y);
		float top_mask = 1.0 - smoothstep(1.0 - cloud_top_fade, 1.0, max(dir.y, 0.0));
		cloud_mask *= horizon_mask * top_mask * cloud_opacity;
	}

	float sky_visibility = 1.0 - (cloud_mask * sun_cloud_occlusion);
	float horizon_air = 1.0 - smoothstep(atmosphere_horizon_level, atmosphere_horizon_level + atmosphere_height, dir.y);
	horizon_air = pow(saturate(horizon_air), 1.35);

	float atmosphere_light_blend = smoothstep(-0.08, 0.12, sun_alt);
	float low_sun = smoothstep(-0.08, -0.005, sun_alt) * (1.0 - smoothstep(0.06, 0.30, sun_alt));
	float azimuth_alignment = 0.0;
	float dir_xz_len = length(dir.xz);
	float sun_xz_len = length(custom_sun_dir.xz);
	if (dir_xz_len > 0.0001 && sun_xz_len > 0.0001) {
		azimuth_alignment = saturate(dot(dir.xz / dir_xz_len, custom_sun_dir.xz / sun_xz_len));
	}

	vec3 haze_day_color = mix(horizon_color, sunset_horizon_color, sunset_blend * 0.9);
	vec3 haze_color = mix(night_horizon_color, haze_day_color, atmosphere_light_blend);
	float haze_mix = saturate(horizon_air * atmosphere_density * mix(0.04, 0.78, atmosphere_light_blend) * mix(1.0, atmosphere_sunset_boost, sunset_blend));
	final_color = mix(final_color, haze_color, haze_mix * sky_visibility);
	final_color += active_sun_color * pow(azimuth_alignment, 6.0) * horizon_air * low_sun * atmosphere_sun_scatter * sky_visibility;

	vec3 antisolar_dir = -custom_sun_dir;
	float scattering_angle_deg = degrees(acos(clamp(dot(dir, antisolar_dir), -1.0, 1.0)));
	float sun_altitude_deg = degrees(asin(clamp(sun_alt, -1.0, 1.0)));
	float rainbow_day_visibility = day_blend * smoothstep(0.0, 2.0, sun_altitude_deg);
	float rainbow_altitude_visibility = 1.0 - smoothstep(38.0, 42.0, sun_altitude_deg);
	float rainbow_horizon_visibility = smoothstep(-0.02, 0.08, dir.y);
	float rainbow_sky_visibility = smoothstep(0.15, 0.95, sky_visibility);
	float rainbow_visibility = rainbow_intensity * rainbow_day_visibility * rainbow_altitude_visibility * rainbow_horizon_visibility * rainbow_sky_visibility;
	if (rainbow_visibility > 0.001) {
		vec3 primary_rainbow = get_fast_rainbow_color(scattering_angle_deg, 42.0, 1.5);
		vec3 secondary_rainbow = get_fast_rainbow_color(scattering_angle_deg, 51.0, 3.0);
		float alexander_band = smoothstep(43.0, 46.5, scattering_angle_deg) * (1.0 - smoothstep(49.5, 52.5, scattering_angle_deg));
		final_color *= 1.0 - alexander_band * rainbow_visibility * 0.05;
		final_color += (primary_rainbow + secondary_rainbow * rainbow_secondary_intensity) * rainbow_visibility * 2.5;
	}

	// Sun
	vec3 sun_dir_norm = custom_sun_dir;
	vec3 sun_right = normalize(cross(vec3(0.0, 1.0, 0.0), sun_dir_norm));
	if (length(sun_right) < 0.001) sun_right = vec3(1.0, 0.0, 0.0);
	vec3 sun_up = cross(sun_dir_norm, sun_right);

	float sun_x = dot(dir, sun_right);
	float sun_y = dot(dir, sun_up);

	// Vertical flattening (Atmospheric Refraction)
	float sun_flattening = 1.0 + 0.3 * pow(1.0 - saturate(sun_alt * 4.0 + 0.1), 3.0);
	float sun_r2 = sun_x * sun_x + sun_y * sun_y * (sun_flattening * sun_flattening);
	float flattened_sun_dot = sqrt(max(0.0, 1.0 - sun_r2));
	if (sun_dot < 0.0) flattened_sun_dot = -flattened_sun_dot; // Prevent appearing on the opposite hemisphere

	// Dynamic atmospheric blur at the horizon
	float horizon_blur_factor = pow(1.0 - saturate(sun_alt * 5.0 + 0.1), 2.5);

	float disk_radius = 0.015 * sun_disk_size * get_solar_disk_scale(sun_alt);
	// Increase softness massively at the horizon (up to 8x softer)
	float disk_soft = disk_radius * sun_disk_softness * (1.0 + horizon_blur_factor * 8.0);
	float disk = smoothstep(1.0 - disk_radius - disk_soft, 1.0 - disk_radius, flattened_sun_dot);

	float sun_glow_visibility = smoothstep(-0.10, 0.04, sun_alt);
	sun_glow_visibility = pow(sun_glow_visibility, 0.6);

	// Also expand the halo slightly at the horizon to merge with the blurred disk
	float active_halo_size = sun_halo_size * (1.0 + horizon_blur_factor * 1.5);
	float halo = pow(saturate(sun_dot), 1.0 / (0.08 * active_halo_size)) * sun_halo_strength * sun_glow_visibility;
	float atmosphere = pow(saturate(sun_dot), 1.0 / (0.35 * sun_atmosphere_size)) * sun_atmosphere_strength * sun_glow_visibility;

	vec3 sun_body = active_sun_color * sun_energy_scale;

	// Sun extinction at horizon (solid drawing)
	float sun_extinction = mix(1.0, 0.2, pow(1.0 - saturate(sun_alt * 5.0 + 0.1), 2.0));
	final_color += sun_body * disk * sky_visibility * sun_disk_strength * sun_extinction;
	final_color += sun_body * halo * sky_visibility;
	final_color += sun_body * atmosphere * sky_visibility;

	// Moon
	float moon_dot = dot(dir, custom_moon_dir);
	float m_radius = 0.015 * moon_size;
	vec3 final_moon_color = vec3(0.0);
	float moon_alpha = 0.0;

	if (moon_dot > 1.0 - m_radius * 2.0) {
		vec3 up = abs(custom_moon_dir.y) < 0.999 ? vec3(0,1,0) : vec3(1,0,0);
		vec3 right = normalize(cross(up, custom_moon_dir));
		up = cross(custom_moon_dir, right);

		float x = dot(dir, right) / m_radius;
		float y = dot(dir, up) / m_radius;
		float r2 = x*x + y*y;

		if (r2 < 1.0) {
			float moon_mask_val = smoothstep(1.0, 0.9, r2);
			float z = -sqrt(1.0 - r2);
			vec3 N = normalize(x * right + y * up + z * custom_moon_dir);

			float N_dot_L = dot(N, custom_sun_dir);
			float phase_light = smoothstep(-0.1, 0.1, N_dot_L);

			float earth_shadow_radius = m_radius * moon_eclipse_size;
			float umbra_dist = length(dir + custom_sun_dir);
			float umbra = smoothstep(earth_shadow_radius * 0.8, earth_shadow_radius, umbra_dist);

			float light_intensity = phase_light * mix(0.05, 1.0, umbra);

			vec2 moon_uv = vec2(x, y) * 0.5 + 0.5;
			vec3 tex_color = texture(moon_tex, moon_uv).rgb;
			float tex_val = mix(1.0, tex_color.r, step(0.01, tex_color.r + tex_color.g + tex_color.b));

			vec3 earthshine_color = moon_color * 0.1;
			vec3 bright_color = moon_color * 5.0;

			//final_moon_color = mix(earthshine_color, bright_color, light_intensity) * tex_val * 10.0;
			final_moon_color = mix(earthshine_color, bright_color, light_intensity) * tex_val;

			// W noc oswietlony fragment 100%, nieoswietlony 25%
			// W dzien oswietlony fragment ok. 60-80% (leciutko przebija niebo), nieoswietlony 0% (niewidoczny calkiem)
			float lit_alpha = clamp(1.0 - day_blend * 0.3, 0.0, 1.0);
			float unlit_alpha = 0.25 * (1.0 - day_blend);
			moon_alpha = mix(unlit_alpha, lit_alpha, light_intensity) * moon_mask_val;
		}
	}

	float moon_illumination = smoothstep(-0.5, 0.5, dot(custom_sun_dir, -custom_moon_dir));
	float glow_intensity = pow(saturate(moon_dot), 1.0 / (0.1 * moon_glow_size)) * max(0.0, moon_glow_strength);
	vec3 glow_color = moon_color * glow_intensity * (0.1 + 0.9 * moon_illumination) * (1.0 - day_blend * 0.8);

	final_color = mix(final_color, final_moon_color, moon_alpha * sky_visibility);
	//final_color += glow_color * sky_visibility * 10.0;
	final_color += glow_color * sky_visibility;

	// Clouds
	vec3 active_light_dir = mix(custom_moon_dir, custom_sun_dir, day_blend);
	float cloud_dot = dot(dir, active_light_dir);
	float silver_lining = pow(saturate(cloud_dot), 12.0) * cloud_forward_scatter;
	float backscatter_val = pow(1.0 - saturate(cloud_dot), 2.0) * cloud_backscatter;
	float cloud_density_tint = smoothstep(0.45, 1.0, saturate(cloud_coverage));
	vec3 toned_cloud_light_color = mix(vec3(1.0), cloud_light_color, cloud_density_tint);
	vec3 toned_cloud_shadow_color = mix(cloud_shadow_color, cloud_shadow_color * vec3(0.8, 0.82, 0.88), cloud_density_tint);

	vec3 cloud_sun_light = mix(sun_color, sunset_cloud_color, sunset_blend) * sun_energy_scale;
	vec3 cloud_moon_light = moon_color * 0.1;
	vec3 active_light_color = mix(cloud_moon_light, cloud_sun_light, day_blend) * toned_cloud_light_color;
	vec3 cloud_col = mix(toned_cloud_shadow_color * mix(0.02, 1.0, day_blend), active_light_color, saturate(0.1 + silver_lining - backscatter_val));

	final_color = mix(final_color, cloud_col, cloud_mask);
	}

	if (AT_CUBEMAP_PASS) {
		vec3 gi_base = mix(night_base, day_base, day_blend);
		final_color = gi_base * gi_tint * gi_energy_multiplier;
	}

	COLOR = final_color;
}
