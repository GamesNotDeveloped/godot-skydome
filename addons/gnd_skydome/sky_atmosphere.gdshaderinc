// The sky (sky()): the day's, the sunset's and the night's gradient, the stars, the haze, the
// rainbow, the sun and the moon, the clouds over them (clouds(), included before this) and the
// fog towards the horizon. With CLOUDS_HALF_RES defined (and use_half_res_pass) the clouds are drawn
// in Godot's half resolution pass and taken from it (HALF_RES_COLOR).

void sky() {
	vec3 dir = normalize(EYEDIR);

	float sun_alt = custom_sun_dir.y;

	// ALIGNED WITH GDSCRIPT FOR BETTER DAWN/DUSK
	float day_blend = smoothstep(-0.2, day_full_altitude, sun_alt);
	float sunset_blend = smoothstep(-0.2, 0.05, sun_alt) * (1.0 - smoothstep(sunset_fade_start, sunset_fade_end, sun_alt));
	// A heavy cover hides the sunset: the sky, the haze and the clouds take its colours only as much
	// as the cover breaks (as Skydome's light, ambient and fog do, Skydome.gd)
	float overcast_veil = smoothstep(0.35, 0.95, overcast);
	float sunset_seen = sunset_blend * (1.0 - overcast_veil);

	float horizon_t = smoothstep(horizon_height - horizon_softness, horizon_height + horizon_softness, dir.y);
	float zenith_t = pow(saturate(max(dir.y, 0.0)), zenith_curve);

	// Day
	vec3 day_base = mix(lower_sky_color, horizon_color, horizon_t);
	day_base = mix(day_base, zenith_color, zenith_t);
	float day_glow = pow(1.0 - saturate(abs(dir.y - horizon_height) * 2.5), 4.0);
	day_base += horizon_color * day_glow * horizon_glow_strength;

	// Which way the sun is, along the horizon (1 towards it, -1 away)
	float toward_sun = 0.0;
	if (length(dir.xz) > 0.0001 && length(custom_sun_dir.xz) > 0.0001) {
		toward_sun = dot(normalize(dir.xz), normalize(custom_sun_dir.xz));
	}
	float sun_side = saturate(toward_sun);

	// Sunset: its colours low over the horizon, reaching up the sky towards the sun and only a band
	// away from it - the dome above stays the day's, darkening in the twilight
	vec3 sunset_base = mix(sunset_bottom_color, sunset_horizon_color, horizon_t);
	float sunset_glow = pow(1.0 - saturate(abs(dir.y - horizon_height) * 2.5), 4.0);
	sunset_base += sunset_horizon_color * sunset_glow * horizon_glow_strength * 1.5;
	// how much of the sunset a direction has: all of it towards the sun, a third away from it, and as
	// high as its colours reach there (the sine of the elevation)
	float sunset_side = mix(0.3, 1.0, smoothstep(-0.5, 0.9, toward_sun));
	float sunset_reach = mix(0.07, 0.45, smoothstep(-0.3, 1.0, toward_sun));
	float sunset_share = sunset_seen * sunset_side * (1.0 - smoothstep(0.0, sunset_reach, max(dir.y, 0.0)));

	// Mix Day and Sunset
	day_base = mix(day_base, sunset_base, sunset_share);
	day_base *= mix(1.0, 0.72, sunset_blend * zenith_t);
	// opposite the sun about its setting: the earth's shadow low over the horizon and the pink belt
	// over it
	float twilight_arch = smoothstep(-0.12, -0.02, sun_alt) * (1.0 - smoothstep(0.0, 0.05, sun_alt));
	float anti_sun = smoothstep(0.0, -0.8, toward_sun) * twilight_arch * (1.0 - overcast_veil);
	float earth_shadow = 1.0 - smoothstep(0.0, 0.05, dir.y);
	float pink_belt = smoothstep(0.02, 0.06, dir.y) * (1.0 - smoothstep(0.08, 0.22, dir.y));
	day_base *= 1.0 - earth_shadow * anti_sun * 0.3;
	day_base = mix(day_base, mix(sunset_bottom_color, sunset_zenith_color, 0.5), pink_belt * anti_sun * 0.55);

	// Overcast: the cover's grey, lighter towards the horizon, and the sunset's light coming in under
	// it low on the sun's side while the cover is not whole
	vec3 overcast_base = overcast_sky_color * mix(1.15, 0.75, zenith_t);
	day_base = mix(day_base, overcast_base, overcast_veil);
	float under_cover = (1.0 - smoothstep(0.0, 0.08, dir.y)) * smoothstep(-0.03, 0.0, dir.y) * pow(sun_side, 3.0);
	day_base += sunset_horizon_color * under_cover * sunset_blend * overcast_veil * (1.0 - overcast_veil) * 2.4;
	day_base *= sky_energy;

	// Night
	vec3 night_base = mix(night_lower_sky_color, night_horizon_color, horizon_t);
	night_base = mix(night_base, night_zenith_color, zenith_t);
	float night_glow = pow(1.0 - saturate(abs(dir.y - horizon_height) * 2.5), 4.0);
	night_base += night_horizon_color * night_glow * horizon_glow_strength;
	night_base *= night_sky_energy;

	// The radiance cubemap (and the ambient light from it) only takes the gradient
	if (AT_CUBEMAP_PASS) {
		COLOR = mix(night_base, day_base, day_blend);
	}
#ifdef CLOUDS_HALF_RES
	else if (AT_HALF_RES_PASS) {
		vec4 half_res_clouds = high_quality_sky ? clouds(dir, FRAGCOORD.xy, day_blend, sunset_seen) : vec4(0.0);
		COLOR = half_res_clouds.rgb;
		ALPHA = half_res_clouds.a;
	}
#endif
	else {
	vec3 final_color = mix(night_base, day_base, day_blend);
	float sun_dot = dot(dir, custom_sun_dir);

	if (!high_quality_sky) {
		float sun_disk = smoothstep(0.998, 1.0, sun_dot);
		final_color += sun_color * sun_disk * 5.0;
	} else {

	// the sun reddens over a window of its own, higher than the sky's sunset (sunset_disc_fade_*)
	float sun_reddening = smoothstep(-0.2, 0.05, sun_alt)
			* (1.0 - smoothstep(sunset_disc_fade_start, sunset_disc_fade_end, sun_alt)) * (1.0 - overcast_veil);
	vec3 active_sun_color = mix(sun_color, sunset_sun_color, sun_reddening);

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

#ifdef CLOUDS_HALF_RES
	vec4 sky_clouds = HALF_RES_COLOR;
#else
	vec4 sky_clouds = clouds(dir, FRAGCOORD.xy, day_blend, sunset_seen);
#endif
	float cloud_mask = sky_clouds.a;

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

	// the haze as warm as the sunset is on its side of the sky
	vec3 haze_day_color = mix(horizon_color, sunset_horizon_color, sunset_seen * sunset_side * 0.9);
	vec3 haze_color = mix(night_horizon_color, haze_day_color, atmosphere_light_blend);
	float haze_mix = saturate(horizon_air * atmosphere_density * mix(0.04, 0.78, atmosphere_light_blend) * mix(1.0, atmosphere_sunset_boost, sunset_seen * sunset_side));
	final_color = mix(final_color, haze_color, haze_mix * sky_visibility);
	final_color += active_sun_color * pow(azimuth_alignment, 6.0) * horizon_air * low_sun * atmosphere_sun_scatter * sky_visibility
		* (1.0 - overcast_veil);

	vec3 antisolar_dir = -custom_sun_dir;
	float scattering_angle_deg = degrees(acos(clamp(dot(dir, antisolar_dir), -1.0, 1.0)));
	float sun_altitude_deg = degrees(asin(clamp(sun_alt, -1.0, 1.0)));
	float rainbow_day_visibility = day_blend * smoothstep(0.0, 2.0, sun_altitude_deg);
	float rainbow_altitude_visibility = 1.0 - smoothstep(38.0, 42.0, sun_altitude_deg);
	float rainbow_horizon_visibility = smoothstep(-0.02, 0.08, dir.y);
	// the rainbow lies in the rain in front of the clouds, so it is drawn over them (below); the sun
	// lighting the rain is whoever sets rainbow_intensity's to tell
	float rainbow_visibility = rainbow_intensity * rainbow_day_visibility * rainbow_altitude_visibility * rainbow_horizon_visibility;

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

	// The moon's disc is far brighter than the clouds (bright_color), so the share a cloud lets
	// through falls off with its thickness, not linearly - 10% of the disc showed through a full
	// overcast as a grey moon
	float moon_visibility = pow(1.0 - cloud_mask, 4.0);
	final_color = mix(final_color, final_moon_color, moon_alpha * moon_visibility);
	//final_color += glow_color * sky_visibility * 10.0;
	final_color += glow_color * moon_visibility;

	// Clouds (premultiplied, the moon's corona in a thin one theirs)
	final_color = final_color * (1.0 - cloud_mask) + sky_clouds.rgb;

	// The rainbow, over the clouds it is seen against
	if (rainbow_visibility > 0.001) {
		vec3 primary_rainbow = get_fast_rainbow_color(scattering_angle_deg, 42.0, 1.5);
		vec3 secondary_rainbow = get_fast_rainbow_color(scattering_angle_deg, 51.0, 3.0);
		float alexander_band = smoothstep(43.0, 46.5, scattering_angle_deg) * (1.0 - smoothstep(49.5, 52.5, scattering_angle_deg));
		final_color *= 1.0 - alexander_band * rainbow_visibility * 0.05;
		final_color += (primary_rainbow + secondary_rainbow * rainbow_secondary_intensity) * rainbow_visibility * 2.5;
	}
	}

	COLOR = final_color;
	}
}
