extends StaticBody3D

var material: StandardMaterial3D
var is_rotating: bool = false
var interactable_node: Interactable
var parent: MeshInstance3D

func _ready() -> void:
	material = (get_parent() as MeshInstance3D).get_surface_override_material(0)
	interactable_node = get_node(get_meta(Interactable.META_COMPONENT_NAME))
	if interactable_node.interaction_mode == Interactable.InteractionMode.HOLD:
		parent = get_parent() as MeshInstance3D

func _physics_process(delta: float) -> void:
	if parent:
		if interactable_node.interaction_state:
			parent.rotate_y(delta * 5)

func make_sphere_black() -> void:
	material.albedo_color = Color.BLACK

func toggle_sphere_color() -> void:
	material.albedo_color = Color.BLACK if interactable_node.interaction_state else Color.WHITE

func rotate_cube() -> void:
	var parent := get_parent() as MeshInstance3D
	var tween := get_tree().create_tween()

	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(parent, "rotation:y", parent.rotation.y + deg_to_rad(90), 1.0)

func hold_rotate_cube() -> void:
	is_rotating = interactable_node.interaction_state
