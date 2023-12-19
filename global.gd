@tool
extends Node2D

var line: Line = null
var out_branch: Branch = null
var in_branch: Branch = null

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
