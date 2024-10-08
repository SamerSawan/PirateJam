extends RigidBody2D

var currentPotion : String
@onready var sprite_2d = $Sprite2D
var potion_parent
var mouse_position
var smoke = preload("res://scenes/entities/environment/Potions/smoke.tscn")
var sleep = preload("res://scenes/entities/environment/Potions/sleep.tscn")
var slime = preload("res://scenes/entities/environment/Potions/Slime.tscn")
var strength = preload("res://scenes/entities/environment/Potions/strength.tscn")

func _ready():
	mouse_position = get_tree().get_first_node_in_group("player").get_local_mouse_position().normalized()
	potion_parent = get_tree().get_first_node_in_group("potion_thrower")
	if !potion_parent.drinkable_potion:
		linear_velocity = potion_parent.potion_velocity*mouse_position
	if potion_parent.potion_resource:
		currentPotion = potion_parent.potion_resource.name #transfer name of current potion (?)
		match currentPotion: #adjust the look of the potion according to current potion
			"InvisPotion":
				sprite_2d.frame = 0
			"SlimePotion":
				sprite_2d.frame = 1
			"StatuePotion":
				sprite_2d.frame = 2
			"SmokePotion":
				sprite_2d.frame = 3
			"StrengthPotion":
				sprite_2d.frame = 4
			"NoisePotion":
				sprite_2d.frame = 5
			"DashPotion":
				sprite_2d.frame = 6
			"SleepPotion":
				sprite_2d.frame = 7
	SignalBus.potion_changed.emit()

func _on_area_2d_body_entered(_body): #when it hits something (usually world)
	if get_node("SoundQueue_PotionShatter") != null: #stops certain spam potion crashing i think
		var sound_queue = get_node("SoundQueue_PotionShatter")
		sound_queue.reparent(get_node("/root"), true) 
		sound_queue.play_sound()
	match currentPotion: #adjust effect of potion according to equipped potion
			"InvisPotion":
				SignalBus.activate_invis.emit()
			"SlimePotion":
				var slime_instance = slime.instantiate()
				potion_parent.potion_container.call_deferred("add_child", slime_instance)
				slime_instance.global_position = global_position
			"StatuePotion":
				SignalBus.activate_statue.emit()
			"SmokePotion":
				var smoke_instance = smoke.instantiate()
				potion_parent.potion_container.call_deferred("add_child", smoke_instance)
				smoke_instance.global_position = global_position
			"StrengthPotion":
				SignalBus.activate_strength.emit()
			"NoisePotion":
				pass
			"DashPotion":
				SignalBus.activate_dash.emit()
			"SleepPotion":
				var sleep_instance = sleep.instantiate()
				potion_parent.potion_container.call_deferred("add_child", sleep_instance)
				sleep_instance.global_position = global_position
	queue_free() 


