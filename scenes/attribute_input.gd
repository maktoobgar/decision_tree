@tool
extends Control

signal attribute_defined(_name: String, _type: String, output: bool, categories: Array, id: int)
signal operation_canceled()

var text: String = "" : set = _set_text
var attribute_name: String = "" : set = _set_attribute_name, get = _get_attribute_name
var attribute_type: String = "" : set = _set_attribute_type, get = _get_attribute_type
var attribute_output: bool = false : set = _set_attribute_output, get = _get_attribute_output
var categories: Array = []
var id: int = 0

func _set_text(value: String) -> void:
	text = value
	if value == %Label.text:
		return
	%Label.text = value

func _set_attribute_name(value: String) -> void:
	attribute_name = value
	if value == %Name.value:
		return
	%Name.value = value

func _get_attribute_name() -> String:
	return %Name.value

func _set_attribute_type(value: String) -> void:
	attribute_type = value
	if value == %Type.value:
		return
	%Type.value = value

func _get_attribute_type() -> String:
	return %Type.value

func _set_attribute_output(value: bool) -> void:
	%Output.value = "1" if value else "0" if !value else %Output.value

func _get_attribute_output() -> bool:
	return %Output.value == "1"

func initialize(id: int, first: bool) -> void:
	if first:
		%Output.editable = true
	self.id = id
	self.text = Global.get_attribute_name(id + 1)
	self.visible = true

func _on_accept_button_up():
	attribute_defined.emit(attribute_name, attribute_type, attribute_output, categories, id)
	if attribute_output:
		%Output.editable = false
	attribute_name = ""
	attribute_type = "0"
	attribute_output = false
	categories = []
	%CategoriesMargin.visible = false
	for child in %Categories.get_children():
		child.queue_free()

func _on_type_item_selected(inputControl: InputControl):
	%CategoriesMargin.visible = inputControl.value == "Categorical"
	categories = [] if inputControl.value == "Numerical" else categories
	if inputControl.value == "Numerical":
		for child in %Categories.get_children():
			child.queue_free()

func _on_add_category_button_up():
	var input: InputControl = SceneManager.create_scene_instance("input_control")
	input.text = Global.number_to_string(%Categories.get_child_count() + 1) + " Category:"
	input.text_changed.connect(_category_text_changed)
	input.set_meta("id", %Categories.get_child_count())
	%Categories.add_child(input)

func _category_text_changed(inputControl: InputControl) -> void:
	var id: int = int(inputControl.get_meta("id"))
	while id > len(categories) - 1:
		categories.append("")
	categories[id] = inputControl.value

func _on_cancel_button_up():
	operation_canceled.emit()
