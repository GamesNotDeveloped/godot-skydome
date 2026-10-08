@tool
class_name SunShaftsCompositorEffect
extends CompositorEffect

## Compute shaders are imported to SPIR-V with the addon, not compiled from source during play.
const COPY_SHADER: RDShaderFile = preload("sun_shafts_copy.glsl")
const SHAFTS_SHADER: RDShaderFile = preload("sun_shafts.glsl")
const WORKGROUP_SIZE: int = 8
const MIN_SAMPLE_COUNT: int = 4
const MAX_SAMPLE_COUNT: int = 100
const BUFFER_CONTEXT: StringName = &"gnd_sun_shafts"
const SOURCE_COPY: StringName = &"source_color"
const COPY_USAGE: int = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT

var _sun_screen_uv: Vector2 = Vector2(0.5, 0.5)
var _sun_visible: bool = false
var _shaft_color: Color = Color(1.0, 0.9, 0.72, 1.0)
var _density: float = 0.92
var _bright_threshold: float = 0.7
var _weight: float = 0.028
var _decay: float = 0.95
var _exposure: float = 1.1
var _max_radius: float = 0.9
var _sample_count: int = 20
var _dither_strength: float = 1.0
var _debug_overlay_strength: float = 0.0
var _debug_overlay_color: Color = Color(1.0, 0.0, 1.0, 1.0)

@export var sun_screen_uv: Vector2 = Vector2(0.5, 0.5):
    set(value):
        _mutex.lock()
        _sun_screen_uv = value
        _mutex.unlock()
    get:
        return _sun_screen_uv

@export var sun_visible: bool = false:
    set(value):
        _mutex.lock()
        _sun_visible = value
        _mutex.unlock()
    get:
        return _sun_visible

@export var shaft_color: Color = Color(1.0, 0.9, 0.72, 1.0):
    set(value):
        _mutex.lock()
        _shaft_color = value
        _mutex.unlock()
    get:
        return _shaft_color

@export_range(0.0, 1.0, 0.001) var density: float = 0.92:
    set(value):
        _mutex.lock()
        _density = clampf(value, 0.0, 1.0)
        _mutex.unlock()
    get:
        return _density

@export_range(0.0, 10.0, 0.001) var bright_threshold: float = 0.7:
    set(value):
        _mutex.lock()
        _bright_threshold = clampf(value, 0.0, 10.0)
        _mutex.unlock()
    get:
        return _bright_threshold

@export_range(0.0, 0.2, 0.0005) var weight: float = 0.028:
    set(value):
        _mutex.lock()
        _weight = maxf(value, 0.0)
        _mutex.unlock()
    get:
        return _weight

@export_range(0.0, 1.0, 0.001) var decay: float = 0.95:
    set(value):
        _mutex.lock()
        _decay = clampf(value, 0.0, 1.0)
        _mutex.unlock()
    get:
        return _decay

@export_range(0.0, 8.0, 0.01) var exposure: float = 1.1:
    set(value):
        _mutex.lock()
        _exposure = maxf(value, 0.0)
        _mutex.unlock()
    get:
        return _exposure

@export_range(0.0, 2.0, 0.001) var max_radius: float = 0.9:
    set(value):
        _mutex.lock()
        _max_radius = maxf(value, 0.0)
        _mutex.unlock()
    get:
        return _max_radius

@export_range(4, 100) var sample_count: int = 20:
    set(value):
        _mutex.lock()
        _sample_count = clampi(value, MIN_SAMPLE_COUNT, MAX_SAMPLE_COUNT)
        _mutex.unlock()
    get:
        return _sample_count

@export_range(0.0, 2.0, 0.001) var dither_strength: float = 1.0:
    set(value):
        _mutex.lock()
        _dither_strength = maxf(value, 0.0)
        _mutex.unlock()
    get:
        return _dither_strength

@export_group("Debug")
@export_range(0.0, 1.0, 0.001) var debug_overlay_strength: float = 0.0:
    set(value):
        _mutex.lock()
        _debug_overlay_strength = clampf(value, 0.0, 1.0)
        _mutex.unlock()
    get:
        return _debug_overlay_strength

@export var debug_overlay_color: Color = Color(1.0, 0.0, 1.0, 1.0):
    set(value):
        _mutex.lock()
        _debug_overlay_color = value
        _mutex.unlock()
    get:
        return _debug_overlay_color

var rd: RenderingDevice
var shader: RID
var pipeline: RID
var sampler: RID
var copy_shader: RID
var copy_pipeline: RID
var _mutex: Mutex = Mutex.new()


func _init() -> void:
    effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
    access_resolved_color = true
    access_resolved_depth = true
    enabled = true
    RenderingServer.call_on_render_thread(_initialize_shader)


func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE and rd:
        # Queue only the device and its RIDs: this resource is already being deleted.
        # Freeing a shader also frees its pipeline and cached uniform sets.
        if shader.is_valid():
            RenderingServer.call_on_render_thread(rd.free_rid.bind(shader))
        if copy_shader.is_valid():
            RenderingServer.call_on_render_thread(rd.free_rid.bind(copy_shader))
        if sampler.is_valid():
            RenderingServer.call_on_render_thread(rd.free_rid.bind(sampler))


func _initialize_shader() -> void:
    rd = RenderingServer.get_rendering_device()
    if not rd:
        return
    shader = rd.shader_create_from_spirv(SHAFTS_SHADER.get_spirv())
    copy_shader = rd.shader_create_from_spirv(COPY_SHADER.get_spirv())
    if not shader.is_valid() or not copy_shader.is_valid():
        return
    var sampler_state: RDSamplerState = RDSamplerState.new()
    sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
    sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
    sampler_state.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
    sampler_state.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
    sampler = rd.sampler_create(sampler_state)
    pipeline = rd.compute_pipeline_create(shader)
    copy_pipeline = rd.compute_pipeline_create(copy_shader)


func _render_callback(callback_type: int, render_data: RenderData) -> void:
    if not rd or not pipeline.is_valid() or not copy_pipeline.is_valid():
        return
    if not callback_type == EFFECT_CALLBACK_TYPE_POST_TRANSPARENT:
        return

    _mutex.lock()
    var params: Dictionary = {
        "sun_uv": _sun_screen_uv,
        "visible": _sun_visible,
        "color": _shaft_color,
        "density": _density,
        "threshold": _bright_threshold,
        "weight": _weight,
        "decay": _decay,
        "exposure": _exposure,
        "max_radius": _max_radius,
        "sample_count": _sample_count,
        "dither_strength": _dither_strength,
        "debug_overlay_strength": _debug_overlay_strength,
        "debug_overlay_color": _debug_overlay_color,
    }
    _mutex.unlock()
    var sun_uv: Vector2 = params["sun_uv"]
    if not params["visible"] or not sun_uv.is_finite() or params["max_radius"] <= 0.0:
        return
    if params["debug_overlay_strength"] == 0.0 and (params["weight"] == 0.0 or params["exposure"] == 0.0):
        return

    var buffers: RenderSceneBuffersRD = render_data.get_render_scene_buffers() as RenderSceneBuffersRD
    if not buffers:
        return
    var size: Vector2i = buffers.get_internal_size()
    if size.x == 0 or size.y == 0:
        return

    # RenderSceneBuffersRD owns one copy per viewport/view and releases it on resize.
    # Never sample the scene colour while writing it (D3D12 SRV/UAV conflict; Vulkan race).
    if not buffers.has_texture(BUFFER_CONTEXT, SOURCE_COPY):
        buffers.create_texture(
            BUFFER_CONTEXT, SOURCE_COPY, RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT,
            COPY_USAGE, RenderingDevice.TEXTURE_SAMPLES_1, size, buffers.get_view_count(), 1, true, false
        )
    var x_groups: int = ceili(float(size.x) / WORKGROUP_SIZE)
    var y_groups: int = ceili(float(size.y) / WORKGROUP_SIZE)
    var push_constant: PackedByteArray = PackedFloat32Array([
        float(size.x), float(size.y), sun_uv.x, sun_uv.y,
        params["color"].r, params["color"].g, params["color"].b, params["color"].a,
        params["density"], params["threshold"], params["weight"], params["decay"],
        1.0, params["max_radius"], params["exposure"], 0.0,
        float(params["sample_count"]), params["dither_strength"], 0.0, 0.0,
        params["debug_overlay_strength"], params["debug_overlay_color"].r,
        params["debug_overlay_color"].g, params["debug_overlay_color"].b,
    ]).to_byte_array()

    for view: int in buffers.get_view_count():
        var source_depth: RID = buffers.get_depth_layer(view)
        var color_image: RID = buffers.get_color_layer(view)
        var source_copy: RID = buffers.get_texture_slice(BUFFER_CONTEXT, SOURCE_COPY, view, 0, 1, 1)
        if not color_image.is_valid() or not source_depth.is_valid() or not source_copy.is_valid():
            continue

        var copy_from_uniform: RDUniform = RDUniform.new()
        copy_from_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
        copy_from_uniform.binding = 0
        copy_from_uniform.add_id(color_image)

        var copy_to_uniform: RDUniform = RDUniform.new()
        copy_to_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
        copy_to_uniform.binding = 1
        copy_to_uniform.add_id(source_copy)

        var copy_uniforms: Array[RDUniform] = [copy_from_uniform, copy_to_uniform]
        var copy_uniform_set: RID = UniformSetCacheRD.get_cache(copy_shader, 0, copy_uniforms)
        var copy_list: int = rd.compute_list_begin()
        rd.compute_list_bind_compute_pipeline(copy_list, copy_pipeline)
        rd.compute_list_bind_uniform_set(copy_list, copy_uniform_set, 0)
        rd.compute_list_dispatch(copy_list, x_groups, y_groups, 1)
        # Separate lists let RenderingDevice track the copy's write -> sample dependency.
        rd.compute_list_end()

        var source_uniform: RDUniform = RDUniform.new()
        source_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
        source_uniform.binding = 0
        source_uniform.add_id(sampler)
        source_uniform.add_id(source_copy)

        var depth_uniform: RDUniform = RDUniform.new()
        depth_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
        depth_uniform.binding = 1
        depth_uniform.add_id(sampler)
        depth_uniform.add_id(source_depth)

        var target_uniform: RDUniform = RDUniform.new()
        target_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
        target_uniform.binding = 2
        target_uniform.add_id(color_image)

        var uniforms: Array[RDUniform] = [source_uniform, depth_uniform, target_uniform]
        var uniform_set: RID = UniformSetCacheRD.get_cache(shader, 0, uniforms)
        var compute_list: int = rd.compute_list_begin()
        rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
        rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
        rd.compute_list_set_push_constant(compute_list, push_constant, push_constant.size())
        rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
        rd.compute_list_end()
