class_name TalkingCharacter
extends MovingCharacter

@onready var talk_anims: AnimationPlayer = $"TalkAnimPlayer"


# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()


func reset_state():
	super.reset_state()
	finish_speaking()


func speak():
	talk_anims.play("talk")
	talk_anims.advance(randf_range(0.0, 0.3))


func finish_speaking():
	talk_anims.seek(0, true)
	talk_anims.stop()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super._process(delta)
