extends Node2D

var player
var player_entered #toggle raycast tracking
var is_sleep = false
@onready var animated_sprite_2d = $AnimatedSprite2D

@onready var ray_to_player = $RayCast2D

func _ready():
	player = get_tree().get_first_node_in_group("player")
	SignalBus.is_slept.connect(fell_asleep)
	SignalBus.is_awake.connect(woke_up)
	
func _physics_process(_delta):
	player_detection()

func fell_asleep():
	if is_sleep:
		animated_sprite_2d.play("sleep")
		player.watched = false

func woke_up():
	animated_sprite_2d.play("idle")

			
func _on_detection_area_body_entered(body):
	if body.name == "Player": #should only apply to player
		ray_to_player.set_deferred("enabled",true)
		player_entered = true

func _on_detection_area_body_exited(_body):
	ray_to_player.set_deferred("enabled",false)
	player_entered = false
	player.watched = false
	
func player_detection():
	if player_entered == true and !is_sleep: #points raycast to the player
		ray_to_player.set_target_position(player.global_position - ray_to_player.global_position)
		if ray_to_player.is_colliding() && ray_to_player.get_collider() == player: #checks if first object hit is player
			player.watched = true
			print("yep... thats him") #ideally, this part will warn enemies
			#or do whatever the watcher does when it detects the player
		else:
			player.watched = false
