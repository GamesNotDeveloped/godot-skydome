#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform restrict readonly image2D color_image;
layout(rgba16f, set = 0, binding = 1) uniform restrict writeonly image2D source_copy;

void main() {
    ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(pixel, imageSize(color_image)))) {
        return;
    }
    imageStore(source_copy, pixel, imageLoad(color_image, pixel));
}
