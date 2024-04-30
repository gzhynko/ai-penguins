class_name PresentationManager
extends Node

signal enqueue_for_present(id: int, dialogue: CompleteDialogue)
signal remove(id: int)

signal new_enqueued(dialogue: CompleteDialogue)
signal present_queue_updated(new_queue: Dictionary)
signal current_presented_updated(new_presented: CompleteDialogue)

var present_queue: Dictionary 
var current_presented: CompleteDialogue


# Called when the node enters the scene tree for the first time.
func _ready():
	enqueue_for_present.connect(_on_enqueue_for_present)
	remove.connect(_on_remove)


func done_presenting():
	current_presented = null
	current_presented_updated.emit(null)


func present_next_dialogue() -> CompleteDialogue:
	if present_queue.is_empty():
		return null
	var next_in_queue = present_queue.values()[0]
	current_presented = next_in_queue
	
	current_presented_updated.emit(current_presented)
	present_queue.erase(present_queue.keys()[0])
	present_queue_updated.emit(present_queue)
	
	
	return current_presented


func _on_enqueue_for_present(id: int, dialogue: CompleteDialogue):
	present_queue[id] = dialogue
	present_queue_updated.emit(present_queue)
	new_enqueued.emit(dialogue)


func _on_remove(id: int):
	present_queue.erase(id)
	present_queue_updated.emit(present_queue)
