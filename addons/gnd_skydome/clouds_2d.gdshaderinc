// The clouds of the sky (Skydome's own, without a SkydomeClouds): two noise textures on a plane over
// the observer, scrolled by the wind, warped and evolving. clouds() - their colour premultiplied by
// how much they cover (alpha), with the moon's corona in a thin one

uniform sampler2D cloud_tex_a : source_color, filter_linear, repeat_enable;
uniform sampler2D cloud_tex_b : source_color, filter_linear, repeat_enable;

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
group_uniforms;

uniform vec2 cloud_wind_direction = vec2(0.8, 0.3);
uniform float cloud_wind_speed = 1.0;
uniform float cloud_motion_time = 0.0;
uniform float cloud_motion_scale = 0.12;
uniform float cloud_evolution_time = 0.0;
uniform float cloud_evolution_strength : hint_range(0.0, 1.0) = 0.18;
uniform float cloud_evolution_scale : hint_range(0.001, 0.25) = 0.018;

vec2 dir_to_cloud_plane_uv(vec3 dir, float plane_height, float curve) {
	float denom = max(dir.y + plane_height, 0.05);
	vec2 uv = dir.xz / denom;
	float dist = length(uv);
	uv *= 1.0 + dist * curve;
	return uv;
}

vec4 clouds(vec3 dir, vec2 pixel, float day_blend, float sunset_blend) {
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
		// An overcast covers the zenith too: the fade leaves the stars a gap only in a broken sky,
		// a full cover with a hole over the head let the moon's disc through it
		top_mask = mix(top_mask, 1.0, smoothstep(0.6, 1.0, cloud_coverage));
		cloud_mask *= horizon_mask * top_mask * cloud_opacity;
	}

	float moon_dot = dot(dir, custom_moon_dir);
	float moon_illumination = smoothstep(-0.5, 0.5, dot(custom_sun_dir, -custom_moon_dir));
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
	// A thin cloud in front of the moon glows around it instead of showing its disc; a thick
	// cover (cloud_density_tint) takes the corona away as well
	float corona = pow(saturate(moon_dot), 1.0 / (0.02 * moon_glow_size)) * moon_illumination * (1.0 - day_blend);
	cloud_col += moon_color * corona * moon_corona_strength * (1.0 - cloud_density_tint);

	return vec4(cloud_col * cloud_mask, cloud_mask);
}
