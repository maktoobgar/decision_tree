@tool
extends Node2D

const MIN_LENGTH = 300
const HEIGHT = 150

var _tree: NodeTree = null
var _generated_tree_nodes: Array = []
var _inputs: Array = []
var attributes_count: int = 0
var attributes: Array = []

func _init():
	var _pass = NodeTree.new("Pass", 2)
	var _fail = NodeTree.new("Fail", 2)
	var studied = NodeTree.new("Studied", 1).add_decision("Yes", _pass).add_decision("No", _fail)
	var path = NodeTree.new("Sucked", 1).add_decision("No", NodeTree.new("Fail", 2)).add_decision("Yes", NodeTree.new("Pass", 2)).add_decision("Maybe", NodeTree.new("Pass", 2))
	_tree = NodeTree.new("Age", 0).add_decision("Age>18", path).add_decision("Age<18", studied)

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
	var max_in_each_layer = _get_max_in_each_layers(layers)
	var nodes = _draw_tree(max_in_each_layer, 0)
	_draw_over_nodes(nodes.duplicate(true), tree, layers, true)
	_generated_tree_nodes = _delete_all_remaining_nodes(nodes)

# Generate what max amount a node generates in the next level
func _layers(branch: NodeTree, layer_number: int, layers: Array) -> Array:
	if layer_number > len(layers) - 1:
		layers.append(0)
	for key in branch.decisions.keys():
		layers = _layers(branch.decisions[key], layer_number + 1, layers)
	if branch.parent and len(branch.parent.decisions) > layers[layer_number - 1]:
		layers[layer_number] = len(branch.parent.decisions)
	elif not branch.parent:
		layers[layer_number] = 1
	return layers

# Generate How many nodes each layer has
func _get_max_in_each_layers(layers: Array) -> Array:
	var output: Array = []
	for i in range(len(layers)):
		if i > len(output) - 1:
			output.append(0)
		if i == 0:
			output[i] = layers[i]
			continue
		output[i] = output[i-1] * layers[i]
	return output

# Draw the full tree
func _draw_tree(max_in_each_layer: Array, layer_number: int) -> Array:
	var nodes: Array = []
	if layer_number < len(max_in_each_layer) - 1:
		nodes = _draw_tree(max_in_each_layer, layer_number + 1)
	var length = MIN_LENGTH * max_in_each_layer[layer_number]
	for i in range(max_in_each_layer[layer_number]):
		var branch: Branch = SceneManager.create_scene_instance("branch")
		if layer_number == len(max_in_each_layer) - 1:
			branch.last_node = true
		if layer_number == 0:
			branch.first_node = true
		branch.global_position.x = MIN_LENGTH * (i + 1) - (length / 2.0) - (MIN_LENGTH / 2.0)
		branch.global_position.y = layer_number * HEIGHT
		self.add_child(branch)
		nodes.append(branch)
	return nodes

# Actually put values inside the nodes of the tree
func _draw_over_nodes(nodes: Array, tree: NodeTree, layers: Array, first: bool = false) -> void:
	var i = len(nodes) - 1
	if first:
		tree.branch = nodes[i]
		nodes[i].apply_node_tree(tree)
		i -= 1
	for key in tree.decisions.keys():
		var decision: NodeTree = tree.decisions[key]
		decision.branch = nodes[i]
		nodes[i].apply_node_tree(decision)
		tree.branch.connect_line_to_branch(nodes[i], key)
		i -=1
	for key in tree.decisions.keys():
		var decision: NodeTree = tree.decisions[key]
		var length = layers[decision.layer + 1] if decision.layer + 1 < len(layers) else 0
		_draw_over_nodes(nodes.slice(0, i + 1), decision, layers)
		i -= length

# Delete nodes that didn't get used
func _delete_all_remaining_nodes(nodes: Array) -> Array:
	var removed_nodes: Array = []
	for i in range(len(nodes)):
		if nodes[i].node_tree == null:
			nodes[i].queue_free()
			removed_nodes.append(i)
	removed_nodes.reverse()
	for i in removed_nodes:
		nodes.remove_at(i)
	return nodes

func _calculate_the_tree(tree: NodeTree) -> NodeTree:
	for key in tree.decisions:
		var decision = tree.decisions[key]
		decision.calculate_uncertainty()
		if decision.uncertainty == 0.0:
			continue
		var node = Calculator.calculate_decision(attributes, decision.data, true)
		node.parent = tree
		tree.decisions[key] = node
	return tree

# Generate a tree
func _on_generate_button_up():
	_on_clear_button_up()
	var tree = Calculator.calculate_decision(attributes, _inputs, true)
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

func _cancel_attributes_receiving_operation() -> void:
	attributes = []
	%AttributesCount.editable = true
	%DefineAttributesButton.disabled = false
	%InputButton.disabled = true
	%Attribute.visible = false
