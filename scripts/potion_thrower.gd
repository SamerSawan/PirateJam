extends Node2D

@onready var potion_container = $potion_container
@export var potion_velocity: Vector2 = Vector2(500,500)
var potion = preload("res://scenes/entities/player/potion.tscn")
var hotbar = preload("res://Inventory/HotBar.tres")
var player
var potion_resource = SignalBus.equipped_potion
var drinkable_potion: bool = false
var is_aiming: bool = false
var cancelled_throw: bool = false #better cancelling
var menu_opened: bool = false

func _ready():
	player = get_tree().get_first_node_in_group("player")
	SignalBus.potion_changed.connect(update_potion)
	SignalBus.craft_menu_visibility_changed.connect(menu_open)
	
func _physics_process(delta):
	if potion_resource != null && !menu_opened:
		if !player.is_statue && !drinkable_potion && !cancelled_throw: #for throwing
			charge_throw(delta)
			
		elif !player.is_statue && drinkable_potion: #for a delish bev
			drink()

func update_potion(): #two of the if statements of all time
	potion_resource = SignalBus.equipped_potion
	if potion_resource != null:
		if (potion_resource.name == "InvisPotion")||(potion_resource.name == "StatuePotion")||(potion_resource.name == "StrengthPotion")||(potion_resource.name == "DashPotion"):
			drinkable_potion = true
		elif (potion_resource.name == "SlimePotion")||(potion_resource.name == "SmokePotion")||(potion_resource.name == "NoisePotion")||(potion_resource.name == "SleepPotion"):
			drinkable_potion = false
		SignalBus.update_drinkability.emit()

func charge_throw(delta):
	if Input.is_action_pressed("LeftClick") && player.is_on_floor() && player.velocity.x == 0:
		if Input.is_action_pressed("MoveRight") || Input.is_action_pressed("MoveLeft") || Input.is_action_pressed("Jump"):
			player.change_animation_state(0) #cancel throw
			potion_velocity = Vector2(500,500) #reset initial throw speeds on cancel
			is_aiming = false
			cancelled_throw = true
			
		elif potion_velocity.x < 600 && potion_velocity.y < 600: #charge up throw
			potion_velocity.x += (100 * delta) #charge up throw
			potion_velocity.y += (100 * delta)
			player.change_animation_state(2) #code for windup
			is_aiming = true
	elif player.new_state == 2:
		shoot() #activates on mouse release, during windup

func drink():
	if Input.is_action_just_pressed("LeftClick") && player.is_on_floor(): #THROWS STRAIGHT DOWN
		player.change_animation_state(3)
		potion_velocity = Vector2(0,-500)
		var potion_instance = potion.instantiate()
		hotbar.remove(potion_resource)
		potion_container.add_child(potion_instance)
		potion_instance.global_position = $Marker2D.global_position
		potion_velocity = Vector2(500,500)

func shoot():
	if Input.is_action_just_released("LeftClick"): #fire on release
		player.change_animation_state(3) #code for throw
		var potion_instance = potion.instantiate()
		hotbar.remove(potion_resource) #remove currently used potion
		potion_container.add_child(potion_instance)
		potion_instance.global_position = $Marker2D.global_position #spawn on player
		potion_velocity = Vector2(500,500) #reset initial throw speeds after every throw
		SignalBus.update_drinkability.emit()
		is_aiming = false #AUG6 idk if this does anything

func _input(event): #to prevent throwing if u forget to let go while/after moving
	if event.is_action_released("LeftClick"):
		cancelled_throw = false

func menu_open():
	menu_opened = !menu_opened
