extends Node2D

@onready var ray_to_player = $RayCast2D
var player
var player_position
var player_entered: bool = false
var tilemap

func _ready():
	player = get_tree().get_first_node_in_group("player")
	tilemap = get_tree().get_first_node_in_group("tilemap")
	
func _physics_process(_delta):
	player_detection()

func _on_detection_area_body_entered(body):
	if body.name == "Player": #should only apply to player
		ray_to_player.enabled = true
		player_entered = true

func _on_detection_area_body_exited(body):
	if body.name == "Player":
		player_entered = false
		ray_to_player.enabled = false
		player.enter_stealth() #assuming nothing else is going on, should add to player script
		player.stealth_eye.frame = 0 #or else it wont go back
		#here, write if: for all the player states where hidden would be granted (by potions, mostly)
		player.is_hidden = false #in some interactions with smoke(?), player kept hidden falsely


#func reset():
#	player_entered == false

func player_detection(): #its just so much easier than cast_ray()
	if player_entered == true && !player.is_statue && !player.is_invisible: #points raycast to the player IS BEING CALLED
		ray_to_player.set_target_position(player.global_position - ray_to_player.global_position)
		if ray_to_player.is_colliding() && ray_to_player.get_collider() == tilemap:
			pass #stops player from getting lit up through tilemap
		elif ray_to_player.is_colliding() && (ray_to_player.get_collider() is Area2D): #collides with areas only?? this works for the box
			if ray_to_player.get_collider().get_name() == "SmokeArea":
				pass #do nothing if in a smoke (leaves player in stealthed state)
			else: #if player is behind a prop, or in its shadow
				player.is_stealthed = true 
				player.is_hidden = true
				player.stealth_eye.frame = 2 #new hidden icon
				player.enter_stealth()

		elif ray_to_player.is_colliding() && (ray_to_player.get_collider() == player): #no obstuction in LOS (lit up) AUG8 BUG: LIGHTS UP PLAYERS THROUGH TILEMAP
			player.is_stealthed = false
			player.is_hidden = false
			player.stealth_eye.frame = 1 #lit up icon
			player.exit_stealth()
