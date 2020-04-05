tool
extends EditorPlugin

const PLUGIN_NAME = "NodeConntectorPlugin";
const MENU_ITEM = "Connect selected Nodes";

func _enter_tree():
	add_tool_menu_item(MENU_ITEM, self, "onUse");
	pass

func onUse(evt):
	var editor = get_editor_interface();
	var selectedNodes = editor.get_selection().get_selected_nodes();
	if selectedNodes.size() == 0:
		logError("No nodes selected.");
		return;
		
	# Load or create the current scene script
	var scene = editor.get_edited_scene_root();
	var sceneScript:Script = scene.get_script();
	var scriptPath = "";
	var scriptSource = "";
	if sceneScript == null:
		scriptPath = getFilePathPrefix(scene.filename) + scene.name + ".gd";
	else:
		scriptPath = sceneScript.resource_path;

	if sceneScript != null && sceneScript.has_source_code():
		scriptSource = sceneScript.source_code;
	else:
		scriptSource = getDefaultScript(scene);
	
	# Generate the lines of code to insert
	var headerLines = [''];
	var readyLines = [];
	var footerLines = [];
	var nodeNames = [];
	for node in selectedNodes:
		var nodeName: String = node.name;
		var nodeVariable = getNodeVariableName(nodeName);
		nodeNames.append(nodeName);
		headerLines.append('onready var %s = find_node("%s");' % [nodeVariable, nodeName]);
		 
		var signalName = "";
		if node is Button:
			signalName = "pressed";
		elif node is TextEdit:
			signalName = "text_changed";
		
		if signalName != "":
			var handleName = "_on" + nodeName + getUpperCaseSignal(signalName);
			readyLines.append('\t%s.connect("%s", self, "%s");' % [nodeVariable, signalName, handleName]);
			footerLines.append('\n');
			footerLines.append('func %s():' % [handleName]);
			footerLines.append('\tpass;');
	
	# Insert lines of code into sections of the script
	var headerPos = findPositionAfterLine(scriptSource, "extends *");
	if headerPos == -1:
		logError("Could not find an extends statement in script.");
		return;
	scriptSource = modifySection(scriptSource, headerPos, headerLines);

	var readyPos = findPositionAfterLine(scriptSource, "func _ready(*");
	if readyPos == -1:
		logError("Could not find a _ready function in script.");
		return;
	scriptSource = modifySection(scriptSource, readyPos, readyLines);

	scriptSource = modifySection(scriptSource, scriptSource.length(), footerLines);
	
	# Actually write to scene script file
	var f = File.new();
	var err = f.open(scriptPath, File.WRITE);
	if err > 0:
		logError("Cannot open %s for writing. Error code: %i" % [scriptPath, err]);
		return;
	f.store_string(scriptSource);
	f.close();
	
	var updatedScript = load(scriptPath) as Script;
	scene.set_script(updatedScript);
	
	# Success!
	print("%s: Added %s to scene script '%s'." % [PLUGIN_NAME, str(nodeNames), scriptPath]);
	print("%s: Please unfocus Godot window and refocus to see changes to script." % PLUGIN_NAME);


func modifySection(source, pos, sourceLines):
	if sourceLines.size() == 0:
		return source;

	var newSource = '';
	for line in sourceLines:
		newSource += line + '\n';

	return source.insert(pos, newSource);
	
	
func findPositionAfterLine(source: String, lineMatch: String) -> int:
	var lines = source.split("\n");
	var position = 0;
	for line in lines:
		position += line.length() + 1;
		if line.match(lineMatch):
			return position;
	
	return -1;
	

func logError(message):
	printerr(PLUGIN_NAME + ": " + message);
	
	
func getDefaultScript(node):
	var lines = PoolStringArray();
	lines.append("extends Control");
	lines.append("");
	lines.append("func _ready():");
	lines.append("\tpass;");
	return lines.join('\n');
	
	
func getFilePathPrefix(fileName):
	var parts = fileName.split('/');
	parts.remove(parts.size() - 1);
	return parts.join('/') + '/';


func getNodeVariableName(name):
	name = name.replace(" ", "_");
	var first = name.substr(0, 1);
	return first.to_lower() + name.substr(1);


func getUpperCaseSignal(name):
	var parts = name.split("_");
	var newName = "";
	for part in parts:
		var first = part.substr(0, 1);
		newName += first.to_upper() + part.substr(1);
	return newName;


func _exit_tree():
	remove_tool_menu_item(MENU_ITEM);
