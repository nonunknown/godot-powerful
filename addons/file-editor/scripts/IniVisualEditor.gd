tool
extends Control

var IconLoader = preload("res://addons/file-editor/scripts/IconLoader.gd").new()
var LastOpenedFiles = preload("res://addons/file-editor/scripts/LastOpenedFiles.gd").new()

onready var Keys = $VBoxContainer/HSplitContainer/VBoxContainer2/keys
onready var Sections = $VBoxContainer/HSplitContainer/VBoxContainer/sections2

onready var BtnAddSection = $VBoxContainer/HSplitContainer/VBoxContainer/HBoxContainer2/btn_add_section
onready var BtnRemoveSection = $VBoxContainer/HSplitContainer/VBoxContainer/HBoxContainer2/btn_remove_section

onready var BtnAddKey = $VBoxContainer/HSplitContainer/VBoxContainer2/HBoxContainer3/btn_add_key
onready var BtnEditKey = $VBoxContainer/HSplitContainer/VBoxContainer2/HBoxContainer3/btn_edit_key
onready var BtnRemoveKey = $VBoxContainer/HSplitContainer/VBoxContainer2/HBoxContainer3/btn_remove_key

onready var Section = $Section
onready var Key = $Key

var selected_key 
var selected_section : int = -1
var root : TreeItem

var current_file_path : String = ""

signal update_file()

func _ready():
	create_table_names()
	connect_signals()
	load_icons()
	clean_editor()
	
	add_to_group("ini_editor")
	
#	var metadata = [["name","Godot Engine"],["version","1.0.0"],["color","Light Blue"]]
#	load_section("Engine", metadata)

func connect_signals():
	Sections.connect("item_selected",self,"_on_section_selected")
	Sections.connect("nothing_selected",self,"_on_nosection_selected")
	
	BtnAddSection.connect("pressed",self,"_on_addsection_pressed")
	BtnRemoveSection.connect("pressed",self,"_on_removesection_pressed")
	
	Keys.connect("item_selected",self,"_on_key_selected")
	Keys.connect("nothing_selected",self,"_on_nokey_selected")
	
	BtnAddKey.connect("pressed",self,"_on_addkey_pressed")
	BtnRemoveKey.connect("pressed",self,"_on_removekey_pressed")
	BtnEditKey.connect("pressed",self,"_on_editkey_pressed")

func create_table_names():
	create_root()
	Keys.hide_root = true
	
	Keys.set_column_titles_visible(true)
	Keys.set_column_title(0,"Name")
	Keys.set_column_title(1,"Value")

func load_icons():
	$VBoxContainer/HSplitContainer/VBoxContainer/HBoxContainer/sections_icon.texture = IconLoader.load_icon_from_name("sections")
	$VBoxContainer/HSplitContainer/VBoxContainer2/HBoxContainer2/keys_icon.texture = IconLoader.load_icon_from_name("keys")
	BtnAddSection.icon = IconLoader.load_icon_from_name("add")
	BtnAddSection.hint_tooltip = "Add a new Section"
	BtnRemoveSection.icon = IconLoader.load_icon_from_name("delete")
	BtnRemoveSection.hint_tooltip = "Remove selected Section"
	
	BtnAddKey.icon = IconLoader.load_icon_from_name("add")
	BtnAddKey.hint_tooltip = "Add a new Key"
	BtnRemoveKey.icon = IconLoader.load_icon_from_name("delete")
	BtnRemoveKey.hint_tooltip = "Remove selected Key"
	BtnEditKey.icon = IconLoader.load_icon_from_name("edit_")
	BtnEditKey.hint_tooltip = "Edit selected Key"

func _on_addsection_pressed():
	Section.get_node("Container/section/_name").show()
	Section.window_title = "Add a new Section"
	if not Section.is_connected("confirmed",self,"new_section"):
		Section.connect("confirmed",self,"new_section")
	if Section.is_connected("confirmed",self,"remove_section"):
		Section.disconnect("confirmed",self,"remove_section")
	Section.popup()

func _on_removesection_pressed():
	Section.get_node("Container").hide()
	Section.window_title = "Remove selected Section"
	Section.dialog_text = "Are you sure you want to remove this Section?"
	if not Section.is_connected("confirmed",self,"remove_section"):
		Section.connect("confirmed",self,"remove_section")
	if Section.is_connected("confirmed",self,"new_section"):
		Section.disconnect("confirmed",self,"new_section")
	Section.popup()

func _on_addkey_pressed():
	Key.get_node("data").show()
	Key.get_node("data/HBoxContainer/name").editable = true
	Key.get_node("data/HBoxContainer/name").set_text("")
	Key.window_title = "Add a new Key"
	Key.dialog_text = ""
	if not Key.is_connected("confirmed",self,"new_key"):
		Key.connect("confirmed",self,"new_key")
	if Key.is_connected("confirmed",self,"edit_key"):
		Key.disconnect("confirmed",self,"edit_key")
	if Key.is_connected("confirmed",self,"remove_key"):
		Key.disconnect("confirmed",self,"remove_key")
	Key.popup()

func _on_removekey_pressed():
	Key.get_node("data").hide()
	Key.window_title = "Delete selected Key"
	Key.dialog_text = "Are you sure you want to remove the selected Key?"
	if not Key.is_connected("confirmed",self,"remove_key"):
		Key.connect("confirmed",self,"remove_key")
	if Key.is_connected("confirmed",self,"edit_key"):
		Key.disconnect("confirmed",self,"edit_key")
	if Key.is_connected("confirmed",self,"new_key"):
		Key.disconnect("confirmed",self,"new_key")
	Key.popup()

func _on_editkey_pressed():
	Key.get_node("data").show()
	Key.get_node("data/HBoxContainer/name").editable = false
	Key.get_node("data/HBoxContainer/name").set_text(str(selected_key.get_text(0)))
	Key.window_title = "Edit selected Key"
	Key.dialog_text = ""
	if not Key.is_connected("confirmed",self,"edit_key"):
		Key.connect("confirmed",self,"edit_key")
	if Key.is_connected("confirmed",self,"remove_key"):
		Key.disconnect("confirmed",self,"remove_key")
	if Key.is_connected("confirmed",self,"new_key"):
		Key.disconnect("confirmed",self,"new_key")
	Key.popup()

func clean_editor():
	Keys.clear()
	Sections.clear()
	selected_section = -1
	BtnAddKey.disabled = true
	if current_file_path == "":
		BtnAddSection.disabled = true
	else:
		BtnAddSection.disabled = false
	BtnEditKey.disabled = true
	BtnRemoveKey.disabled = true
	BtnRemoveSection.disabled = true
	
	create_root()

func open_file(filemap : Array):
	clean_editor()
	for section in filemap:
		load_sections(section[0],section[1])

func new_section():
	var file = ConfigFile.new()
	file.load(current_file_path)
	
	var section_name = str(Section.get_node("Container/section/_name").get_text())
	var key_name = str(Section.get_node("Container/key/_name").get_text())
	var key_value = Section.get_node("Container/value/_value").get_text()
	
	if section_name and key_name and key_value:
		file.set_value(section_name,key_name,key_value)
		file.save(current_file_path)
		
		load_sections(section_name,[[key_name,key_value]])
		
		emit_signal("update_file")
	else:
		print("Section <",section_name,"> with Key name: <",key_name,"> and Key value: <",key_value,"> not valid.")

func remove_section():
	var file = ConfigFile.new()
	file.load(current_file_path)
	var current_section = Sections.get_item_text(selected_section)
	file.erase_section(current_section)
	Sections.remove_item(selected_section)
	file.save(current_file_path)
	
	emit_signal("update_file")

func new_key():
	var key_name = str(Key.get_node("data/HBoxContainer/name").get_text())
	var key_value = Key.get_node("data/HBoxContainer2/value").get_text()
	if key_name and key_value:
		
		var file = ConfigFile.new()
		file.load(current_file_path)
		
		var current_section = Sections.get_item_text(selected_section)
		
		file.set_value(current_section,key_name,key_value)
		file.save(current_file_path)
		
		load_keys_selected_section([[key_name,key_value]])
		
		file.save(current_file_path)
		
		emit_signal("update_file")
	else:
		print("Key name: <",key_name,"> with Key value: <",key_value,"> not valid.")

func remove_key():
	var section = Sections.get_item_text(selected_section)
	var sectionmetadata = Sections.get_item_metadata(selected_section)
	
	for meta in sectionmetadata:
		if meta.has(selected_key.get_text(0)):
			sectionmetadata.erase(meta)
	
	Sections.set_item_metadata(selected_section,sectionmetadata)
	
	if Sections.get_item_metadata(selected_section) == []:
		Sections.remove_item(selected_section)
	
	var file = ConfigFile.new()
	file.load(current_file_path)
	file.set_value(section,selected_key.get_text(0),null)
	file.save(current_file_path)
	
	Keys.clear()
	create_root()
	load_keys_selected_section(sectionmetadata)
	
	emit_signal("update_file")

func edit_key():
	remove_key()
	new_key()

# load a section with custom fields @section_name = name of section ; @section_metadata = keys of this section with keys' properties
func load_sections(section_name : String, section_metadata : Array):
	Sections.add_item(section_name,IconLoader.load_icon_from_name("section"),true)
	Sections.set_item_metadata(Sections.get_item_count()-1,section_metadata)

# load a key of a selected section to fill the "keys" list
func load_keys_selected_section(metadata : Array):
	for key in metadata:
		var key_item = Keys.create_item(root)
		key_item.set_text(0,key[0])
		key_item.set_text(1,key[1])

func _on_section_selected(index : int):
	Keys.clear()
	create_root()
	BtnRemoveSection.disabled = false
	BtnAddSection.disabled = false
	BtnAddKey.disabled = false
	BtnRemoveKey.disabled = true
	BtnEditKey.disabled = true
	
	selected_section = index
	if Sections.get_item_metadata(index):
		load_keys_selected_section(Sections.get_item_metadata(index))

func _on_key_selected():
	selected_key = Keys.get_selected()
	BtnRemoveKey.disabled = false
	BtnEditKey.disabled = false

func _on_nosection_selected():
	BtnRemoveKey.disabled = true
	BtnAddKey.disabled = true
	BtnEditKey.disabled = true
	BtnRemoveSection.disabled = true
	Keys.clear()
	selected_section = -1

func _on_nokey_selected():
	BtnRemoveKey.disabled = true
	BtnEditKey.disabled = true

func create_root():
	root = Keys.create_item()
	root.set_text(0,"KEY_NAME")
	root.set_text(1,"KEY_VALUE")
