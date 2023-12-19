@tool
extends Node2D

const MIN_LENGTH = 300
const HEIGHT = 150
var _tree: NodeTree = null

func _init():
	var _pass = NodeTree.new("Pass", 2)
	var _fail = NodeTree.new("Fail", 2)
	var studied = NodeTree.new("Studied", 1).add_decision("Yes", _pass).add_decision("No", _fail)
	_tree = NodeTree.new("Age", 0).add_decision("Age>18", studied).add_decision("Age<18", NodeTree.new("Fail", 1).add_decision("No", NodeTree.new("Fail", 2)))

# Generate a tree
func generate_tree(tree: NodeTree) -> void:
	var layers = _layers(tree, 0, [])
	var max_in_each_layer = _get_max_in_each_layers(layers)
	var nodes = _draw_tree(max_in_each_layer, 0)
	_draw_over_nodes(nodes.duplicate(true), tree, layers, true)
	_delete_all_remaining_nodes(nodes)

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
		branch.global_position.x = MIN_LENGTH * (i + 1) - (length / 2) - (MIN_LENGTH / 2)
		branch.global_position.y = layer_number * HEIGHT
		self.add_child(branch)
		nodes.append(branch)
	return nodes

# Actually put values inside the nodes of the tree
func _draw_over_nodes(nodes: Array, tree: NodeTree, layers: Array, first: bool = false) -> void:
	if first:
		tree.branch = nodes[len(nodes) - 1]
		nodes.pop_back().apply_node_tree(tree)
	for key in tree.decisions.keys():
		var decision: NodeTree = tree.decisions[key]
		decision.branch = nodes[len(nodes) - 1]
		nodes[len(nodes) - 1].apply_node_tree(decision)
		tree.branch.connect_line_to_branch(nodes.pop_back(), key)
	for key in tree.decisions.keys():
		var decision: NodeTree = tree.decisions[key]
		var length = layers[decision.layer + 1] if decision.layer + 1 < len(layers) else 0
		_draw_over_nodes(nodes.duplicate(true), decision, layers)
		for i in range(length):
			nodes.pop_back()

# Delete nodes that didn't get used
func _delete_all_remaining_nodes(nodes: Array) -> void:
	for node in nodes:
		if node.node_tree == null:
			node.queue_free()

# Generate a tree
func _on_button_button_up():
	generate_tree(_tree)