tool
extends Control

onready var FileList = $FileList

onready var NewFileDialogue = $NewFileDialogue
onready var NewFileDialogue_name = $NewFileDialogue/VBoxContainer/new_filename

onready var FileBTN = $FileEditorContainer/TobBar/file_btn.get_popup()
onready var PreviewBTN = $FileEditorContainer/TobBar/preview_btn.get_popup()
onready var EditorBTN = $FileEditorContainer/TobBar/editor_btn.get_popup()

onready var Version = $FileEditorContainer/TobBar/version


onready var FileContainer = $FileEditorContainer/SplitContainer/FileContainer
onready var OpenFileList = $FileEditorContainer/SplitContainer/FileContainer/OpenFileList
onready var OpenFileName = $FileEditorContainer/SplitContainer/EditorContainer/HBoxContainer/OpenFileName
onready var SplitEditorContainer = $FileEditorContainer/SplitContainer/EditorContainer
onready var WrapBTN = $FileEditorContainer/SplitContainer/EditorContainer/HBoxContainer/wrap_button
onready var MapBTN = $FileEditorContainer/SplitContainer/EditorContainer/HBoxContainer/map_button

var IconLoader = preload("res://addons/file-editor/scripts/IconLoader.gd").new()
var LastOpenedFiles = preload("res://addons/file-editor/scripts/LastOpenedFiles.gd").new()

var Preview = preload("res://addons/file-editor/scenes/Preview.tscn")
var IniEditor = preload("res://addons/file-editor/scenes/IniEditor.tscn")
var VanillaEditor = preload("res://addons/file-editor/scenes/VanillaEditor.tscn")
var CsvEditor = preload("res://addons/file-editor/scenes/CsvEditor.tscn")

onready var EditorContainer = $FileEditorContainer/SplitContainer

var DIRECTORY : String = "res://"
var EXCEPTIONS : String = "addons"
var EXTENSIONS : PoolStringArray = [
"*.txt ; Plain Text File", 
"*.rtf ; Rich Text Format File", 
"*.log ; Log File", 
"*.md ; MD File",
"*.doc ; WordPad Document",
"*.doc ; Microsoft Word Document",
"*.docm ; Word Open XML Macro-Enabled Document",
"*.docx ; Microsoft Word Open XML Document",
"*.bbs ; Bulletin Board System Text",
"*.dat ; Data File",
"*.xml ; XML File",
"*.sql ; SQL database file",
"*.json ; JavaScript Object Notation File",
"*.html ; HyperText Markup Language",
"*.csv ; Comma-separated values",
"*.cfg ; Configuration File",
"*.ini ; Initialization File (same as .cfg Configuration File)",
"*.csv ; Comma-separated values File",
]

var directories = []
var files = []
var current_file_index = -1
var current_file_path = ""
var save_as = false
var current_editor : Control 
var current_ini_editor : Control
var current_csv_editor : Control



func _ready():
	
	clean_editor()
	update_version()
	connect_signals()
	create_shortcuts()
	load_icons()
	
	var opened_files : Array = LastOpenedFiles.load_opened_files()
	for open_file in opened_files:
		open_file(open_file[1])
	
	FileList.set_filters(EXTENSIONS)

func create_shortcuts():
	var hotkey 
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_S
	hotkey.control = true
	FileBTN.set_item_accelerator(4,hotkey.get_scancode_with_modifiers()) # save file
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_N
	hotkey.control = true
	FileBTN.set_item_accelerator(0,hotkey.get_scancode_with_modifiers()) # new file
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_O
	hotkey.control = true
	FileBTN.set_item_accelerator(1,hotkey.get_scancode_with_modifiers()) # open file
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_D
	hotkey.control = true
	FileBTN.set_item_accelerator(6,hotkey.get_scancode_with_modifiers()) # delete file
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_S
	hotkey.control = true
	hotkey.alt = true
	FileBTN.set_item_accelerator(5,hotkey.get_scancode_with_modifiers()) #save file as
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_C
	hotkey.control = true
	hotkey.alt = true
	FileBTN.set_item_accelerator(2,hotkey.get_scancode_with_modifiers()) # close file
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_F
	hotkey.control = true
	FileBTN.set_item_accelerator(8,hotkey.get_scancode_with_modifiers()) # search
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_R
	hotkey.control = true
	FileBTN.set_item_accelerator(9,hotkey.get_scancode_with_modifiers()) # replace
	
	# vanilla editor -----------------------
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_1
	hotkey.control = true
	EditorBTN.set_item_accelerator(0,hotkey.get_scancode_with_modifiers()) # vanilla editor
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_2
	hotkey.control = true
	EditorBTN.set_item_accelerator(1,hotkey.get_scancode_with_modifiers()) # csv editor
	
	hotkey = InputEventKey.new()
	hotkey.scancode = KEY_3
	hotkey.control = true
	EditorBTN.set_item_accelerator(2,hotkey.get_scancode_with_modifiers()) # inieditor editor

func load_icons():
	$FileEditorContainer/TobBar/file_btn.icon = IconLoader.load_icon_from_name("file")
	$FileEditorContainer/TobBar/preview_btn.icon = IconLoader.load_icon_from_name("read")
	$FileEditorContainer/TobBar/editor_btn.icon = IconLoader.load_icon_from_name("edit_")

func connect_signals():
	FileList.connect("confirmed",self,"update_list")
	FileBTN.connect("id_pressed",self,"_on_filebtn_pressed")
	PreviewBTN.connect("id_pressed",self,"_on_previewbtn_pressed")
	EditorBTN.connect("id_pressed",self,"_on_editorbtn_pressed")
	
	OpenFileList.connect("item_selected",self,"_on_fileitem_pressed")
	WrapBTN.connect("item_selected",self,"on_wrap_button")
	MapBTN.connect("item_selected",self,"on_minimap_button")

func update_version():
	var plugin_version = ""
	var config =  ConfigFile.new()
	var err = config.load("res://addons/file-editor/plugin.cfg")
	if err == OK:
		plugin_version = config.get_value("plugin","version")
	Version.set_text("v"+plugin_version)
	print(plugin_version)

func create_selected_file():
	update_list()
	FileList.mode = FileDialog.MODE_SAVE_FILE
	FileList.set_title("Create a new File")
	if FileList.is_connected("file_selected",self,"delete_file"):
		FileList.disconnect("file_selected",self,"delete_file")
	if FileList.is_connected("file_selected",self,"open_file"):
		FileList.disconnect("file_selected",self,"open_file")
	if not FileList.is_connected("file_selected",self,"create_new_file"):
		FileList.connect("file_selected",self,"create_new_file")
	open_filelist()

func open_selected_file():
	update_list()
	FileList.mode = FileDialog.MODE_OPEN_FILE
	FileList.set_title("Select a File you want to edit")
	if FileList.is_connected("file_selected",self,"delete_file"):
		FileList.disconnect("file_selected",self,"delete_file")
	if FileList.is_connected("file_selected",self,"create_new_file"):
		FileList.disconnect("file_selected",self,"create_new_file")
	if not FileList.is_connected("file_selected",self,"open_file"):
		FileList.connect("file_selected",self,"open_file")
	open_filelist()

func delete_selected_file():
	update_list()
	FileList.mode = FileDialog.MODE_OPEN_FILES
	FileList.set_title("Select one or more Files you want to delete")
	if FileList.is_connected("file_selected",self,"open_file"):
		FileList.disconnect("file_selected",self,"open_file")
	if FileList.is_connected("file_selected",self,"create_new_file"):
		FileList.disconnect("file_selected",self,"create_new_file")
	if not FileList.is_connected("files_selected",self,"delete_file"):
		FileList.connect("files_selected",self,"delete_file")
	open_filelist()

func save_current_file_as():
	update_list()
	FileList.mode = FileDialog.MODE_SAVE_FILE
	FileList.set_title("Save this File as...")
	if FileList.is_connected("file_selected",self,"delete_file"):
		FileList.disconnect("file_selected",self,"delete_file")
	if FileList.is_connected("file_selected",self,"open_file"):
		FileList.disconnect("file_selected",self,"open_file")
	if not FileList.is_connected("file_selected",self,"create_new_file"):
		FileList.connect("file_selected",self,"create_new_file")
	open_filelist()

func _on_filebtn_pressed(index : int):
	match index:
		0:
			create_selected_file()
		1:
			open_selected_file()
		2:
			if current_file_index!=-1 and current_file_path != "":
				close_file(current_file_index)
		
		3:
			if current_file_index!=-1 and current_file_path != "":
				save_as = false
				save_file(current_file_path)
		4:
			if current_file_index!=-1 and current_file_path != "":
				save_as = true
				save_file(current_file_path)
				save_current_file_as()
		5:
			delete_selected_file()
		6:
			current_editor.open_searchbox()
		7:
			current_editor.open_replacebox()

func _on_previewbtn_pressed(id : int):
	if id == 0:
		bbcode_preview()
	elif id == 1:
		markdown_preview()
	elif id == 2:
		html_preview()
	elif id == 3:
		csv_preview()
	elif id == 4:
		xml_preview()
	elif id == 5:
		json_preview()

func _on_editorbtn_pressed(index : int):
	match index:
		0:
			if not current_editor.visible:
				current_editor.show()
				if current_csv_editor:
					current_csv_editor.hide()
				if current_ini_editor:
					current_ini_editor.hide()
		1:
			if current_csv_editor and not current_csv_editor.visible:
				current_csv_editor.show()
				current_editor.hide()
				if current_ini_editor:
					current_ini_editor.hide()
		2:
			if current_ini_editor and not current_ini_editor.visible:
				current_editor.hide()
				if current_csv_editor:
					current_csv_editor.hide()
				current_ini_editor.show()

func _on_fileitem_pressed(index : int):
	current_file_index = index
	var selected_item_metadata = OpenFileList.get_item_metadata(index)
	var extension = selected_item_metadata[0].current_path.get_file().get_extension()
	current_file_path = selected_item_metadata[0].current_path
	
	if current_editor.visible:
		current_editor.hide()
		current_editor = selected_item_metadata[0]
		current_editor.show()
		OpenFileName.set_text(current_editor.current_path)
		current_csv_editor = selected_item_metadata[2]
		current_ini_editor = selected_item_metadata[1]
		if WrapBTN.get_selected_id() == 1:
			current_editor.set_wrap_enabled(true)
		else:
			current_editor.set_wrap_enabled(false)
		if MapBTN.get_selected_id() == 1:
			current_editor.draw_minimap(true)
		else:
			current_editor.draw_minimap(false)
	elif current_csv_editor and current_csv_editor.visible:
		if extension == "csv":
			current_csv_editor.hide()
			current_csv_editor = selected_item_metadata[2]
			current_csv_editor.show()
			OpenFileName.set_text(current_csv_editor.current_file_path)
			current_editor = selected_item_metadata[0]
			current_ini_editor = selected_item_metadata[1]
		else:
			if current_csv_editor:
				current_csv_editor.hide()
			current_csv_editor = selected_item_metadata[2]
			if current_ini_editor:
				current_ini_editor.hide()
			current_ini_editor = selected_item_metadata[1]
			current_editor.hide()
			current_editor = selected_item_metadata[0]
			current_editor.show()
			OpenFileName.set_text(current_editor.current_path)
	elif current_ini_editor and current_ini_editor.visible:
		if extension == "cfg" or extension == "ini":
			current_ini_editor.hide()
			current_ini_editor = selected_item_metadata[1]
			current_ini_editor.show()
			OpenFileName.set_text(current_ini_editor.current_file_path)
		else:
			if current_ini_editor:
				current_ini_editor.hide()
			current_ini_editor = selected_item_metadata[1]
			if current_csv_editor:
				current_csv_editor.hide()
			current_csv_editor = selected_item_metadata[2]
			current_editor.hide()
			current_editor = selected_item_metadata[0]
			current_editor.show()
			OpenFileName.set_text(current_editor.current_path)

func open_file(path : String):
	if current_file_path != path:
		current_file_path = path
		
		var vanilla_editor = open_in_vanillaeditor(path)
		var ini_editor = open_in_inieditor(path)
		var csv_editor = open_in_csveditor(path)
		
		generate_file_item(path,vanilla_editor,ini_editor,csv_editor)
		
		LastOpenedFiles.store_opened_files(OpenFileList)
	current_editor.show()

func generate_file_item(path : String , veditor : Control , inieditor : Control, csveditor : Control):
	OpenFileName.set_text(path)
	OpenFileList.add_item(path.get_file(),IconLoader.load_icon_from_name("file"),true)
	current_file_index = OpenFileList.get_item_count()-1
	OpenFileList.set_item_metadata(current_file_index,[veditor,inieditor,csveditor])
	OpenFileList.select(OpenFileList.get_item_count()-1)

func open_in_vanillaeditor(path : String) -> Control:
	var editor = VanillaEditor.instance()
	SplitEditorContainer.add_child(editor,true)
	
	if current_editor and current_editor!=editor:
		editor.show()
		current_editor.hide()
	
	current_editor = editor
	
	
	editor.connect("text_changed",self,"_on_vanillaeditor_text_changed")
	
	var current_file : File = File.new()
	current_file.open(path,File.READ)
	var current_content = ""
	current_content = current_file.get_as_text()
	
	var last_modified = OS.get_datetime_from_unix_time(current_file.get_modified_time(path))
	
	current_file.close()
	
	editor.new_file_open(current_content,last_modified,current_file_path)
	
	update_list()
	
	if WrapBTN.get_selected_id() == 1:
		current_editor.set_wrap_enabled(true)
	
	return editor

func open_in_inieditor(path : String) -> Control:
	var extension = path.get_file().get_extension()
	if extension == "ini" or extension == "cfg":
		var inieditor = IniEditor.instance()
		SplitEditorContainer.add_child(inieditor)
		inieditor.hide()
		inieditor.connect("update_file",self,"_on_update_file")
		current_ini_editor = inieditor
		inieditor.current_file_path = path
		var current_file : ConfigFile = ConfigFile.new()
		var err = current_file.load(path)
		if err == OK:
			var sections = current_file.get_sections()
			var filemap = []
			for section in sections:
				var keys = []
				var section_keys = current_file.get_section_keys(section)
				for key in section_keys:
					keys.append([key,current_file.get_value(section,key)])
				
				filemap.append([section,keys])
			
			inieditor.open_file(filemap)
		return inieditor
	else:
		current_ini_editor = null
		return null

func open_in_csveditor(path : String) -> Control:
	var extension = path.get_file().get_extension()
	if extension == "csv":
		var csveditor = CsvEditor.instance()
		SplitEditorContainer.add_child(csveditor)
		csveditor.hide()
		csveditor.connect("update_file",self,"_on_update_file")
		current_csv_editor = csveditor
		csveditor.current_file_path = path
		csveditor.open_csv_file(path,"|")
		return csveditor
	else:
		current_csv_editor = null
		return null

func close_file(index):
	LastOpenedFiles.remove_opened_file(index,OpenFileList)
	OpenFileList.remove_item(index)
	OpenFileName.clear()
	current_editor.queue_free()
	
	OpenFileList.select(OpenFileList.get_item_count()-1)
	_on_fileitem_pressed(OpenFileList.get_item_count()-1)

func _on_update_file():
	current_editor.clean_editor()
	var current_file : File = File.new()
	current_file.open(current_file_path,File.READ)
	
	var current_content = current_file.get_as_text()
	var last_modified = OS.get_datetime_from_unix_time(current_file.get_modified_time(current_file_path))
	
	current_file.close()
	
	current_editor.new_file_open(current_content,last_modified,current_file_path)

func delete_file(files_selected : PoolStringArray):
	var dir = Directory.new()
	for file in files_selected:
		dir.remove(file)
	
	update_list()

func open_newfiledialogue():
	NewFileDialogue.popup()
	NewFileDialogue.set_position(OS.get_screen_size()/2 - NewFileDialogue.get_size()/2)

func open_filelist():
	update_list()
	FileList.popup()
	FileList.set_position(OS.get_screen_size()/2 - FileList.get_size()/2)

func create_new_file(given_path : String):
	var current_file = File.new()
	current_file.open(given_path,File.WRITE)
	if save_as : 
		current_file.store_line(current_editor.get_node("TextEditor").get_text())
	current_file.close()
	
	open_file(given_path)

func save_file(current_path : String):
	var current_file = File.new()
	current_file.open(current_path,File.WRITE)
	var current_content = ""
	var lines = current_editor.get_node("TextEditor").get_line_count()
	for line in range(0,lines):
		current_content = current_editor.get_node("TextEditor").get_text()
		current_file.store_line(current_editor.get_node("TextEditor").get_line(line))
	current_file.close()
	
	current_file_path = current_file_path
	
	var last_modified = OS.get_datetime_from_unix_time(current_file.get_modified_time(current_path))
	
	current_editor.update_lastmodified(last_modified,"save")
	OpenFileList.set_item_metadata(current_file_index,[current_content,last_modified,current_path])
	
	if OpenFileList.get_item_text(current_file_index).ends_with("(*)"):
		OpenFileList.set_item_text(current_file_index,OpenFileList.get_item_text(current_file_index).rstrip("(*)"))
	
	OpenFileList.set_item_metadata(current_file_index,[current_editor,open_in_inieditor(current_file_path),open_in_csveditor(current_file_path)])
	
	update_list()

func clean_editor() -> void :
	for inieditor in get_tree().get_nodes_in_group("ini_editor"):
		inieditor.queue_free()
	for vanillaeditor in get_tree().get_nodes_in_group("vanilla_editor"):
		vanillaeditor.queue_free()
	OpenFileName.clear()
	OpenFileList.clear()


func csv_preview():
	var preview = Preview.instance()
	get_parent().get_parent().get_parent().add_child(preview)
	preview.popup()
	preview.window_title += " ("+current_file_path.get_file()+")"
	var lines = current_editor.get_node("TextEditor").get_line_count()
	var rows = []
	for i in range(0,lines-1):
		rows.append(current_editor.get_node("TextEditor").get_line(i).rsplit(",",false))
	preview.print_csv(rows)

func bbcode_preview():
	var preview = Preview.instance()
	get_parent().get_parent().get_parent().add_child(preview)
	preview.popup()
	preview.window_title += " ("+current_file_path.get_file()+")"
	preview.print_bb(current_editor.get_node("TextEditor").get_text())

func markdown_preview():
	var preview = Preview.instance()
	get_parent().get_parent().get_parent().add_child(preview)
	preview.popup()
	preview.window_title += " ("+current_file_path.get_file()+")"
	preview.print_markdown(current_editor.get_node("TextEditor").get_text())

func html_preview():
	var preview = Preview.instance()
	get_parent().get_parent().get_parent().add_child(preview)
	preview.popup()
	preview.window_title += " ("+current_file_path.get_file()+")"
	preview.print_html(current_editor.get_node("TextEditor").get_text())

func xml_preview():
	pass

func json_preview():
	pass


func _on_vanillaeditor_text_changed():
	if not OpenFileList.get_item_text(current_file_index).ends_with("(*)"):
		OpenFileList.set_item_text(current_file_index,OpenFileList.get_item_text(current_file_index)+"(*)")


func update_list():
	FileList.invalidate()

func on_wrap_button(index:int):
	match index:
		0:
			current_editor.set_wrap_enabled(false)
		1:
			current_editor.set_wrap_enabled(true)

func on_minimap_button(index:int):
	match index:
		0:
			current_editor.draw_minimap(false)
		1:
			current_editor.draw_minimap(true)

func check_file_preview(file : String):
	# check whether the opened file has a corresponding preview session for its extension
	 pass
