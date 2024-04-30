class_name VoicedReplica
extends Resource

@export var author: Characters.Character
@export var text: String
@export var voice_bytes: PackedByteArray

func _init(author_: Characters.Character = Characters.Character.NONE, text_: String = "", voice_bytes_: PackedByteArray = PackedByteArray()):
	author = author_
	text = text_
	voice_bytes = voice_bytes_

func get_full_text() -> String:
	return "{0}: {1}".format([Characters.character_to_string_capitalized(author), text])
