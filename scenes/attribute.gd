extends Object

class_name Attribute

var name: String = ""
var type: String = ""
var output: bool = false
var categories: Array = []
var index: int = -1

func _init(name: String, type: String, output: bool, categories: Array, index: int) -> void:
	self.name = name
	self.type = type
	self.output = output
	self.categories = categories
	self.index = index
