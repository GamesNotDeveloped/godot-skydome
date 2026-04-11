extends RefCounted


static func get_editor_viewport_3d(index := 0):
    return EditorInterface.get_editor_viewport_3d(index)


static func get_editor_camera_3d(index := 0):
    var viewport = get_editor_viewport_3d(index)
    if viewport == null:
        return null
    return viewport.get_camera_3d()


static func get_editor_viewport_size(index := 0) -> Vector2:
    var viewport = get_editor_viewport_3d(index)
    if viewport == null:
        return Vector2.ZERO
    return viewport.get_visible_rect().size
