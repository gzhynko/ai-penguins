extends TextureRect

@onready var scene_viewport: SubViewport = get_tree().get_first_node_in_group("g_scene_viewport")


# Called when the node enters the scene tree for the first time.
func _ready():
	texture = scene_viewport.get_texture()
