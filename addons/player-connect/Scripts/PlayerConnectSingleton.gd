@tool
extends Node

# Preload the scene
const PLAYER_SCENE = preload("res://addons/player-connect/Scenes/player-connect_ui.tscn")
var player_ui: Node = null

func _ready():
	if not player_ui:
		player_ui = PLAYER_SCENE.instantiate()
		add_child(player_ui)
