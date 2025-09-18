@tool
extends EditorPlugin

var Globals := {}

func _enter_tree() -> void:
	add_autoload_singleton("PlayerConnectUI", "res://addons/player-connect/Scripts/PlayerConnectSingleton.gd")
	
	# Fetch it and store in plugin-global dictionary
	var player_ui = Globals.player_ui if Globals.has("player_ui") else null

func _exit_tree() -> void:
	remove_autoload_singleton("PlayerConnectUI")
	Globals.clear()
