tool
extends Node

const lastopenedfile_path : String = "res://addons/file-editor/lastopenedfiles.lastcfg"

func _ready():
	pass

func store_opened_files(filecontainer : Control):
	var file = ConfigFile.new()
	file.load(lastopenedfile_path)
	for child in range(0,filecontainer.get_item_count()):
		var filepath = filecontainer.get_item_metadata(child)[0].current_path
		file.set_value("Opened",filepath.get_file(),filepath)
	
	file.save(lastopenedfile_path)

func remove_opened_file(index : int , filecontainer : Control):
	var file = ConfigFile.new()
	file.load(lastopenedfile_path)
	var filepath = filecontainer.get_item_metadata(index)[0].current_path
	file.set_value("Opened",filepath.get_file(),null)
	file.save(lastopenedfile_path)

func load_opened_files() -> Array:
	var file = ConfigFile.new()
	file.load(lastopenedfile_path)
	var keys = []
	if file.has_section("Opened"):
		var openedfiles = file.get_section_keys("Opened")
		for openedfile in openedfiles:
			keys.append([openedfile,file.get_value("Opened",openedfile)])
	return keys
