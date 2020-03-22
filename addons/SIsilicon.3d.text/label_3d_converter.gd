tool
extends Button

signal mesh_generated(mesh_inst)

const Label3D = preload("label_3d.gd")

var label3d : Label3D

var image_cache = PoolRealArray()

# These variables are used to spread the marching_square function
# across multiple frames.
var finished_marching = false
var os_time

func _on_Button_pressed():
	generate_geometry()

func generate_geometry():
	$PopupDialog.popup_centered()
	var text_scale = label3d.text_scale
	var extrude = label3d.extrude
	var viewport = label3d.get_node("Viewport")
	
	viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
	
	var image = viewport.get_texture().get_data()
	image.lock()
	
	var edges = Dictionary()
	finished_marching = false
	os_time = OS.get_ticks_msec()
	do_marching_squares(image, edges)
	while not finished_marching:
		yield(get_tree(), "idle_frame")
	
	# Contours are the edges and holes of the text.
	# The paths are said edges combined with the holes for easier triangulation.
	var contours = []
	collect_contours(edges.duplicate(), contours)
	var paths = contours.duplicate(true)
	decimate_holes(edges, paths, Rect2(0, 0, image.get_width(), image.get_height()))
	
	var triangle_data = []
	var vertex_data = []
	for path in paths:
		path.points = douglas_peucker(path.points, 0.125)
		# Edge data beyond this point will no longer be valid
		
		var triangles = []
		ear_clipping(path, triangles)
		
		# points are converted into vector3 here.
		for p in path.points.size():
			var point = path.points[p]
			point -= Vector2(image.get_width(), image.get_height()) / 2.0
			point *= text_scale * 2.0
			path.points[p] = Vector3(point.x, point.y, extrude)
		
		ArrayUtils.call_per_element(triangles, "offset_indices", vertex_data.size())
		
		ArrayUtils.append_array(vertex_data, path.points)
		ArrayUtils.append_array(triangle_data, triangles)
	
	if extrude != 0:
		# Generate the back triangles
		var original_vert_size = vertex_data.size()
		for v in original_vert_size:
			var vertex = vertex_data[v]
			vertex_data.append(vertex * Vector3(1, 1, -1))
		
		var tri_size = triangle_data.size()
		for t in tri_size:
			var triangle = triangle_data[t].duplicate()
			triangle.offset_indices(original_vert_size)
			triangle.reverse_order()
			triangle_data.append(triangle)
		
		# And now the triangles inbetween
		for path in paths:
			var vertices = path.points.duplicate()
			var points_size = path.points.size()
			for vert in points_size:
				var back_vertex = path.points[vert] * Vector3(1, 1, -1)
				vertices.append(back_vertex)
			
			var triangles = []
			for i in points_size:
				var index = i + vertex_data.size()
				var a = index
				var b = (index + 1) if i != points_size - 1 else vertex_data.size()
				var c = index + points_size
				var d = ((index + 1) if i != points_size - 1 else vertex_data.size()) + points_size
				
				triangles.append(Triangle.new(c, b, a))
				triangles.append(Triangle.new(d, b, c))
			
			ArrayUtils.append_array(vertex_data, vertices)
			ArrayUtils.append_array(triangle_data, triangles)
	
	var geom = SurfaceTool.new()
	geom.clear()
	
	geom.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vert in vertex_data:
		geom.add_vertex(vert)
	for tri in triangle_data:
		geom.add_index(tri.a)
		geom.add_index(tri.b)
		geom.add_index(tri.c)
	geom.generate_normals()
	
	var material = SpatialMaterial.new()
	material.albedo_color = label3d.color
	material.metallic = label3d.metallic
	material.roughness = label3d.roughness
	
	var mesh_inst = MeshInstance.new()
	mesh_inst.mesh = geom.commit()
	mesh_inst.material_override = material
	mesh_inst.transform = label3d.transform
	mesh_inst.name = label3d.name + "-mesh"
	
	emit_signal("mesh_generated", mesh_inst)
	
	image_cache.resize(0)
	image.unlock()
	$PopupDialog.hide()


func do_marching_squares(image, edges):
	for y in image.get_height() - 1:
		for x in image.get_width() - 1:
			var i = Vector2(x, y)
			
			var p_ul = get_pixel(image, x, y)
			var p_ll = get_pixel(image, x, y+1)
			var p_ur = get_pixel(image, x+1, y)
			var p_lr = get_pixel(image, x+1, y+1)
			
			var top = inverse_lerp(p_ul, p_ur, 1)
			var bottom = inverse_lerp(p_ll, p_lr, 1)
			var left = inverse_lerp(p_ul, p_ll, 1)
			var right = inverse_lerp(p_ur, p_lr, 1)
			
			var ul = int(p_ul > 1) * 1
			var ll = int(p_ll > 1) * 2
			var ur = int(p_ur > 1) * 4
			var lr = int(p_lr > 1) * 8
			
			var bit = ul | ll | ur | lr
			
			# Notice: cases 6 and 9 have not been implemented.
			match bit:
				# Corner Cases
				1:
					create_edge(edges, i, x, y + left, x + top, y, Vector2.UP)
				2:
					create_edge(edges, i, x + bottom, y + 1, x, y + left, Vector2.LEFT)
				4:
					create_edge(edges, i, x + top, y, x + 1, y + right, Vector2.RIGHT)
				8:
					create_edge(edges, i, x + 1, y + right, x + bottom, y + 1, Vector2.DOWN)
				
				# Edge Cases
				3:
					create_edge(edges, i, x + bottom, y + 1, x + top, y, Vector2.UP)
				5:
					create_edge(edges, i, x, y + left, x + 1, y + right, Vector2.RIGHT)
				10:
					create_edge(edges, i, x + 1, y + right, x, y + left, Vector2.LEFT)
				12:
					create_edge(edges, i, x + top, y, x + bottom, y + 1, Vector2.DOWN)
				
				# Inner Corner cases
				14:
					create_edge(edges, i, x + top, y, x, y + left, Vector2.LEFT)
				13:
					create_edge(edges, i, x, y + left, x + bottom, y + 1, Vector2.DOWN)
				11:
					create_edge(edges, i, x + 1, y + right, x + top, y, Vector2.UP)
				7:
					create_edge(edges, i, x + bottom, y + 1, x + 1, y + right, Vector2.RIGHT)
			
			if OS.get_ticks_msec() - os_time > 20:
				var max_i = (image.get_width() - 1) * (image.get_height() - 1)
				var curr_i = x + (y * image.get_width() - 1)
				$PopupDialog/VBoxContainer/ProgressBar.value = float(curr_i) / max_i * 100
				
				yield(get_tree(), "idle_frame")
				os_time = OS.get_ticks_msec()
	
	finished_marching = true

func collect_contours(edges, contours):
	
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var coord = edges.keys()[0]
	
	var start_edge = edges[coord]
	var contour = Contour.new(start_edge.direction == Vector2.UP || \
			start_edge.direction == Vector2.RIGHT)
	contours.append(contour)
	
	contour.points.append(edges[coord].end)
	contour.edges.append(edges[coord])
	var edge = edges[coord]
	
	edges.erase(coord)
	
	var loop_started = true
	while loop_started or edge != start_edge:
		var edge_found = false
		
		for dir in directions:
			if edges.has(coord + dir) and edges[coord + dir].begin == edge.end:
				edge_found = true
				
				coord += dir
				contour.points.append(edges[coord].end)
				contour.edges.append(edges[coord])
				edge = edges[coord]
				edges.erase(coord)
				
				break
		
		if not edge_found:
			break
		
		loop_started = false
	
	if not edges.empty():
		collect_contours(edges, contours)

func decimate_holes(edges, contours, bounds):
	for c in range(contours.size()-1, -1, -1):
		var contour = contours[c]
		if contour.is_hole:
			for i in contour.edges.size():
				var edge = contour.edges[i]
				var edge_found = false
				
				var dir = edge.direction
				dir = Vector2(dir.y, -dir.x)
				var pos = ((edge.begin + edge.end) / 2.0).floor()
				var other_edge
				
				while not other_edge and bounds.has_point(pos):
					pos += dir
					if edges.has(pos):
						other_edge = edges[pos]
				
				if other_edge:
					
					for other_contour in contours:
						if other_contour == contour:
							continue
						
						for j in other_contour.edges.size():
							var other_point = other_contour.edges[j]
							if other_edge == other_point:
								edge_found = true
								other_contour.fuse_with(contour, j, i + 1)
								break
						
						if edge_found:
							break
					
				if edge_found:
					break
			
			contours.remove(c)

func douglas_peucker(points, tolerance):
	var farthest = farthest_point(points)
	
	
	# Farthest point not existing must mean the points only made of two,
	# and cannot be simplified any further.
	if not farthest:
		return points
	
	if farthest.distance < tolerance:
		return [points[0], points[-1]]
	else:
		var left = []
		var right = []
		ArrayUtils.split_array(points, farthest.index, left, right)
		
		left = douglas_peucker(left, tolerance)
		right = douglas_peucker(right, tolerance)
		
		ArrayUtils.append_array(left, right)
		return left

func ear_clipping(contour, triangles):
	var points = ArrayUtils.to_dictionary(contour.points)
	
	var i = 0
	var counter = 0
	while points.size() > 3:
		counter += 1
		if(counter > 4000):
			printerr("Hmmm... Infinite loop much?")
			break
		
		var keys = points.keys()
		var point_a = points[keys[i-1]]
		var point_b = points[keys[i]]
		var point_c = points[keys[(i+1) % keys.size()]]
		
		if (point_b - point_a).cross(point_c - point_b) < 0:
			var has_point = false
			for p in points:
				var point = points[p]
				if point == point_a or point == point_b or point == point_c:
					continue
				if point_inside_triangle(point, point_a, point_b, point_c):
					has_point = true
					break
			
			if not has_point:
				var tri = Triangle.new(keys[i-1], keys[i], keys[(i+1) % keys.size()])
				triangles.append(tri)
				points.erase(keys[i])
		
		i = wrapi(i + 1, 0, points.size())
	
	var keys = points.keys()
	triangles.append(Triangle.new(keys[0], keys[1], keys[2]))

# This returns a dictionary containing the farthest point,
# the distance associated with it, and its index in the array.
func farthest_point(points):
	var first = points[0]
	var last = points[-1]
	
	if points.size() < 3:
		return
	
	var farthest
	var max_dist = -1
	var index
	for i in range(1, points.size() - 1):
		var distance = distance_to_segment(points[i], first, last)
		if distance > max_dist:
			farthest = points[i]
			max_dist = distance
			index = i
	
	return {"point": farthest, "distance": max_dist, "index": index}

func distance_to_segment(point, a, b):
	# This is because I don't know how to snap a point onto a line,
	# so I'm relying on Plane in the meantime.
	var plane = Plane(Vector3(a.x, a.y, 0),
			Vector3(b.x, b.y, 0), Vector3(a.x, a.y, 1))
	
	var projected = plane.project(Vector3(point.x, point.y, 0))
	var t = inverse_lerp(a.x, b.x, projected.x) if a.x != b.x else \
			inverse_lerp(a.y, b.y, projected.y)
	
	var snapped = a.linear_interpolate(b, t)
	return point.distance_squared_to(snapped)

func vec_sign(p1, p2, p3):
	return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)

func point_inside_triangle(point, a, b, c):
	var d1 = vec_sign(point, a, b)
	var d2 = vec_sign(point, b, c)
	var d3 = vec_sign(point, c, a)
	
	var has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
	var has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
	return not (has_neg and has_pos)

func create_edge(edges, offset, p1x, p1y, p2x, p2y, dir):
	edges[offset] = MSEdge.new(Vector2(p1x, p1y), Vector2(p2x, p2y), dir)

func get_pixel(image : Image, x : int, y : int):
	if x < 1 || y < 1 || x > image.get_width()-1 || y > image.get_height()-1:
		return 0
	
	var i = x + y * image.get_width()
	if image_cache.size() > i and image_cache[i] != null:
		return image_cache[i]
	else:
		var real = image.get_pixel(x, y).r;
		if image_cache.size() <= i:
			image_cache.resize(i+1)
		image_cache[i] = real
		return real


class MSEdge:
	var begin : Vector2
	var end : Vector2
	
	var coordinate : Vector2
	
	# One of the four cardinal directions
	var direction : Vector2
	
	func _init(begin, end, direction):
		self.begin = begin
		self.end = end
		self.direction = direction


class Contour:
	var points := []
	var edges := []
	var is_hole : bool
	
	func _init(is_hole):
		self.is_hole = is_hole
	
	func fuse_with(contour, self_point, other_point):
		var points_behind = []
		var points_after = []
		
		ArrayUtils.split_array(points, self_point + 1, points_behind, points_after)
		
		var shifted_contour = contour.points.duplicate()
		ArrayUtils.shift_array(shifted_contour, other_point)
		
		ArrayUtils.append_array(points_behind, shifted_contour)
		points_behind.append(shifted_contour[0])
		points_behind.append(points[self_point])
		ArrayUtils.append_array(points_behind, points_after)
		
		points = points_behind


class Triangle:
	var a : int
	var b : int
	var c : int
	
	func _init(a, b, c):
		self.a = a
		self.b = b
		self.c = c
	
	func offset_indices(offset):
		a += offset
		b += offset
		c += offset
	
	func reverse_order():
		var temp = a
		a = b
		b = temp
	
	func duplicate():
		return Triangle.new(a, b, c)
