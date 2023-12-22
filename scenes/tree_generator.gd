@tool
extends Node2D

const MIN_LENGTH = 170
const HEIGHT = 150

var _tree: NodeTree = null
var _generated_tree_nodes: Array = []
var _inputs: Array = []
var attributes_count: int = 0
var attributes: Array = []

func _init():
	var gpa = NodeTree.new("GPA", 1).add_decision("High", NodeTree.new("Pass", 2)).add_decision("Medium", NodeTree.new("Fail", 2)).add_decision("Low", NodeTree.new("Fail", 2))
	_tree = NodeTree.new("Studied", 0).add_decision("Yes", NodeTree.new("Pass", 1)).add_decision("No", gpa)

func _ready():
	Global.ui = %UI
	%Attribute.attribute_defined.connect(_attribute_get_next_input)
	%Attribute.operation_canceled.connect(_cancel_attributes_receiving_operation)

func _show_input_error() -> void:
	%Popup.title = "Validation Error"
	%Popup.dialog_text = "Not all input fields are valid, please provide one output"
	%Popup.popup_centered()

# Generate a tree
func generate_tree(tree: NodeTree) -> void:
	var layers = _layers(tree, 0, [])
	var max_in_each_layer = _get_max_in_each_layer(layers)
	var min_lengths_each_layer = _get_min_lengths_in_each_layer(layers)
	_generated_tree_nodes = _draw_tree(tree, layers, max_in_each_layer, min_lengths_each_layer)

# Generate what max amount a node generates in the next level
func _layers(branch: NodeTree, layer_number: int, layers: Array) -> Array:
	if layer_number > len(layers) - 1:
		layers.append(0)
	if len(branch.decisions) == 0:
		layers[layer_number] = len(branch.parent.decisions) if layers[layer_number] < len(branch.parent.decisions) else layers[layer_number]
		return layers
	for key in branch.decisions:
		var layers_temp = _layers(branch.decisions[key], layer_number + 1, layers)
		layers[layer_number] = layers_temp[layer_number] if layers_temp[layer_number] > layers[layer_number] else layers[layer_number]
	if branch.parent and len(branch.parent.decisions) > layers[layer_number - 1]:
		layers[layer_number - 1] = len(branch.parent.decisions) if layers[layer_number - 1] < len(branch.parent.decisions) else layers[layer_number - 1]
	elif branch.parent == null:
		layers[layer_number] = 1
	return layers

# Generate How many nodes each layer has
func _get_max_in_each_layer(layers: Array) -> Array:
	var output: Array = []
	for i in range(len(layers)):
		if i > len(output) - 1:
			output.append(0)
		if i == 0:
			output[i] = layers[i]
			continue
		output[i] = output[i-1] * layers[i]
	return output

func _get_min_lengths_in_each_layer(layers: Array, index: int = 0) -> Array:
	var output: Array = []
	if index >= len(layers):
		for i in range(len(layers)):
			output.append(0.0)
		return output
	output = _get_min_lengths_in_each_layer(layers, index + 1)
	if index == len(layers) - 1:
		output[index] = MIN_LENGTH
	else:
		output[index] = output[index + 1] * layers[index + 1]
	return output

# Draw the full tree
func _draw_tree(tree: NodeTree, layers: Array, max_in_each_layer: Array, min_lengths_each_layer: Array, layer_number: int = 0, i: int = 0, gap: int = 0) -> Array:
	var nodes: Array = []
	var branch: Branch = SceneManager.create_scene_instance("branch")
	var previous_gap = (gap - i)/layers[layer_number]
	if len(tree.decisions) == 0:
		branch.last_node = true
	if tree.parent == null:
		branch.first_node = true
	var length = min_lengths_each_layer[layer_number] * max_in_each_layer[layer_number]
	branch.apply_node_tree(tree)
	branch.global_position.x = min_lengths_each_layer[layer_number] * (i + 1) - (length / 2.0) - (min_lengths_each_layer[layer_number] / 2.0) + ((previous_gap) * min_lengths_each_layer[layer_number - 1])
	branch.global_position.y = layer_number * HEIGHT
	self.add_child(branch)
	nodes.append(branch)
	for j in range(len(tree.decisions.keys())):
		var key = tree.decisions.keys()[j]
		var new_nodes = _draw_tree(tree.decisions[key], layers, max_in_each_layer, min_lengths_each_layer, layer_number + 1, j, (layers[layer_number + 1] * gap) + j)
		nodes.append_array(new_nodes)
		branch.connect_line_to_branch(new_nodes[0], key)
	return nodes

func _calculate_the_tree(tree: NodeTree) -> NodeTree:
	for key in tree.decisions:
		var decision = tree.decisions[key]
		decision.calculate_uncertainty()
		if decision.uncertainty == 0.0:
			continue
		var node = Calculator.calculate_decision(attributes, decision.data, false)
		node.parent = tree
		tree.decisions[key] = node
		node = _calculate_the_tree(node)
	return tree

# Generate a tree
func _on_generate_button_up():
#	generate_tree(_tree)
#	return
	_on_clear_button_up()
	var tree = Calculator.calculate_decision(attributes, _inputs, false)
	tree = _calculate_the_tree(tree)
	generate_tree(tree)
	%Character.position = Vector2.ZERO

func _on_attributes_count_text_changed(inputControl: InputControl):
	attributes_count = int(inputControl.value)
	%DefineAttributesButton.disabled = attributes_count <= 0

func _on_define_attributes_button_button_up():
	%AttributesCount.editable = false
	%DefineAttributesButton.disabled = true
	_attribute_get_next_input("", "", false, [], -1)
	attributes = []

func _attribute_get_next_input(_name: String, _type: String, output: bool, categories: Array, id: int) -> void:
	if id != -1:
		attributes.append(Attribute.new(_name, _type, output, categories, id))
	if attributes_count <= id + 1:
		var found = false
		for attribute in attributes:
			if attribute.output:
				found = true
				break
		if !found:
			_show_input_error()
			attributes = []
		%AttributesCount.editable = true
		%DefineAttributesButton.disabled = false
		%InputButton.disabled = len(attributes) == 0
		%Attribute.visible = false
		return
	%Attribute.initialize(id + 1, id == -1)

func _on_clear_button_up():
	for node in _generated_tree_nodes:
		node.queue_free()
	_generated_tree_nodes = []

func _on_input_button_button_up():
	%FileDialog.popup_centered()

func _on_file_dialog_file_selected(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	var splits = content.split("\n", false)
	_inputs = []
	for line in splits:
		var data = {}
		var line_splits = line.strip_escapes().split(",", false)
		var i = 0
		for attribute in attributes:
			data[attribute.name] = line_splits[i]
			if attribute.type == "Numerical":
				data[attribute.name] = float(line_splits[i])
			i += 1
		_inputs.append(data)
	%Generate.disabled = len(_inputs) == 0

func _cancel_attributes_receiving_operation() -> void:
	attributes = []
	%Generate.disabled = true
	%AttributesCount.editable = true
	%DefineAttributesButton.disabled = false
	%InputButton.disabled = true
	%Attribute.visible = false
