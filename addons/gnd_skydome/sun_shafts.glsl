#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0) uniform sampler2D source_color;
layout(set = 0, binding = 1) uniform sampler2D source_depth;
layout(rgba16f, set = 0, binding = 2) uniform restrict writeonly image2D color_image;

layout(push_constant, std430) uniform Params {
    vec2 raster_size;
    vec2 sun_uv;
    vec4 shaft_color;
    vec4 shaft_params_a; // x: density, y: threshold, z: weight, w: decay
    vec4 shaft_params_b; // x: visible, y: max_radius, z: exposure, w: unused
    vec4 perf_params;    // x: sample_count, y: dither_strength
    vec4 debug_params;
} params;

const int MIN_SAMPLE_COUNT = 4;
const int MAX_SAMPLE_COUNT = 100;
const float SKY_DEPTH_EPSILON = 0.00001;
const float BRIGHTNESS_TRANSITION = 0.5;

float luminance(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

float interleaved_gradient_noise(vec2 uv) {
    vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
    return fract(magic.z * fract(dot(uv, magic.xy)));
}

void main() {
    ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = imageSize(color_image);
    if (pixel.x >= size.x || pixel.y >= size.y) {
        return;
    }

    vec4 base = texelFetch(source_color, pixel, 0);

    if (params.shaft_params_b.x < 0.5 || params.shaft_params_b.y <= 0.0 ||
            any(isnan(params.sun_uv)) || any(isinf(params.sun_uv))) {
        imageStore(color_image, pixel, base);
        return;
    }

    vec2 uv = (vec2(pixel) + vec2(0.5)) / params.raster_size;
    vec2 delta = params.sun_uv - uv;
    float dist = length(delta);

    float radial_falloff = (1.0 - smoothstep(0.0, params.shaft_params_b.y, dist));
    if (radial_falloff <= 0.0) {
        imageStore(color_image, pixel, base);
        return;
    }

    if (params.debug_params.x > 0.0) {
        base.rgb = mix(base.rgb, params.debug_params.yzw, clamp(params.debug_params.x, 0.0, 1.0));
    }

    int sample_count = clamp(int(params.perf_params.x), MIN_SAMPLE_COUNT, MAX_SAMPLE_COUNT);
    float dither = interleaved_gradient_noise(vec2(pixel)) * params.perf_params.y;
    vec2 step_uv = delta * (params.shaft_params_a.x / float(sample_count));
    vec2 sample_uv = uv + step_uv * dither;

    float illumination_decay = 1.0;
    float accumulation = 0.0;
    float threshold = params.shaft_params_a.y;

    for (int i = 0; i < sample_count; i++) {
        if (sample_uv.x >= 0.0 && sample_uv.x < 1.0 && sample_uv.y >= 0.0 && sample_uv.y < 1.0) {
            // texelFetch ignores sampler clamping; round-off must not reach size.
            ivec2 sample_pixel = clamp(ivec2(sample_uv * vec2(size)), ivec2(0), size - 1);

            // The resolved reverse-Z depth is zero for the sky.
            float depth = texelFetch(source_depth, sample_pixel, 0).r;
            if (depth <= SKY_DEPTH_EPSILON) {
                vec3 sample_color = texelFetch(source_color, sample_pixel, 0).rgb;
                float lum = luminance(sample_color);
                float bright = smoothstep(threshold, threshold + BRIGHTNESS_TRANSITION, lum);
                accumulation += bright * illumination_decay * params.shaft_params_a.z;
            }
        }

        sample_uv += step_uv;
        illumination_decay *= params.shaft_params_a.w;
    }

    vec3 shafts = params.shaft_color.rgb * accumulation * params.shaft_params_b.z * radial_falloff;
    base.rgb += shafts;
    imageStore(color_image, pixel, base);
}
