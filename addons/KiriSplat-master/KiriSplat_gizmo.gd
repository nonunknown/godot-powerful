# ----------------------------------------------------------------------
# KiriSplat
# Copyright 2020 Kiri Jolly
# ----------------------------------------------------------------------

# Editor gizmo implementation.

extends EditorSpatialGizmoPlugin

var handles

func _ready():
	pass

func _init():
	create_material("main", Color(0.5, 0.5, 1.0))
	create_handle_material("handles")

func get_name():
	return "KiriSplatInstance"

func has_gizmo(spatial):
	return spatial is KiriSplatInstance

func redraw(gizmo):
	gizmo.clear()

	var node = gizmo.get_spatial_node()

	# Manually create a bounding box display.

	var lines = PoolVector3Array()

	var left   = -node.width / 2.0
	var right  = node.width / 2.0
	var bottom = -node.height / 2.0
	var top    = node.height / 2.0
	var front  = -node.depth / 2.0
	var back   = node.depth / 2.0

	# Top
	lines.push_back(Vector3(left, top, back))
	lines.push_back(Vector3(left, top, front))

	lines.push_back(Vector3(right, top, back))
	lines.push_back(Vector3(right, top, front))

	lines.push_back(Vector3(left, top, back))
	lines.push_back(Vector3(right, top, back))

	lines.push_back(Vector3(left, top, front))
	lines.push_back(Vector3(right, top, front))

	# Bottom
	lines.push_back(Vector3(left, bottom, back))
	lines.push_back(Vector3(left, bottom, front))

	lines.push_back(Vector3(right, bottom, back))
	lines.push_back(Vector3(right, bottom, front))

	lines.push_back(Vector3(left, bottom, back))
	lines.push_back(Vector3(right, bottom, back))

	lines.push_back(Vector3(left, bottom, front))
	lines.push_back(Vector3(right, bottom, front))

	# Vertical lines
	lines.push_back(Vector3(left, top, back))
	lines.push_back(Vector3(left, bottom, back))

	lines.push_back(Vector3(right, top, back))
	lines.push_back(Vector3(right, bottom, back))

	lines.push_back(Vector3(left, top, front))
	lines.push_back(Vector3(left, bottom, front))

	lines.push_back(Vector3(right, top, front))
	lines.push_back(Vector3(right, bottom, front))

	gizmo.add_lines(lines, get_material("main", gizmo), false)

	# Create handles. Order matters here (assumed order in set_handle()).
	handles = PoolVector3Array()
	handles.push_back(Vector3(left, 0.0, 0.0))
	handles.push_back(Vector3(right, 0.0, 0.0))
	handles.push_back(Vector3(0.0, top, 0.0))
	handles.push_back(Vector3(0.0, bottom, 0.0))
	handles.push_back(Vector3(0.0, 0.0, front))
	handles.push_back(Vector3(0.0, 0.0, back))

	gizmo.add_handles(handles, get_material("handles", gizmo), false)

func set_handle(gizmo, index, camera, new_screenspace_point):

	# Get the original view space position just so we have a depth value to work
	# with.
	var original_world_pos = \
		gizmo.get_spatial_node().get_global_transform() * handles[index]
	var original_viewspace_pos = \
		camera.get_camera_transform().affine_inverse() * original_world_pos

	# Project the screen point out to the depth we got from the view space
	# position, and convert it back into object space.
	var new_world_pos = camera.project_position(
		new_screenspace_point,
		-original_viewspace_pos.z)
	var new_objectspace_pos = \
		gizmo.get_spatial_node().get_global_transform().affine_inverse() * \
		new_world_pos

	# Set the width/height/depth based on the new value just for the
	# corresponding axis in the reprojected position.
	if index == 0 || index == 1:
		gizmo.get_spatial_node().set_width(abs(new_objectspace_pos.x) * 2.0)
	if index == 2 || index == 3:
		gizmo.get_spatial_node().set_height(abs(new_objectspace_pos.y) * 2.0)
	if index == 4 || index == 5:
		gizmo.get_spatial_node().set_depth(abs(new_objectspace_pos.z) * 2.0)
