extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var player_cam: Camera3D = $PlayerCam
@onready var interaction_ray: RayCast3D = %InteractionRay
@onready var player_prompt: Label = $PlayerCanvasLayer/PlayerPrompt

@export var sensitivity: float = 4.0
@export var allow_interact: bool = true

var allow_rotate: bool = true
var allow_movement: bool = true

func _ready() -> void:
	Input.mouse_mode = Input.MouseMode.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	#region Default Player Script
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	#endregion
	
	player_prompt.text = ""
	if interaction_ray.is_colliding() and allow_interact:
		var collider = interaction_ray.get_collider()
		if collider.has_meta(Interactable.META_IS_INTERACTABLE): # The object can be interacted with
			handle_interactable(collider)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()
	if event is InputEventMouseMotion and allow_rotate:
		rotate_y(-event.relative.x / 1000 * sensitivity)
		player_cam.rotate_x(-event.relative.y / 1000 * sensitivity)
		player_cam.rotation.x = clamp(player_cam.rotation.x, deg_to_rad(-80), deg_to_rad(90))

func handle_interactable(collider: Object) -> void:
	var interactable: Interactable = collider.get_node(collider.get_meta(Interactable.META_COMPONENT_NAME))
	player_prompt.text = interactable.get_prompt()
	
	if Input.is_action_just_pressed("interact"):
		if interactable.get_interaction_mode() == Interactable.InteractionMode.HOLD: #Special case for Hold type interaction
			interactable.process_interaction_event(true)
			# Set to true or remove these lines if you want the player to move and rotate, but this is prone to breaking the interaction system
			allow_movement = false
			allow_rotate = false 
		else:
			interactable.process_interaction_event()
		
	if Input.is_action_just_released("interact"):
		allow_movement = true
		allow_rotate = true
		if interactable.get_interaction_mode() == Interactable.InteractionMode.HOLD:
			interactable.process_interaction_event(false)
