extends Node

class_name NodeTree

var label: String = ""
var layer: int = 0
var decisions: Dictionary = {}
var branch: Branch = null
var parent: NodeTree = null

# All inputs in one place
var data: Array = []
# Inputs Divided into different categories with each decision
# {"decision1": [data categorized in first decision], "decision2": [data categorized in second decision], ...}
var all_data_in_categories_for_decisions: Dictionary = {}
# Inputs of the correct category
# {"decision1": [right categorized data in first decision], "decision2": [right categorized data in second decision], ...}
var correct_categorizing_groups: Dictionary = {}
# Inputs Divided into different categories
var all_data_in_categories: Array = []
# Categories of the target attribute are in here
var categories: Array = []
var categories_attribute_name: String = ""

var uncertainty: float = 0
var uncertainty_based_on_correct_attribute: float = 0
var split: float = 0
var gain: float = 0
var gain_ratio: float = 0

# 1
func calculate_uncertainty() -> void:
	var sum: float = 0
	var N: float = len(data)
	for data_in_category in all_data_in_categories:
		var n: float = len(data_in_category)
		if n == 0:
			continue
		sum += (n/N)*(log(N/n)/log(2))
	self.uncertainty = sum

# 2
func calculate_uncertainty_based_on_correct_attribute() -> void:
	var sum: float = 0
	var N: float = len(data)
	for key in decisions:
		var n: float = len(decisions[key].data)
		if n == 0:
			continue
		var sum2: float = 0
		for i in range(len(all_data_in_categories_for_decisions[key])):
			var n2: float = len(all_data_in_categories_for_decisions[key][i])
			if n2 == 0:
				continue
			sum2 += (n2/n)*(log(n/n2)/log(2))
		sum = (n/N) * sum2
	self.uncertainty_based_on_correct_attribute = sum

# 3
func calculate_gain() -> void:
	self.gain = self.uncertainty - self.uncertainty_based_on_correct_attribute

# 4
func calculate_split() -> void:
	var sum: float = 0
	var N: float = len(data)
	for key in decisions:
		var n: float = len(decisions[key].data)
		if n == 0:
			continue
		sum += (n/N)*(log(N/n)/log(2))
	self.split = sum

# 5
func calculate_gain_ratio() -> void:
	self.gain_ratio = self.gain / self.split if self.gain > 0 and self.split > 0 else 0

# Adds a decision based on the attribute
func add_decision(decision_label: String, decision: NodeTree) -> NodeTree:
	decisions[decision_label] = decision
	decision.parent = self
	return self

func calculate_all_data_in_categories() -> void:
	all_data_in_categories = []
	for whatever in categories:
		all_data_in_categories.append([])
	for j in range(len(data)):
		for k in range(len(categories)):
			if data[j][categories_attribute_name] == categories[k]:
				all_data_in_categories[k].append(data[j])

func _init(label: String, layer: int):
	self.label = label
	self.layer = layer
