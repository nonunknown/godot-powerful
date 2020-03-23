# ----------------------------------------------------------------------
# KiriSplat
# Copyright 2020 Kiri Jolly
# ----------------------------------------------------------------------

# Editor plugin implementation.

tool
extends EditorPlugin

const gizmoPluginScript = preload("KiriSplat_gizmo.gd")
var gizmoPlugin = gizmoPluginScript.new()

func _enter_tree():
	print("KiriSplat init")

	add_custom_type(
		"KiriSplatInstance",
		"Spatial",
		preload("KiriSplatInstance.gd"),
		preload("KiriSplatInstance_icon.png"))

	add_spatial_gizmo_plugin(gizmoPlugin)

func _exit_tree():
	print("KiriSplat shutdown")
	remove_spatial_gizmo_plugin(gizmoPlugin)
	remove_custom_type("KiriSplatInstance")

