@tool
extends Control

class_name Attribute

signal attribute_defined(name: String, _type: String, id: int)

var text: String = "" : set = _set_text
var attribute_name: String = "" : set = _set_attribute_name, get = _get_attribute_name
var attribute_type: String = "" : set = _set_attribute_type, get = _get_attribute_type
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

func initialize(id: int) -> void:
	self.id = id
	self.text = Global.get_attribute_name(id + 1)
	self.visible = true

func _on_accept_button_up():
	attribute_defined.emit(attribute_name, attribute_type, categories, id)
	attribute_name = ""
	attribute_type = "0"
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
