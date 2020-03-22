# FileSystem root
var fs: EditorFileSystemDirectory
# Indexed resources
var resources: Array
# Filtered index
var resources_filtered: Array

func _init(_fs: EditorFileSystemDirectory) -> void:
	fs = _fs
	build_index()

func build_index() -> void:
	resources = []
	search_directory(fs, "res://")
	resources_filtered = resources

func search_directory(dir: EditorFileSystemDirectory, cur_path: String) -> void:
	# Files
	for i in range(dir.get_file_count()):
		resources.append({
			"type": dir.get_file_type(i),
			"path": dir.get_file_path(i),
		})
	
	# Subdirectories
	for i in range(dir.get_subdir_count()):
		var subdir = dir.get_subdir(i)
		search_directory(subdir, cur_path + subdir.get_name())

func filter(text: String) -> void:
	if text == "":
		resources_filtered = resources
		return
	
	resources_filtered = []
	for res in resources:
		if text.is_subsequence_ofi(res.path):
			resources_filtered.append(res)
