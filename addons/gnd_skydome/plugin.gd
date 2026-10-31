@tool
extends EditorPlugin

const SERVER_NAME := "SkydomeServer"


func _enable_plugin() -> void:
    add_autoload_singleton(SERVER_NAME, "res://addons/gnd_skydome/SkydomeServer.gd")


func _disable_plugin() -> void:
    remove_autoload_singleton(SERVER_NAME)
