# ----------------------------------------------------------------------
# KiriSplat
# Copyright 2020 Kiri Jolly
# ----------------------------------------------------------------------

# Main splat instance implementation.

tool
extends Spatial
class_name KiriSplatInstance

var splattableTriangleVerts   = PoolVector3Array()
var splattableTriangleNormals = PoolVector3Array()
var splattableTriangleUVs     = PoolVector2Array()

var splatChildren = []
var lastTransform = Transform()

export(float) var width = 2.0 setget set_width
export(float) var height = 2.0 setget set_height
export(float) var depth = 2.0 setget set_depth

export(Material) var material = \
	preload("KiriSplat_defaultMaterial.tres") setget set_material

# ----------------------------------------------------------------------
# Getters/Setters

func set_material(newMaterial):
	material = newMaterial
	call_deferred("rescan_all_nodes")

func set_width(newWidth):
	width = newWidth
	call_deferred("rescan_all_nodes")
	update_gizmo()

func set_height(newHeight):
	height = newHeight
	call_deferred("rescan_all_nodes")
	update_gizmo()

func set_depth(newDepth):
	depth = newDepth
	call_deferred("rescan_all_nodes")
	update_gizmo()

# ----------------------------------------------------------------------
# Triangle collision test functions

func _test_triangle_project_box(dir):

	var center_x = 0.0
	var center_y = 0.0
	var center_z = 0.0
	
	var extent_x = width / 2.0
	var extent_y = height / 2.0
	var extent_z = depth / 2.0

	var c = (dir.x * center_x) + (dir.y * center_y) + (dir.z * center_z)
	var e = abs(dir.x * extent_x) + abs(dir.y * extent_y) + abs(dir.z * extent_z);

	# Return min, max.
	return [c - e, c + e] 
	
func _test_triangle_project_triangle(dir,  tri):
	var ret_min = dir.dot(tri[0])
	var ret_max = ret_min
	
	var p = dir.dot(tri[1])
	
	if p < ret_min:
		ret_min = p
	
	if p > ret_max:
		ret_max = p

	p = dir.dot(tri[2])
	
	if p < ret_min:
		ret_min = p

	if p > ret_max:
		ret_max = p

	return [ret_min, ret_max]

func _test_triangle(tri):

	# Get the triangle normal.
	var triangle_plane_normal = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
	var triangle_plane_distance = triangle_plane_normal.dot(tri[0])
	
	var dir
	var triangle_range = [-triangle_plane_distance, -triangle_plane_distance]
	var box_range

	# Project the box onto the axis defined by the triangle normal.
	box_range = _test_triangle_project_box(triangle_plane_normal)
	if triangle_range[1] < box_range[0] or box_range[1] < triangle_range[0]:
		return false
	
	# Project the triangle onto the axes defined by the box sides.
	triangle_range = _test_triangle_project_triangle(Vector3(1.0, 0.0, 0.0), tri)
	if triangle_range[1] < -width / 2.0 or width / 2.0 < triangle_range[0]:
		return false
	
	triangle_range = _test_triangle_project_triangle(Vector3(0.0, 1.0, 0.0), tri)
	if triangle_range[1] < -height / 2.0 or height / 2.0 < triangle_range[0]:
		return false

	triangle_range = _test_triangle_project_triangle(Vector3(0.0, 0.0, 1.0), tri)
	if triangle_range[1] < -depth / 2.0 or depth / 2.0 < triangle_range[0]:
		return false
		
	# Project both the triangle and the box onto an axis defined by the cross
	# product of the edges on the triangle with the normals of the box faces.
	var i = 0
	var j = 2
	while i < 3:

		var edge = tri[i] - tri[j]
		
		var k = 0
		while k < 3:

			dir = edge.cross(
				Vector3(
					1.0 if k == 0 else 0.0,
					1.0 if k == 1 else 0.0,
					1.0 if k == 2 else 0.0))

			box_range = _test_triangle_project_box(dir)
			triangle_range = _test_triangle_project_triangle(dir, tri)
			
			if triangle_range[1] < box_range[0] or box_range[1] < triangle_range[0]:
				return false

			k = k + 1

		j = i
		i = i + 1

	# No separating axis found. Guess we're done here.
	return true

# ----------------------------------------------------------------------
# Geometry generation functions

func _scan_nodes(node):
	
	var my_transform_worldspace = get_global_transform()
	
	# Create a world space AABB to represent the area covered by the splat.
	var my_aabb_worldspace = my_transform_worldspace.xform(AABB(
		Vector3(-width/2.0, -height/2.0, -depth/2.0),
		Vector3(width, height, depth)))

	var mesh_transform_worldspace = Transform()
	var meshMesh = null

	# Handle CSGs.
	if node is CSGShape:
		if node.is_root_shape():
			node._update_shape() # Hack - We shouldn't call a private function.
			var transformAndMesh = node.get_meshes()
			if len(transformAndMesh) > 0:
				mesh_transform_worldspace = node.get_global_transform() * transformAndMesh[0]
				meshMesh = transformAndMesh[1]

	# Handle meshes.
	if node is MeshInstance:
		mesh_transform_worldspace = node.get_global_transform()
		meshMesh = node.mesh

	if meshMesh != null:

		# Get the mesh's AABB in world space.
		var mesh_aabb_worldspace = mesh_transform_worldspace.xform(meshMesh.get_aabb())

		if mesh_aabb_worldspace.intersects(my_aabb_worldspace):

			for surfaceIndex in range(0, meshMesh.get_surface_count()):

				# FIXME: Add support for fans, strips, and quads.
				if meshMesh is ArrayMesh:
					if meshMesh.surface_get_primitive_type(surfaceIndex) != Mesh.PRIMITIVE_TRIANGLES:
						continue

				var surfaceArrays = meshMesh.surface_get_arrays(surfaceIndex)

				# Create a matrix that'll go straight from the mesh's coordinate
				# space to our own coordinate space, so we can quickly shuffle
				# triangles into (local) position.
				var mesh_transform_to_my_transform_worldspace = \
					my_transform_worldspace.affine_inverse() * \
					mesh_transform_worldspace
				
				var meshTransformRotation = Transform(
					mesh_transform_to_my_transform_worldspace.basis,
					Vector3(0.0, 0.0, 0.0))

				# Vertex count is different for indexed vs non-indexed meshes.
				var vertCount = len(surfaceArrays[ArrayMesh.ARRAY_VERTEX])
				if surfaceArrays[ArrayMesh.ARRAY_INDEX]:
					vertCount = len(surfaceArrays[ArrayMesh.ARRAY_INDEX])

				var i = 0

				# Handle indexed arrays.
				while i < vertCount:

					var idx0
					var idx1
					var idx2

					# Vertex indices are different for indexed vs non-indexed
					# meshes.
					if surfaceArrays[ArrayMesh.ARRAY_INDEX]:
						idx0 = surfaceArrays[ArrayMesh.ARRAY_INDEX][i]
						idx1 = surfaceArrays[ArrayMesh.ARRAY_INDEX][i+1]
						idx2 = surfaceArrays[ArrayMesh.ARRAY_INDEX][i+2]
					else:
						idx0 = i
						idx1 = i + 1
						idx2 = i + 2

					var verts = PoolVector3Array([
						mesh_transform_to_my_transform_worldspace * surfaceArrays[ArrayMesh.ARRAY_VERTEX][idx0],
						mesh_transform_to_my_transform_worldspace * surfaceArrays[ArrayMesh.ARRAY_VERTEX][idx1],
						mesh_transform_to_my_transform_worldspace * surfaceArrays[ArrayMesh.ARRAY_VERTEX][idx2]])

					if _test_triangle(verts):

						var normals = PoolVector3Array([
							meshTransformRotation * surfaceArrays[ArrayMesh.ARRAY_NORMAL][idx0],
							meshTransformRotation * surfaceArrays[ArrayMesh.ARRAY_NORMAL][idx1],
							meshTransformRotation * surfaceArrays[ArrayMesh.ARRAY_NORMAL][idx2]])
							
						var UVs = PoolVector2Array([
							Vector2(verts[0].x / width + 0.5, verts[0].z / depth + 0.5),
							Vector2(verts[1].x / width + 0.5, verts[1].z / depth + 0.5),
							Vector2(verts[2].x / width + 0.5, verts[2].z / depth + 0.5)])

						splattableTriangleVerts = splattableTriangleVerts + verts
						splattableTriangleNormals = splattableTriangleNormals + normals
						splattableTriangleUVs = splattableTriangleUVs + UVs

					i = i + 3

	# Recurse into children.
	var childNodes = node.get_children()
	for child in childNodes:
		
		var childGroups = child.get_groups()
		
		# "not_splattable" nodes should be explicitly skipped.
		if "not_splattable" in childGroups:
			continue
		
		# "splattable" nodes should also be skipped, because they're already
		# handled at the root level.
		if "splattable" in childGroups:
			continue
		
		# Don't descend into other splats. We are definitely not interested in
		# their generated meshes.
		if child.get_class() == get_class():
			continue
		
		_scan_nodes(child)

func rescan_all_nodes():

	# Clear out existing triangle data.
	splattableTriangleVerts   = PoolVector3Array()
	splattableTriangleNormals = PoolVector3Array()
	splattableTriangleUVs     = PoolVector2Array()

	# Scan all the existing nodes.
	if is_inside_tree():
		var nodesInSplatGroup = get_tree().get_nodes_in_group("splattable")
		for node in nodesInSplatGroup:
			_scan_nodes(node)

	# Delete old children.
	var childList = get_children()
	for i in childList:
		remove_child(i)
		i.queue_free()

	if len(splattableTriangleVerts):

		# Assemble all the individual array data together and add it to the mesh
		# as a surface.
		var newArrayMesh = ArrayMesh.new()
		var newArrayMeshArrays = []
		newArrayMeshArrays.resize(Mesh.ARRAY_MAX)
		newArrayMeshArrays[Mesh.ARRAY_VERTEX] = splattableTriangleVerts
		newArrayMeshArrays[Mesh.ARRAY_NORMAL] = splattableTriangleNormals
		newArrayMeshArrays[Mesh.ARRAY_TEX_UV] = splattableTriangleUVs
		newArrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, newArrayMeshArrays)

		# Assign the material to this surface.
		var materialInstance = material.duplicate()
		if materialInstance is ShaderMaterial:
			materialInstance.set_shader_param("splat_height", height)
		var newMeshInstance = MeshInstance.new()
		newMeshInstance.set_mesh(newArrayMesh)
		newMeshInstance.set_surface_material(0, materialInstance)

		# Add mesh the instance to the tree. We're not going to set the owner,
		# though, because we don't want to clutter up the tree in the editor.
		add_child(newMeshInstance)

	# Set the last transform so we know the next time something moves and we
	# need to update.
	if is_inside_tree():
		lastTransform = get_global_transform()
	else:
		lastTransform = Transform()

# ----------------------------------------------------------------------
# Engine stuff

# Called when the node enters the scene tree for the first time.
func _ready():
	call_deferred("rescan_all_nodes")
	set_notify_transform(true)
	set_notify_local_transform(true)

#func _process(_delta):
#	pass

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		call_deferred("rescan_all_nodes")
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		call_deferred("rescan_all_nodes")

# FIXME: Ugly hack that lets us rescan in the editor when the transform changes.
func _get_configuration_warning():
	# FIXME: Global transform.
	if lastTransform != get_global_transform():
		call_deferred("rescan_all_nodes")
	return ""

