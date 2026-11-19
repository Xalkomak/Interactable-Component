# Xalkomak's Interaction System

A lightweight, component-based interaction system for Godot. Attach an `Interactable` node to a `PhysicsBody2D` or `PhysicsBody3D` to register its parent as an interactable object.

The system supports four interaction modes:

- **One Shot**: interaction can be performed once.
- **Toggle**: interaction switches between two states.
- **Hold**: interaction remains active while the interaction input is held.
- **Always**: the object remains available for interaction regardless of its internal state.

The `Interactable` component handles interaction state, availability, prompts, and method dispatch. The parent object defines what actually happens when interacted with.

---

## Installation

1. Add the `Interactable` node as a child of a `PhysicsBody2D` or `PhysicsBody3D`.
2. Attach a script to the parent object.
3. Configure the `Interactable` node using the Inspector.
4. In your player/controller script, detect interactable objects and call `process_interaction_event()` when the player interacts.

The parent must preferably be a physics body. The demo player detects objects using a raycast.

---

## Inspector Properties

| Property | Type | Description |
|---|---|---|
| `interaction_mode` | `InteractionMode` | Determines how the interaction behaves. |
| `interact_prompt` | `String` | Prompt displayed when the object can be interacted with. Leave empty to display no prompt. |
| `interact_prompt_toggle` | `String` | Alternate prompt used by Toggle mode. |
| `allow_interact` | `bool` | Determines whether the object can currently be interacted with. |
| `call_method` | `StringName` | Name of the method called on the parent when interaction is processed. |
| `delta_threshold` | `float` | Maximum input delay used by the Hold-mode timing safeguard. |

### Interaction Modes

#### One Shot

The interaction is processed once. After the interaction, `allow_interact` is set to `false` (unless the `toggle` argument supplied to `process_interaction_event()` changes it).

Use this mode for interactions that only need to happen once, like triggering a cutscene or launching a nuke.

#### Toggle

Each interaction switches `interaction_state` between `true` and `false`.

The component can return different prompts depending on its state:

- `interact_prompt` when the state is `false`.
- `interact_prompt_toggle` when the state is `true`.

Use this mode for switches, lights, or other binary state-changing interactions.

#### Hold

The interaction state is set to the value supplied through the `toggle` argument of `process_interaction_event()`.

- Call `process_interaction_event(true)` when the interaction begins.
- Call `process_interaction_event(false)` when the interaction ends.

The component uses `delta_threshold` to track input time in its Hold-mode processing. In the demo player, movement and camera rotation are disabled while holding an interaction to avoid losing the raycast target.

> **Note:** Hold-mode input handling depends on the player/controller implementation. The included demo controller locks movement and camera rotation while holding. If you have a better way of implementing Hold mode, feel free to contribute.

#### Always

The interaction does not change `interaction_state`. It remains available for interaction, subject to `allow_interact`.

Use this mode for actions that can be performed repeatedly without maintaining a toggle state.

---

## How It Works

### Registration

When the `Interactable` node enters the scene, it sets metadata on its parent:

- `Interactable`: marks the parent as an interactable object.
- `InteractableNodeName`: stores the name of the child component.

The player/controller can check for the metadata and retrieve the component without requiring the parent to use a particular custom class.

### Interaction prompts

Call `get_prompt()` to retrieve the prompt text for the current mode and state.

| Mode | Returned prompt |
|---|---|
| One Shot & Always | `interact_prompt` |
| Toggle | `interact_prompt` or `interact_prompt_toggle`, depending on state |
| Hold | `interact_prompt` when inactive; empty while active |
| Any mode when interaction is unavailable | Empty string |

### Method dispatch

When `process_interaction_event()` is called, the component attempts to call the method named by `call_method` on its parent.

If the parent does not have the configured method, an error is printed.

---

## API

### Constants

| Constant | Value | Purpose |
|---|---|---|
| `META_IS_INTERACTABLE` | `"Interactable"` | Metadata key used to identify an interactable parent. |
| `META_COMPONENT_NAME` | `"InteractableNodeName"` | Metadata key containing the component's node name. |

### Enum: `InteractionMode`

```
enum InteractionMode {
	ONE_SHOT,
	TOGGLE,
	HOLD,
	ALWAYS,
}
```

Provides the core structure for various interaction. Has the potential to be expanded.

### Variables

| Variable | Description |
|---|---|
| `interaction_mode` | Selected interaction mode. |
| `interact_prompt` | Main interaction prompt. |
| `interact_prompt_toggle` | Alternate Toggle-mode prompt. |
| `allow_interact` | Whether interaction is currently allowed. |
| `call_method` | Parent method to invoke. |
| `delta_threshold` | Hold-mode timing threshold. |
| `interaction_state` | Current interaction state, used by Toggle and Hold modes. |
| `elapsed` | Time accumulated by Hold-mode processing. |

### Functions

#### `get_prompt() -> String`

Returns the prompt appropriate to the interaction mode and current state. Returns an empty string if interaction is unavailable.

#### `process_interaction_event(toggle: bool = false) -> void`

Processes an interaction event, updates state as appropriate for the selected mode, and calls the configured method on the parent.

For Hold mode, pass `true` when starting and `false` when ending the interaction.

---

## Example Parent Script

This example demonstrates a few different behaviours. The method names assigned to `call_method` in the Inspector must match methods on the parent.

```
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
```

The actual behaviour is defined by the parent script; the `Interactable` component only invokes the configured method.

---

## Player/Controller Integration

The included demo controller uses a `RayCast3D` to detect objects in front of the player.

### Detecting an interactable

```
if interaction_ray.is_colliding() and allow_interact:
	var collider = interaction_ray.get_collider()
	if collider.has_meta(Interactable.META_IS_INTERACTABLE):
		handle_interactable(collider)
```

### Retrieving the component

```
var interactable: Interactable = collider.get_node(
	collider.get_meta(Interactable.META_COMPONENT_NAME)
)
```

### Handling input

The demo controller calls `process_interaction_event()` when the interaction input is pressed. Hold mode is handled separately so the controller can signal the beginning and end of the interaction.

```gdscript
if Input.is_action_just_pressed("interact"):
	if interactable.interaction_mode == Interactable.InteractionMode.HOLD:
		interactable.process_interaction_event(true)
		allow_movement = false
		allow_rotate = false
	else:
		interactable.process_interaction_event()

if Input.is_action_just_released("interact"):
	allow_movement = true
	allow_rotate = true
	if interactable.interaction_mode == Interactable.InteractionMode.HOLD:
		interactable.process_interaction_event(false)
```

This is an example integration, not a requirement for every project. Your own player/controller can implement target detection, input handling, and Hold-mode behaviour differently.

---

## Demo

The demo scene contains objects configured to showcase each interaction mode. You can experiment with their `Interactable` properties through the Inspector.

---

## Notes

- The interaction input action in the included demo is named `interact`. Add it to **Project Settings → Input Map**.
- The configured `call_method` must exist on the parent node.
- The parent is registered through metadata when the component enters the scene tree.
- The demo controller uses a raycast and therefore requires appropriate collision layers/masks and physics collision on the interactable objects.
- The demo's Hold interaction disables movement and camera rotation while active to keep the target acquired. If you have a better way of handling this, feel free to contribute.
