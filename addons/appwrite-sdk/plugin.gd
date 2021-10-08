tool
extends EditorPlugin


func _enter_tree():
    add_autoload_singleton("Appwrite", "res://addons/appwrite-sdk/Appwrite/appwrite.gd")

func _exit_tree():
    remove_autoload_singleton("Appwrite")
