extends CharacterBody2D

@onready var Patrol1 = $PatrolPoints/PP1
@onready var Patrol2 = $PatrolPoints/PP2
@onready var WallRaycast = $Raycasts/WallDetect
@onready var HoleRaycast = $Raycasts/HoleDetect
@onready var ray_to_player = $Raycasts/ToPlayerRaycast
@onready var gapRaycast = $Raycasts/GapCalculator
@onready var guard_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var detection_area_shape = $DetectionArea/CollisionShape2D


#potions
var is_sleep = false
var is_slowed = false
@onready var slow_timer = $SlowTimer
var speed = 2500.0 #when returning to patrol state

@export var patrol_speed: float = 2500.0 ##very initial speed
@export var chase_speed = 14000.0 #player shouldnt be able to outrun normally
@export var jump_strength_x = 2.0 ##for gaps
@export var jump_strength_y = 300.0 ##for gaps


var gravity_value = ProjectSettings.get_setting("physics/2d/default_gravity")

#dont ask why there's so many
var player_in_area: bool = false
var spotted_once: bool = false
var player_entered: bool = false
var player_los: bool = false #line of sight
var direction
var current_destination: Vector2
var current_patrol_point: Vector2
var last_patrol_point: Vector2
var player
var to_cliff: float
var distance_to_player

#"states"
var is_idle: bool = false
var is_chasing: bool = false

func _ready():
	player = get_tree().get_first_node_in_group("player")
#	$PP1.visible = false uncomment after testing to hide patrol points
#	$PP2.visible = false
	current_patrol_point = Patrol2.position
	current_destination = current_patrol_point
	direction = position.direction_to(current_destination.position)
	SignalBus.is_slept.connect(fell_asleep)
	SignalBus.is_awake.connect(woke_up)
	SignalBus.is_slowed.connect(slowed)
	SignalBus.not_slowed.connect(not_slowed)
	direction = position.direction_to(current_destination)
	
func _physics_process(delta):
	flip_sprite()
	raycast_business()
	move(delta)
	gravity(delta)
	animation_handler()
	chase()
	player_detection()
	player_in_area = detection_area.overlaps_body(player) #scans every frame not just on enter
	scan_for_player()
		
	move_and_slide()

func slowed():
	if is_slowed:
		speed = 1000
		patrol_speed = 100
		chase_speed = 4000
		slow_timer.start()

func not_slowed():
	speed = 2500
	patrol_speed = 200
	chase_speed = 8000

func fell_asleep():
	if is_sleep:
		player.watched = false
		is_chasing = false
		speed = 0

func woke_up():
	speed = 2500.0

func gravity(delta):
	if not is_on_floor():
		velocity.y += gravity_value * delta
		
func idle():#stand around for a few, unless something changes
	$IdleTimer.start()
	velocity.x = 0
	is_idle = true
	guard_sprite.play("idle")
	
func raycast_business(): #jump over cliffs
	gap_distance()
	if WallRaycast.is_colliding() && !is_idle:
		velocity.y -= 20
		velocity.x += 5*direction.x #just to stop him from getting stuck on wall in peculiar case
	if !HoleRaycast.is_colliding() && $GapJumpCD.is_stopped() && gapRaycast.is_colliding(): #hops
#		gapRaycast.enabled = true
		$GapJumpCD.start() #to stop forces from constantly applying
		velocity.y -= jump_strength_y
		velocity.x += jump_strength_x*(round(direction.x)) * to_cliff
#		gapRaycast.enabled = false
#	elif !HoleRaycast.is_colliding(): trying to get him to turn around if there's no 
#		idle()

func animation_handler():
	if !is_chasing && !is_idle:
		guard_sprite.play("walk")
	
func chase():
	if is_chasing:
		direction = position.direction_to(player.global_position)
		speed = chase_speed
		player.watched = true

func _on_pp_2_area_body_entered(body):
	if body == self && !is_chasing:
		idle()
		current_destination = Patrol1.position
		direction = position.direction_to(current_destination)


func _on_pp_1_area_body_entered(body):
	if body == self && !is_chasing:
		idle()
		current_destination = Patrol2.position
		direction = position.direction_to(current_destination)

func move(delta):
	if !is_idle && HoleRaycast.is_colliding() && !player.dying:
		if direction.x < 0:
			velocity.x = floor(direction.x)*speed*delta
		elif direction.x > 0: #should already be exclusive but just in case
			velocity.x = ceil(direction.x)*speed*delta
func gap_distance(): #increases x jump speed according to gap
	gapRaycast.enabled = !HoleRaycast.is_colliding()
	if gapRaycast.is_colliding():
		var collision_point = gapRaycast.get_collision_point()
		to_cliff = position.distance_to(collision_point)

func flip_sprite():
	if !is_idle && direction.x != 0 && !player.dying: #it gets fducky when it goes to 0, rounds -0.4 -> 0 rather than -1
		guard_sprite.flip_h = ((direction.x) < 0)
		if direction.x > 0: #if positive, round up to 1
			WallRaycast.target_position.x = 32*(ceil(direction.x)) #ceiling is round up
			HoleRaycast.position.x = 14*(ceil(direction.x))
			gapRaycast.target_position.x = 160*(ceil(direction.x))
			gapRaycast.position.x = 24*(ceil(direction.x))
			detection_area_shape.position.x = 102*(ceil(direction.x))
		elif direction.x < 0: #if negative, round down to 0
			WallRaycast.target_position.x = 32*(floor(direction.x)) #floor is round down
			HoleRaycast.position.x = 14*(floor(direction.x))
			gapRaycast.target_position.x = 160*(floor(direction.x))
			gapRaycast.position.x = 24*(floor(direction.x))
			detection_area_shape.position.x = 102*(floor(direction.x))
func _on_idle_timer_timeout(): #to make him idle at patrol points
	is_idle = false

func spotted_player(): #on area body entered, ACTIVATES CHASE BOOL
		is_idle = false #break idle on detection
		if !guard_sprite.animation == "attack":
			guard_sprite.play("chase") #stop from interrupting attack
		$LoseAggroTimer.stop() #this WONT trigger the timeout effect, but will reset timer
		last_patrol_point = current_destination
		is_chasing = true


func _on_lose_aggro_timer_timeout(): #stop chasing if LOS broken for too long
	guard_sprite.play("walk")
	is_chasing = false
	direction = position.direction_to(last_patrol_point)
	speed = patrol_speed
	player.watched = false

func kill_mode(): #THE FINAL STRIKE
	distance_to_player = (position - player.global_position)
	if abs(distance_to_player.x) < 40 && abs(distance_to_player.y) < 20 && !player.dying:
		guard_sprite.play("attack")
		SignalBus.player_died.emit()
		velocity.x = 0
		
		#realized this makes boxes useless so commented out for now
func _on_stealth_detect_area_body_entered(body): #THE CLOSE HITBOX
	if body == player && player.is_stealthed && !player.is_hidden: #check stealth
		player_entered = true
		ray_to_player.set_deferred("enabled",true)


func scan_for_player():
	if player_in_area:
		if (!player.is_stealthed || is_chasing): #should only apply to player
			ray_to_player.set_deferred("enabled",true)
			player_entered = true
			
func _on_detection_area_body_entered(body):
	pass

func _on_detection_area_body_exited(_body):
	ray_to_player.set_deferred("enabled",false)
	player_entered = false
	$LoseAggroTimer.start()
	

func patrol_points_setter(): #this broke for no reason so here's a function
	var PP1globalP = $PP1.global_position
	var PP2globalP = $PP2.global_position
	$PP1.top_level = true #stop the patrol points
	$PP2.top_level = true #from moving with parent
	await get_tree().create_timer(0.1)
	$PP1.global_position = PP1globalP
	$PP2.global_position = PP2globalP #this is genuinely mind boggling
	#becoming top_level ruins positioning, so we're saving them first


func _on_slow_timer_timeout():
	is_slowed = false
	not_slowed()

func player_detection(): #CLEAR LOS/ AGGRO FUNC
	if player_entered == true: #points raycast to the player
		ray_to_player.set_target_position(player.global_position - ray_to_player.global_position)
		if ray_to_player.is_colliding() && ray_to_player.get_collider() == player: #checks if first object hit is player
			if !spotted_once:
				spotted_player() #RUNS ONCE UNLESS THE SITUATION CHANGES
				spotted_once = true
				kill_mode()

			else:
				if spotted_once: #RUNS ONCE UNLESS THE SITUATION CHANGES
					$LoseAggroTimer.start() #breaks aggro if in area AND in LOS
					spotted_once = false #the timer keeps starting in the area so it doesnt timeout
					
			

