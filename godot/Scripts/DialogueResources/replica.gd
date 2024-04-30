class_name Replica
extends Resource

@export var author: Characters.Character
@export var text: String

func _init(author_: Characters.Character = Characters.Character.NONE, text_: String = ""):
	author = author_
	text = text_
