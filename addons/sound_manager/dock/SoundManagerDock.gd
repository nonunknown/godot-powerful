tool
extends ScrollContainer

### Variables
#Path configuration section
onready var change_bgm_path_button = get_node("VBoxContainer/BGMPathPanel/FindPathButton");
onready var bgm_dir_field = get_node("VBoxContainer/BGMPathPanel/PathField");
onready var change_bgs_path_button = get_node("VBoxContainer/BGSPathPanel/FindPathButton");
onready var bgs_dir_field = get_node("VBoxContainer/BGSPathPanel/PathField");
onready var sfx_dir_field = get_node("VBoxContainer/SFXPathPanel/PathField");
onready var change_sfx_path_button = get_node("VBoxContainer/SFXPathPanel/FindPathButton");
onready var mfx_dir_field = get_node("VBoxContainer/MFXPathPanel/PathField");
onready var change_mfx_path_button = get_node("VBoxContainer/MFXPathPanel/FindPathButton");

#Audiobuses configuration
onready var bgm_bus_field = get_node("VBoxContainer/BGMBusPanel/NameField");
onready var bgs_bus_field = get_node("VBoxContainer/BGSBusPanel/NameField");
onready var sfx_bus_field = get_node("VBoxContainer/SFXBusPanel/NameField");
onready var mfx_bus_field = get_node("VBoxContainer/MFXBusPanel/NameField");

#Sound type buttons
onready var bgm_button = get_node("VBoxContainer/TypeContainer/BGM");
onready var bgs_button = get_node("VBoxContainer/TypeContainer/BGS");
onready var sfx_button = get_node("VBoxContainer/TypeContainer/SFX");
onready var mfx_button = get_node("VBoxContainer/TypeContainer/MFX");

#Tab section
onready var tab = get_node("VBoxContainer/TabContainer");
onready var bgm_files_tab = get_node("VBoxContainer/TabContainer/BGMScrollContainer/BGMFiles");
onready var bgs_files_tab = get_node("VBoxContainer/TabContainer/BGSScrollContainer/BGSFiles");
onready var sfx_files_tab = get_node("VBoxContainer/TabContainer/SFXScrollContainer/SFXFiles");
onready var mfx_files_tab = get_node("VBoxContainer/TabContainer/MFXScrollContainer/MFXFiles");

#Dictionary section
onready var dictionary_panel = get_node("VBoxContainer/DictionaryContainer/DictionaryPanel");
onready var add_entry_button = get_node("VBoxContainer/AddEntryButton");

#Advanced options section
onready var advanced_button = get_node("VBoxContainer/AdvancedOptions/AdvancedButton");
onready var preload_button = get_node("VBoxContainer/AdvancedOptions/PreloadButton");
onready var preinstantiate_button = get_node("VBoxContainer/AdvancedOptions/PreinstantiateButton");

#Internal variables
var TITLE				: String	= "SoundManager" ;
var BGM_DIR_PATH		: String	= "";
var BGS_DIR_PATH		: String	= "";
var SFX_DIR_PATH		: String	= "";
var MFX_DIR_PATH		: String	= "";
var BGM_BUS_NAME		: String	= "";
var BGS_BUS_NAME		: String	= "";
var SFX_BUS_NAME		: String	= "";
var MFX_BUS_NAME		: String	= "";
var PRELOAD_RES			: bool		= false;
var PREINSTANTIATE_NODES	: bool		= false;
var audio_files_dictionary : Dictionary = {};
var file : File = File.new();
var data_settings : Dictionary;

### Signals
signal change_dir_requested(sound_type);
signal check_file_names_requested;


func _ready() -> void:
	self.rect_size.x = get_node("VBoxContainer/TabContainer").rect_size.x + 25;
	var json_exists = read_sound_manager_settings();
	if (json_exists == false):
		update_sound_manager_settings();
	connect_signals();


func connect_signals() -> void:
	#Path fields and buttons
	bgm_dir_field.connect("text_entered", self, "_on_bgm_dir_field_entered")
	bgs_dir_field.connect("text_entered", self, "_on_bgs_dir_field_entered") 
	sfx_dir_field.connect("text_entered", self, "_on_sfx_dir_field_entered")
	mfx_dir_field.connect("text_entered", self, "_on_mfx_dir_field_entered")
	change_bgm_path_button.connect("pressed", self, "_on_BGM_FindPathButton_pressed")
	change_bgs_path_button.connect("pressed", self, "_on_BGS_FindPathButton_pressed")
	change_sfx_path_button.connect("pressed", self, "_on_SFX_FindPathButton_pressed")
	change_mfx_path_button.connect("pressed", self, "_on_MFX_FindPathButton_pressed")
	#Bus fields
	bgm_bus_field.connect("text_entered", self, "_on_bgm_bus_entered")
	bgs_bus_field.connect("text_entered", self, "_on_bgs_bus_entered")
	sfx_bus_field.connect("text_entered", self, "_on_sfx_bus_entered")
	mfx_bus_field.connect("text_entered", self, "_on_mfx_bus_entered")
	#Sound type buttons
	bgm_button.connect("pressed", self, "_on_type_button_pressed", ["BGM"])
	bgs_button.connect("pressed", self, "_on_type_button_pressed", ["BGS"])
	sfx_button.connect("pressed", self, "_on_type_button_pressed", ["SFX"])
	mfx_button.connect("pressed", self, "_on_type_button_pressed", ["MFX"])
	#Dictionary 
	add_entry_button.connect("pressed", self, "_on_add_entry_button_pressed")
	#Advanced
	advanced_button.connect("toggled", self, "_on_advanced_button_toggled");
	preload_button.connect("toggled", self, "_on_preload_button_toggled");
	preinstantiate_button.connect("toggled", self, "_on_preinstantiate_button_toggled");
	

### Functions to read and update the JSON file (res://addons/sound_manager/SoundManager.json)

func parse_json_string(json_file: String) -> Dictionary:
	var result: Dictionary = {}
	var json: JSONParseResult = JSON.parse(json_file)
	if typeof(json.result) == TYPE_DICTIONARY:
		result = json.result
	else:
		print_debug("Error to parse the JSON file")
	return result

func read_sound_manager_settings() -> bool:
	if (file.file_exists("res://addons/sound_manager/SoundManager.json") == false):
		return false;
		
	file.open("res://addons/sound_manager/SoundManager.json", File.READ);
	data_settings = parse_json_string(file.get_as_text());
	file.close();
	#Set the variables
	BGM_DIR_PATH = data_settings["BGM_DIR_PATH"];
	BGS_DIR_PATH = data_settings["BGS_DIR_PATH"];
	SFX_DIR_PATH = data_settings["SFX_DIR_PATH"];
	MFX_DIR_PATH = data_settings["MFX_DIR_PATH"];
	BGM_BUS_NAME = data_settings["BGM_BUS_NAME"];
	BGS_BUS_NAME = data_settings["BGS_BUS_NAME"];
	SFX_BUS_NAME = data_settings["SFX_BUS_NAME"];
	MFX_BUS_NAME = data_settings["MFX_BUS_NAME"];
	#get the audio files dictionary
	if data_settings["Dictionary"] is Dictionary:
		audio_files_dictionary = data_settings["Dictionary"];
	#get advanced options
	PRELOAD_RES = data_settings["PRELOAD_RES"];
	PREINSTANTIATE_NODES = data_settings["PREINSTANTIATE_NODES"];
	advanced_button.set_pressed(PRELOAD_RES || PREINSTANTIATE_NODES);
	preload_button.set_pressed(PRELOAD_RES);
	preinstantiate_button.set_pressed(PREINSTANTIATE_NODES);
	self._on_advanced_button_toggled(PRELOAD_RES || PREINSTANTIATE_NODES);
	self._on_preload_button_toggled(PRELOAD_RES);
	self._on_preinstantiate_button_toggled(PREINSTANTIATE_NODES);
	self.update_gui();
	return true;
#end

func update_sound_manager_settings() -> void:
	data_settings["BGM_DIR_PATH"] = BGM_DIR_PATH
	data_settings["BGS_DIR_PATH"] = BGS_DIR_PATH
	data_settings["SFX_DIR_PATH"] = SFX_DIR_PATH
	data_settings["MFX_DIR_PATH"] = MFX_DIR_PATH
	data_settings["BGM_BUS_NAME"] = BGM_BUS_NAME
	data_settings["BGS_BUS_NAME"] = BGS_BUS_NAME
	data_settings["SFX_BUS_NAME"] = SFX_BUS_NAME
	data_settings["MFX_BUS_NAME"] = MFX_BUS_NAME
	data_settings["Dictionary"] = audio_files_dictionary
	data_settings["PRELOAD_RES"] = PRELOAD_RES
	data_settings["PREINSTANTIATE_NODES"] = PREINSTANTIATE_NODES
	file.open("res://addons/sound_manager/SoundManager.json", File.WRITE)
	file.store_string(JSON.print(data_settings, "", true))
	file.close()
	self.update_gui();

#Update GUI
func update_gui() -> void:
	bgm_dir_field.text = BGM_DIR_PATH
	bgs_dir_field.text = BGS_DIR_PATH
	sfx_dir_field.text = SFX_DIR_PATH
	mfx_dir_field.text = MFX_DIR_PATH
	bgm_bus_field.text = BGM_BUS_NAME
	bgs_bus_field.text = BGS_BUS_NAME
	sfx_bus_field.text = SFX_BUS_NAME
	mfx_bus_field.text = MFX_BUS_NAME	
	populate_dictionary_panel()

### Files Tab handlers
func populate_files_tab( sound_type: String , file_names : PoolStringArray)->void:
	var files_tab : VBoxContainer
	if sound_type == "BGM":
		files_tab = bgm_files_tab
	elif sound_type == "BGS":
		files_tab = bgs_files_tab
	elif sound_type == "SFX":
		files_tab = sfx_files_tab
	else:
		files_tab = mfx_files_tab
	#Clean the file_tab selected
	if files_tab is Node:
		while files_tab.get_child_count() > 0:
			var child_node = files_tab.get_child(0)
			files_tab.remove_child(child_node)
			child_node.queue_free()
		#Populate the file_tab selected
		for i in range(0, file_names.size()):
			var file_extension = file_names[i].get_extension();
			if (file_extension == "wav" ||
			file_extension == "ogg" ||
			file_extension == "mp3" ||
			file_extension == "opus"):
				var file_name_container : HBoxContainer = HBoxContainer.new()
				var add_entry_button : ToolButton = ToolButton.new()
				var add_icon : Texture
				add_icon = load("res://addons/sound_manager/dock/assets/add_icon.svg") as Texture
				var line_edit : LineEdit = LineEdit.new()
				#Set the nodes
				file_name_container.alignment = BoxContainer.ALIGN_CENTER
				line_edit.name = "File_" + str(i)
				line_edit.rect_min_size = Vector2(280,0)
				line_edit.editable = false
				line_edit.text = file_names[i]
				add_entry_button.icon = add_icon
				add_entry_button.hint_tooltip = "Add a new entry in the dictionary for this sound file"
				#Add the nodes into the dock scene
				file_name_container.add_child(line_edit)
				file_name_container.add_child(add_entry_button)
				files_tab.add_child(file_name_container)
				#Make the signal connections
				add_entry_button.connect("pressed", self, "_on_add_entry_button_pressed", [line_edit.text])

func insert_new_entry(key: String = "", value: String = ""):
	var entry_container: HBoxContainer = HBoxContainer.new()
	var key_input : LineEdit = LineEdit.new()
	var value_input : LineEdit = LineEdit.new()
	var quit_entry_button : ToolButton = ToolButton.new()
	#Load the icon image for the quit entry button
	var quit_button_icon: Texture
	quit_button_icon = load("res://addons/sound_manager/dock/assets/remove_icon.svg") as Texture
	#Set the new nodes
	#Container
	entry_container.alignment = BoxContainer.ALIGN_CENTER
	entry_container.name = "Entry_" + str((dictionary_panel.get_child_count() + 1))
	#Key UI
	if key == "":
		key_input.text = "Sound_" + str((dictionary_panel.get_child_count() + 1))
	else:
		key_input.text = key
	key_input.placeholder_text = "Sound name"
	key_input.rect_min_size = Vector2(120,0)
	key_input.max_length = 280
	key_input.hint_tooltip = "Insert here a key for this sound file"
	#Value UI
	value_input.text = value
	value_input.placeholder_text = "sound_file_name.extension"
	value_input.rect_min_size = Vector2(160,0)
	value_input.max_length = 280
	value_input.hint_tooltip = "Insert here the name of a sound file (name_file.extension)"
	quit_entry_button.icon = quit_button_icon
	quit_entry_button.hint_tooltip = "Remove this entry"
	#Insert the new nodes into the scene
	entry_container.add_child(key_input)
	entry_container.add_child(value_input)
	entry_container.add_child(quit_entry_button)
	dictionary_panel.add_child(entry_container)
	#Make the signal connections
	key_input.connect("text_entered", self, "_on_key_input_entered", [value_input.text])
	value_input.connect("text_entered", self, "_on_value_input_entered",[key_input.text])
	quit_entry_button.connect("pressed", self, "_on_quit_entry_button_pressed", [entry_container.name])

func populate_dictionary_panel():
	if audio_files_dictionary.size() > 0:
		var dictionary_keys: Array = audio_files_dictionary.keys()
		#Clean the dictionary panel
		while dictionary_panel.get_child_count() > 0:
			var child_node = dictionary_panel.get_child(0)
			dictionary_panel.remove_child(child_node)
			child_node.queue_free()
		#Populate the dictionary
		for i in range(0, dictionary_keys.size()):
			var key: String = dictionary_keys[i]
			var value: String = audio_files_dictionary[key]
			insert_new_entry(key, value)

func update_dictionary() ->void:
	#Construct a new dictionary from the inputs of the dictionary section
	var new_dictionary: Dictionary = {}
	if dictionary_panel.get_child_count() > 0:
		for i in range(0, dictionary_panel.get_child_count()):
			var key : String = dictionary_panel.get_child(i).get_child(0).text
			var value: String = dictionary_panel.get_child(i).get_child(1).text
			new_dictionary[key] = value
	audio_files_dictionary = new_dictionary
	#Update the Sound Manager JSON file
	update_sound_manager_settings()

### UI signals handlers
func _on_bgm_dir_field_entered(new_path) -> void:
	BGM_DIR_PATH = new_path
	#Check the files names from all the paths registered
	emit_signal("check_file_names_requested")
	update_sound_manager_settings()

func _on_bgs_dir_field_entered(new_path) -> void:
	BGS_DIR_PATH = new_path
	#Check the files names from all the paths registered
	emit_signal("check_file_names_requested")
	update_sound_manager_settings()

func _on_sfx_dir_field_entered(new_path) -> void:
	SFX_DIR_PATH = new_path
	#Check the files names from all the paths registered
	emit_signal("check_file_names_requested")
	update_sound_manager_settings()

func _on_mfx_dir_field_entered(new_path) -> void:
	MFX_DIR_PATH = new_path
	#Check the files names from all the paths registered
	emit_signal("check_file_names_requested")
	update_sound_manager_settings()

func _on_BGM_FindPathButton_pressed() -> void:
	emit_signal("change_dir_requested", "BGM")

func _on_BGS_FindPathButton_pressed() -> void:
	emit_signal("change_dir_requested", "BGS")

func _on_SFX_FindPathButton_pressed() -> void:
	emit_signal("change_dir_requested", "SFX")

func _on_MFX_FindPathButton_pressed() -> void:
	emit_signal("change_dir_requested", "MFX")

func _on_bgm_bus_entered(bus : String) -> void:
	BGM_BUS_NAME = bus if (AudioServer.get_bus_index(bus) >= 0) else "Master"
	update_sound_manager_settings()
	
func _on_bgs_bus_entered(bus : String) -> void:
	BGS_BUS_NAME = bus if (AudioServer.get_bus_index(bus) >= 0) else "Master"
	update_sound_manager_settings()
	
func _on_sfx_bus_entered(bus : String) -> void:
	SFX_BUS_NAME = bus if (AudioServer.get_bus_index(bus) >= 0) else "Master"
	update_sound_manager_settings()
	
func _on_mfx_bus_entered(bus : String) -> void:
	MFX_BUS_NAME = bus if (AudioServer.get_bus_index(bus) >= 0) else "Master"
	update_sound_manager_settings()

func _on_type_button_pressed(sound_type):
	if sound_type == "BGM":
		tab.current_tab = 0
		bgm_button.pressed = true
	elif sound_type == "BGS":
		tab.current_tab = 1
	elif sound_type == "SFX":
		tab.current_tab = 2
	elif sound_type == "MFX":
		tab.current_tab = 3

#Insert a new entry from the dictionary section
func _on_add_entry_button_pressed(file_name: String = "")->void:
	insert_new_entry("", file_name)

#Remove an entry from the dictionary
func _on_quit_entry_button_pressed(node_name : String) -> void:
	var child_node: Node = dictionary_panel.get_node(node_name)
	if child_node is Node:
		dictionary_panel.remove_child(child_node)
		child_node.queue_free()
	update_dictionary()

func _on_key_input_entered(new_key: String, new_value: String) -> void:
	if new_key != "" and new_value != "":
		update_dictionary()

func _on_value_input_entered(new_value: String, new_key: String) -> void:
	if new_key != "" and new_value != "":
		update_dictionary()


#### Plugin.gd - Sound Manager Dock Scene communication - Signal handlers

func _on_bgm_dir_changed(path: String, file_names: PoolStringArray) -> void:
	BGM_DIR_PATH = path
	populate_files_tab("BGM", file_names)
	update_sound_manager_settings()

func _on_bgs_dir_changed(path: String, file_names: PoolStringArray) -> void:
	BGS_DIR_PATH = path
	populate_files_tab("BGS", file_names)
	update_sound_manager_settings()

func _on_sfx_dir_changed(path: String, file_names: PoolStringArray) -> void:
	SFX_DIR_PATH = path
	populate_files_tab("SFX", file_names)
	update_sound_manager_settings()

func _on_mfx_dir_changed(path: String, file_names: PoolStringArray) -> void:
	MFX_DIR_PATH = path
	populate_files_tab("MFX", file_names)
	update_sound_manager_settings()

func _on_file_names_updated(bgm_file_names, bgs_file_names,sfx_file_names, mfx_file_names):
	populate_files_tab("BGM", bgm_file_names)
	populate_files_tab("BGS", bgs_file_names)
	populate_files_tab("SFX", sfx_file_names)
	populate_files_tab("MFX", mfx_file_names)
	
func _on_advanced_button_toggled(toggled : bool) -> void:
	$VBoxContainer/AdvancedOptions/PreloadLabel.set_visible(toggled);
	preload_button.set_visible(toggled);
	$VBoxContainer/AdvancedOptions/PreinstantiateLabel.set_visible(toggled);
	preinstantiate_button.set_visible(toggled);
	PRELOAD_RES = toggled && preload_button.is_pressed();
	PREINSTANTIATE_NODES = toggled && preinstantiate_button.is_pressed();
	update_sound_manager_settings()
	
func _on_preload_button_toggled(toggled : bool) -> void:
	PRELOAD_RES = toggled;
	update_sound_manager_settings();

func _on_preinstantiate_button_toggled(toggled : bool) -> void:
	PREINSTANTIATE_NODES = toggled;
	update_sound_manager_settings();
