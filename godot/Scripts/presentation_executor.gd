class_name PresentationExecutor
extends Node

var current_dialogue: CompleteDialogue = null
var is_presenting: bool :
	get:
		return current_dialogue != null

var current_replica_n: int
var current_character: Characters.Character

var current_actor_node: TalkingCharacter
var previous_actor_node: TalkingCharacter 

@onready var penguins_man: Penguins = get_tree().get_first_node_in_group("g_penguin_man")
@onready var kowalski: TalkingCharacter = penguins_man.kowalski
@onready var rico: TalkingCharacter = penguins_man.rico
@onready var skipper: TalkingCharacter = penguins_man.skipper
@onready var private: TalkingCharacter = penguins_man.private

@onready var voice_player: AudioStreamPlayer = get_tree().get_first_node_in_group("g_dialogue_voice_player")
@onready var pres_manager: PresentationManager = get_tree().get_first_node_in_group("g_presentation_man")

@onready var subtitles_label: Label = get_tree().get_first_node_in_group("g_subtitles_label")
@onready var camera: Camera = get_tree().get_first_node_in_group("g_camera")


# Called when the node enters the scene tree for the first time.
func _ready():
	voice_player.finished.connect(_on_voice_playback_finished)
	pres_manager.new_enqueued.connect(_on_new_enqueued)


func _on_new_enqueued(_new_dialogue):
	if not is_presenting and not pres_manager.present_queue.is_empty():
		current_dialogue = pres_manager.present_next_dialogue()
		_init_dialogue()


func _init_dialogue():
	current_replica_n = 0
	
	penguins_man.reset_penguins()
	camera.reset_position()
	
	execute_current_line()


func execute_current_line():
	var replica = current_dialogue.replicas[current_replica_n]
	
	# get the next replica (if any)
	var next_replica_n = current_dialogue.get_next_line_n(current_replica_n)
	var next_replica: VoicedReplica
	if next_replica_n != -1:
		next_replica = current_dialogue.replicas[next_replica_n]
	
	current_character = replica.author
	subtitles_label.text = replica.get_full_text()
	
	current_actor_node = _get_actor_node_from_character(current_character)
	camera.follow_node(current_actor_node as Node3D)
	
	current_actor_node.speak()
	if previous_actor_node:
		if current_actor_node != previous_actor_node:
			current_actor_node.stop_and_look_at(previous_actor_node as Node3D)
	elif next_replica:
		var author = next_replica.author
		if current_character != author:
			var next_actor_node = _get_actor_node_from_character(author)
			current_actor_node.stop_and_look_at(next_actor_node as Node3D)
	
	if next_replica and next_replica.author != current_character:
		previous_actor_node = current_actor_node
	
	voice_player.stream.data = replica.voice_bytes
	voice_player.play()


func _get_actor_node_from_character(character: Characters.Character) -> TalkingCharacter:
	match character:
		Characters.Character.RICO:
			return rico
		Characters.Character.KOWALSKI:
			return kowalski
		Characters.Character.PRIVATE:
			return private
		Characters.Character.SKIPPER:
			return skipper
	return null


func _on_voice_playback_finished():
	current_actor_node.finish_speaking()
	
	# wait some time before finishing the line
	await get_tree().create_timer(2.0).timeout
	
	_line_finished()


func _line_finished():
	current_actor_node.start_wandering()
	
	var next_line_n = current_dialogue.get_next_line_n(current_replica_n)
	if next_line_n == -1:
		_dialogue_finished()
	else:
		current_replica_n = next_line_n
		execute_current_line()


func _dialogue_finished():
	is_presenting = false
	current_dialogue = null
	current_replica_n = -1
	
	current_actor_node = null
	previous_actor_node = null
	
	pres_manager.done_presenting()
	var next = pres_manager.present_next_dialogue()
	if next == null:
		return
	else:
		current_dialogue = next
		_init_dialogue()
