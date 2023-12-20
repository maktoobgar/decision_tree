@tool
extends Line2D

class_name Line

@export var starting_point: Vector2 = Vector2.ZERO: set = _set_starting_point
@export var destination_point: Vector2 = Vector2.ZERO: get = _get_destination_point, set = _set_destination_point
@export var text: String = "Test": get = _get_text, set = _set_text

func _get_destination_point() -> Vector2:
	return destination_point

func _set_destination_point(value: Vector2) -> void:
	value = to_local(value)
	destination_point = value
	self.points[1] = value
	if !self.is_node_ready():
		await self.ready
	var p = (destination_point - starting_point) / 2
	%LabelContainer.position = p
	%LabelContainer.rotation = _calculate_angle()

func _set_starting_point(value: Vector2) -> void:
	value = to_local(value)
	starting_point = value
	self.points[0] = value
	if !self.is_node_ready():
		await self.ready
	var p = (destination_point - starting_point) / 2
	%LabelContainer.position = p + starting_point
	%LabelContainer.rotation = _calculate_angle()

# Returns the angle in radian
func _calculate_angle() -> float:
	var width: float = starting_point.x - destination_point.x
	var height: float = starting_point.y - destination_point.y
	var arctan = atan(height/width)

	return arctan if !is_nan(arctan) else 0

func _get_text() -> String:
	return text

func _set_text(value: String) -> void:
	%Label.text = value
	text = value
