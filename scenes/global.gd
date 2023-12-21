@tool
extends Node2D

const ints_to_strs = {
	0: "",
	1: "First",
	2: "Second",
	3: "Third",
	4: "Fourth",
	5: "Fifth",
	6: "Sixth",
	7: "Seventh",
	8: "Eighth",
	9: "Ninth",
	10: "Tenth",
	11: "Eleventh",
	12: "Twelfth",
	13: "Thirteenth",
	14: "Fourteenth",
	15: "Fifteenth",
	16: "Sixteenth",
	17: "Seventeenth",
	18: "Eighteenth",
	19: "Nineteenth",
	20: "Twenty",
	30: "Thirthy",
	40: "Forty",
	50: "Fifty",
	60: "Sixty",
	70: "Seventy",
	80: "Eighty",
	90: "Ninety"
}

var line: Line = null
var out_branch: Branch = null
var in_branch: Branch = null

var ui: Node = null

func _input(event):
	if line and out_branch and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if in_branch:
			in_branch.connect_out_to_in_branch(out_branch, line)
			out_branch.connect_in_to_out_branch(in_branch, line)
		else:
			out_branch.delete_line(line)
		line = null
		out_branch = null
		in_branch = null
	if line and out_branch and event is InputEventMouseMotion:
		line.destination_point = get_global_mouse_position()
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_released() and ui:
		if not Engine.is_editor_hint():
			ui.visible = !ui.visible

func number_to_string(num: int) -> String:
	if num > 99:
		return "Invalid Number"
	if num > 20:
		return ints_to_strs.get((num/10)*10, "Invalid Number") + " " + ints_to_strs.get(num%10, "Invalid Number")
	return ints_to_strs.get(num, "Invalid Number")

func get_attribute_name(num: int) -> String:
	return number_to_string(num) + " Attribute"
