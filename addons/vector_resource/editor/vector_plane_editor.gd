tool extends Control

var edited_vector: VectorResource

enum VectorPlane {
	XY,
	XZ,
	YZ
}
var plane = VectorPlane.XY
var vector_width = 0.1
var vector = Vector3()
var view_vector = Vector3()

var _origin_transform = Transform2D()
var _mouse_pos = Vector2()
var _dragging = false


func get_plane_grid_step():
	return Vector2(edited_vector.grid_step, edited_vector.grid_step)


func get_plane_vector():
	var vec = Vector2()
	match plane:
		VectorPlane.XY:
			vec = Vector2(vector.x, vector.y)
		VectorPlane.XZ:
			vec = Vector2(vector.x, vector.z)
		VectorPlane.YZ:
			vec = Vector2(vector.z, vector.y) # reverse so that Y matches XY
	return vec


func set_view_vector_components(u, v):
	match plane:
		VectorPlane.XY:
			view_vector.x = u
			view_vector.y = v
		VectorPlane.XZ:
			view_vector.x = u
			view_vector.z = v
		VectorPlane.YZ:
			view_vector.y = u
			view_vector.z = v


func set_plane_vector_components(u, v):
	match plane:
		VectorPlane.XY:
			vector.x = u
			vector.y = v
		VectorPlane.XZ:
			vector.x = u
			vector.z = v
		VectorPlane.YZ:
			vector.y = v
			vector.z = u


func get_w_color():
	var wc: Color
	match plane:
		VectorPlane.XY:
			wc = get_color("axis_z_color", "Editor")
		VectorPlane.XZ:
			wc = get_color("axis_y_color", "Editor")
		VectorPlane.YZ:
			wc = get_color("axis_x_color", "Editor")
	return wc


func get_w_offset(): # z but per plane
	var ofs = 0.0
	match plane:
		VectorPlane.XY:
			ofs = -vector.z / edited_vector.max_length
		VectorPlane.XZ:
			ofs = vector.y / edited_vector.max_length
		VectorPlane.YZ:
			ofs = vector.x / edited_vector.max_length
	ofs = max(0, 1.0 - ofs)
	return ofs


func set_w_component(w): # z but per plane
	match plane:
		VectorPlane.XY:
			vector.z = w
		VectorPlane.XZ:
			vector.y = w
		VectorPlane.YZ:
			vector.x = w


func get_vector_origin():
	return rect_size / 2.0


func get_w_component(): # z but per plane
	match plane:
		VectorPlane.XY:
			return vector.z
		VectorPlane.XZ:
			return vector.y
		VectorPlane.YZ:
			return vector.x


func get_view_coordinates(p_world_pos):
	var center = get_vector_origin()
	_origin_transform.origin = center

	var coord = _origin_transform.xform_inv(p_world_pos)
	coord = (coord / rect_size * 2.0).clamped(1.0)

	return coord


func get_vector_coordinates(p_view_pos):
	var coord = (p_view_pos * edited_vector.max_length).clamped(edited_vector.max_length)
	return coord


func draw_plane_axes(p_center: Vector2):
	var xc = get_color("axis_x_color", "Editor")
	var yc = get_color("axis_y_color", "Editor")
	var zc = get_color("axis_z_color", "Editor")

	var uc: Color
	var vc: Color

	match plane:
		VectorPlane.XY:
			uc = xc
			vc = yc
		VectorPlane.XZ:
			uc = xc
			vc = zc
		VectorPlane.YZ:
			uc = zc
			vc = yc

	draw_line(Vector2(rect_size.x / 2.0, 0.0), Vector2(rect_size.x / 2.0, rect_size.y), vc)
	draw_line(Vector2(0.0, rect_size.y / 2.0), Vector2(rect_size.x, rect_size.y / 2.0), uc)
	draw_circle(p_center, 3, get_w_color()) # z-depth hint


func _draw():
	if not is_instance_valid(edited_vector):
		return

	var center = get_vector_origin()
	_origin_transform.origin = center

	# Draw grid
	var gs = get_plane_grid_step() * (get_vector_origin() / edited_vector.max_length)

	if edited_vector.snapped and gs.x > 0.0 and gs.y > 0.0:
		var gc = (get_vector_origin() / gs).ceil()
		var ofs = (gc * gs) - get_vector_origin()
		var pos = gs - ofs

		var grid_color = get_color("mono_color", "Editor") * Color(1, 1, 1, 0.07)

		while pos.x < rect_size.x:
			draw_line(Vector2(pos.x, rect_size.y), Vector2(pos.x, 0), grid_color)
			pos.x += gs.x
		while pos.y < rect_size.y:
			draw_line(Vector2(0, pos.y), Vector2(rect_size.x, pos.y), grid_color)
			pos.y += gs.y

	if edited_vector.normalized:
		var c = Color.white
		c.a = 0.02
		draw_circle(center, min(rect_size.x, rect_size.y) / 2.0, c)

	# Draw axes
	draw_plane_axes(center)

	if vector == Vector3():
		return

	# Draw vector
	draw_set_transform(center, 0.0, Vector2.ONE)

	var vec = (get_plane_vector() / edited_vector.max_length) * get_vector_origin()

	if edited_vector.snapped:
		vec = vec.snapped(gs)

	if _dragging:
		var c = Color.white
		c.a = 0.07
		draw_circle(vec, gs.length() / 4, c)

	if edited_vector.normalized:
		var c = Color.white
		c.a = 0.2
		draw_circle(vec, gs.length() / 8, c)
		vec = vec.normalized() * get_vector_origin()

	var w_ofs = get_w_offset()
	var end_color = Color.white
	end_color.a = w_ofs

	var ARROW_HEIGHT_MAX = 10.0
	var arrow_height = ARROW_HEIGHT_MAX * w_ofs
	var arrow_tip_offset = arrow_height / 2.0
	var arrow_points = [
		Vector2(),
		Vector2(-arrow_height, arrow_tip_offset),
		Vector2(-arrow_height, -arrow_tip_offset)
	]

	var body = []
	var arrow_vec = vec.move_toward(Vector2(), arrow_height)
	body.push_back(Vector2(0, vector_width))
	body.push_back(Vector2(0, -vector_width))
	body.push_back(Vector2(arrow_vec.length(), -vector_width * w_ofs))
	body.push_back(Vector2(arrow_vec.length(), vector_width * w_ofs))

	draw_set_transform(center, vec.angle(), Vector2.ONE)
	draw_polygon(body, PoolColorArray([Color.white, Color.white, end_color, end_color]), PoolVector2Array([]), null, null, true)
	draw_set_transform(center + vec, vec.angle(), Vector2.ONE)
	draw_polygon(arrow_points, PoolColorArray([end_color, end_color, end_color]), PoolVector2Array([]), null, null, true)


func _process(delta):
	if not is_instance_valid(edited_vector):
		return

	vector = edited_vector.value

	if _dragging:
		var coord = get_view_coordinates(_mouse_pos)
		set_view_vector_components(coord.x, coord.y)
		var uv = get_vector_coordinates(coord)
		set_plane_vector_components(uv.x, uv.y)
		edited_vector.value = vector

	update()


func _gui_input(event):
	if event is InputEventMouseMotion:
		_mouse_pos = event.position
	elif event is InputEventMouseButton:
		_dragging = event.pressed
