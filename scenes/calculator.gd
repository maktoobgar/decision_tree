@tool
extends Node

func choose_tree_between_all_trees(trees: Array, gain_ratio: bool) -> NodeTree:
	var output_tree: NodeTree = null
	for tree in trees:
		if gain_ratio:
			if output_tree == null:
				output_tree = tree
				continue
			if tree.gain_ratio > output_tree.gain_ratio:
				output_tree = tree
		else:
			if output_tree == null:
				output_tree = tree
				continue
			if tree.gain > output_tree.gain:
				output_tree = tree
	return output_tree

func calculate_decision(attributes: Array, inputs: Array, gain_ratio: bool) -> NodeTree:
	var target_attribute: Attribute = null
	for attribute in attributes:
		if attribute.output:
			target_attribute = attribute
	var trees = []
	for attribute in attributes:
		attribute = attribute as Attribute
		if attribute.output:
			continue
		var _inputs = inputs.duplicate(true)
		var difference = func(a: Dictionary, b: Dictionary) -> bool:
			return a[attribute.name] < b[attribute.name]
		_inputs.sort_custom(difference)
		var middle: float = -1
		if attribute.type == "Numerical":
			for i in range(len(_inputs)):
				var tree: NodeTree = NodeTree.new(attribute.name, -1)
				var input = _inputs[i]
				# Find the middle number
				if input[attribute.name] > middle:
					middle = input[attribute.name]
				else:
					continue
				# Find the bigger and smaller than middle number items
				var bigger_than_mids = []
				var smaller_than_mids = []
				for j in range(len(_inputs)):
					if _inputs[j][attribute.name] >= middle:
						bigger_than_mids.append(_inputs[j])
					elif _inputs[j][attribute.name] < middle:
						smaller_than_mids.append(_inputs[j])
				# Find all categories of bigger_than_mid and smaller_than_mid and categorize them
				var bigger_than_mids_categories = []
				for whatever in target_attribute.categories:
					bigger_than_mids_categories.append([])
				var smaller_than_mids_categories = []
				for whatever in target_attribute.categories:
					smaller_than_mids_categories.append([])
				var all_categories = []
				for whatever in target_attribute.categories:
					all_categories.append([])
				for j in range(len(bigger_than_mids)):
					for k in range(len(target_attribute.categories)):
						if bigger_than_mids[j][target_attribute.name] == target_attribute.categories[k]:
							bigger_than_mids_categories[k].append(bigger_than_mids[j])
							all_categories[k].append(bigger_than_mids[j])
				for j in range(len(smaller_than_mids)):
					for k in range(len(target_attribute.categories)):
						if smaller_than_mids[j][target_attribute.name] == target_attribute.categories[k]:
							smaller_than_mids_categories[k].append(smaller_than_mids[j])
							all_categories[k].append(smaller_than_mids[j])
				# Find the biggest category in the bigger and smaller than middle group to consider
				# it as right grouping
				var bigger_than_mids_biggest_value = -1
				var bigger_than_mids_biggest_category = ""
				var bigger_than_mids_biggest_category_id = -1
				for j in range(len(bigger_than_mids_categories)):
					if len(bigger_than_mids_categories[j]) > bigger_than_mids_biggest_value:
						bigger_than_mids_biggest_value = len(bigger_than_mids_categories[j])
						bigger_than_mids_biggest_category = target_attribute.categories[j]
						bigger_than_mids_biggest_category_id = j
				var smaller_than_mids_biggest_value = -1
				var smaller_than_mids_biggest_category = ""
				var smaller_than_mids_biggest_category_id = -1
				for j in range(len(smaller_than_mids_categories)):
					if len(smaller_than_mids_categories[j]) > smaller_than_mids_biggest_value:
						smaller_than_mids_biggest_value = len(smaller_than_mids_categories[j])
						smaller_than_mids_biggest_category = target_attribute.categories[j]
						smaller_than_mids_biggest_category_id = j
				# Create the decisions and put the data inside them
				var right_decision = NodeTree.new(bigger_than_mids_biggest_category, 0)
				var left_decision = NodeTree.new(smaller_than_mids_biggest_category, 0)
				var right_decision_label = attribute.name+">="+str(input[attribute.name])
				var left_decision_label = attribute.name+"<"+str(input[attribute.name])
				right_decision.parent = tree
				left_decision.parent = tree
				tree.data = _inputs
				tree.correct_categorizing_groups[right_decision_label] = bigger_than_mids_categories[bigger_than_mids_biggest_category_id]
				tree.correct_categorizing_groups[left_decision_label] = smaller_than_mids_categories[smaller_than_mids_biggest_category_id]
				tree.all_data_in_categories_for_decisions[right_decision_label] = bigger_than_mids_categories
				tree.all_data_in_categories_for_decisions[left_decision_label] = smaller_than_mids_categories
				tree.all_data_in_categories = all_categories
				tree.categories_attribute_name = target_attribute.name
				right_decision.categories_attribute_name = target_attribute.name
				left_decision.categories_attribute_name = target_attribute.name
				tree.categories = target_attribute.categories
				right_decision.categories = target_attribute.categories
				left_decision.categories = target_attribute.categories
				right_decision.data = bigger_than_mids
				left_decision.data = smaller_than_mids
				left_decision.calculate_all_data_in_categories()
				right_decision.calculate_all_data_in_categories()
				tree.add_decision(attribute.name+">="+str(input[attribute.name]), right_decision)
				tree.add_decision(attribute.name+"<"+str(input[attribute.name]), left_decision)
				trees.append(tree)
			for tree in trees:
				tree.calculate_uncertainty()
				tree.calculate_uncertainty_based_on_correct_attribute()
				tree.calculate_gain()
				tree.calculate_split()
				tree.calculate_gain_ratio()
	return choose_tree_between_all_trees(trees, gain_ratio)
