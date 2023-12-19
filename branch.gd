@tool
extends Node2D

class_name Branch

@export var text: String = "Test": get = _get_text, set = _set_text
var node_tree: NodeTree = null

@onready var input_position: Vector2i = %Input.position
@onready var output_position: Vector2i = %Output.position
var _output_mouse_down: bool = false
var _input_mouse_up: bool = false
var _in_branches: Dictionary = {}
var _out_branches: Dictionary = {}

func _get_text() -> String:
	return text

func _set_text(value: String) -> void:
	%Label.text = value
	text = value

func _on_output_input_event(viewport: Node, event:InputEvent, shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_output_mouse_down = event.pressed

func _on_output_mouse_entered():
	if Global.line == null:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_output_mouse_exited():
	if _output_mouse_down:
		var line: Line = generate_line("")
		Global.line = line
		Global.out_branch = self
		_output_mouse_down = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_input_mouse_entered():
	if Global.line and Global.out_branch and self != Global.out_branch and not _out_branches.has(Global.out_branch):
		%InputSprite.scale = Vector2(5, 5)
		Global.in_branch = self

func _on_input_mouse_exited():
	%InputSprite.scale = Vector2(2.5, 2.5)
	Global.in_branch = null

func delete_line(line: Line) -> void:
	line.queue_free()

func generate_line(text: String) -> Line:
	var line: Line = SceneManager.create_scene_instance("line")
	line.text = text
	%Lines.add_child(line)
	return line

func connect_out_to_in_branch(out_branch: Branch, line: Line) -> bool:
	_out_branches[out_branch] = line
	%InputSprite.scale = Vector2(2.5, 2.5)
	line.destination_point = %Input.global_position
	return true

func connect_in_to_out_branch(in_branch: Branch, line: Line) -> bool:
	_in_branches[in_branch] = line
	return true

func apply_node_tree(node_tree: NodeTree) -> void:
	self.node_tree = node_tree
	self.text = node_tree.label

func connect_line_to_branch(branch: Branch, text: String) -> void:
	var line: Line = generate_line(text)
	branch.connect_out_to_in_branch(self, line)
	self.connect_in_to_out_branch(branch, line)
