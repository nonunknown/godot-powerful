tool


# dclass : "FileSystemDock" || "ImportDock" || "NodeDock" || "SceneTreeDock" || "InspectorDock"; compares names in case of custom docks
static func get_dock(dclass : String, base_control_vbox : VBoxContainer) -> Node:
	for tabcontainer in base_control_vbox.get_child(1).get_child(0).get_children(): # LEFT left
		for dock in tabcontainer.get_children():
			if dock.get_class() == dclass or dock.name == dclass:
				dock.set_meta("pos", EditorPlugin.DOCK_SLOT_LEFT_UL if tabcontainer.get_index() == 0 else EditorPlugin.DOCK_SLOT_LEFT_BL)
				return dock
	
	for tabcontainer in base_control_vbox.get_child(1).get_child(1).get_child(0).get_children(): # LEFT right
		for dock in tabcontainer.get_children():
			if dock.get_class() == dclass or dock.name == dclass:
				dock.set_meta("pos", EditorPlugin.DOCK_SLOT_LEFT_UR if tabcontainer.get_index() == 0 else EditorPlugin.DOCK_SLOT_LEFT_BR)
				return dock
	
	for tabcontainer in base_control_vbox.get_child(1).get_child(1).get_child(1).get_child(1).get_child(0).get_children(): # RIGHT left
		for dock in tabcontainer.get_children():
			if dock.get_class() == dclass or dock.name == dclass:
				dock.set_meta("pos", EditorPlugin.DOCK_SLOT_RIGHT_UL if tabcontainer.get_index() == 0 else EditorPlugin.DOCK_SLOT_RIGHT_BL)
				return dock
	
	for tabcontainer in base_control_vbox.get_child(1).get_child(1).get_child(1).get_child(1).get_child(1).get_children(): # RIGHT right
		for dock in tabcontainer.get_children():
			if dock.get_class() == dclass or dock.name == dclass:
				dock.set_meta("pos", EditorPlugin.DOCK_SLOT_RIGHT_UR if tabcontainer.get_index() == 0 else EditorPlugin.DOCK_SLOT_RIGHT_BR)
				return dock
	
	push_warning("Plugin: %s dock not found." % dclass)
	return null


static func get_current_script_texteditor(script_editor : ScriptEditor) -> TextEdit:
	var script_index = script_editor.get_child(0).get_child(1).get_child(1).get_current_tab_control().get_index() # be careful about help pages
	return script_editor.get_child(0).get_child(1).get_child(1).get_child(script_index).get_child(0).get_child(0).get_child(0) as TextEdit 
