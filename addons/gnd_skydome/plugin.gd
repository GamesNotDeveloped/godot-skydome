@tool
extends EditorPlugin

const SERVER_NAME := "SkydomeServer"


## The scenes open with a Skydome in them made it with no server: they are reloaded once the
## autoload is in, so their Skydome is made anew with it
func _enable_plugin() -> void:
    add_autoload_singleton(SERVER_NAME, "res://addons/gnd_skydome/SkydomeServer.gd")
    for i in 10:
        if Engine.has_singleton(SERVER_NAME):
            break
        await get_tree().process_frame
    for root: Node in EditorInterface.get_open_scene_roots():
        if not root.scene_file_path.is_empty() and _has_skydome(root):
            EditorInterface.reload_scene_from_path(root.scene_file_path)


func _disable_plugin() -> void:
    remove_autoload_singleton(SERVER_NAME)


func _has_skydome(root: Node) -> bool:
    return root is Skydome or root.find_children("*", "", true, false).any(func(node: Node) -> bool:
        return node is Skydome)
