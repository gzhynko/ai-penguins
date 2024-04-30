extends Node

signal received_inference_stats(stats_array: Array[float])

var console_window: PackedScene = preload("res://Scenes/console_window.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	var window_instance = console_window.instantiate()
	add_child(window_instance)

