extends Node

class_name NodeTree

var label: String = ""
var layer: int = 0
var decisions: Dictionary = {}
var branch: Branch = null
var parent: NodeTree = null

func add_decision(decision_label: String, decision: NodeTree) -> NodeTree:
	decisions[decision_label] = decision
	decision.parent = self
	return self

func _init(label: String, layer: int):
	self.label = label
	self.layer = layer
