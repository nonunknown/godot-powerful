tool
extends VBoxContainer

var IconLoader = preload("res://addons/file-editor/scripts/IconLoader.gd").new()
var LastOpenedFiles = preload("res://addons/file-editor/scripts/LastOpenedFiles.gd").new()

onready var ReadOnly = $FileInfo/Readonly

onready var TextEditor = $TextEditor

onready var LastModified = $FileInfo/lastmodified

onready var FileList = get_parent().get_parent().get_parent().get_parent().get_node("FileList")

onready var ClosingFile = get_parent().get_parent().get_parent().get_parent().get_node("ConfirmationDialog")

onready var LastModifiedIcon = $FileInfo/lastmodified_icon

onready var SearchBox = $SearchBox
onready var ReplaceBox = $ReplaceBox

onready var c_counter = $FileInfo/c_counter

var current_path = ""
var current_filename = ""
var Preview = load("res://addons/file-editor/scenes/Preview.tscn")


var search_flag = 0

signal text_changed()

func _ready():
	ClosingFile.connect("confirmed",self,"queue_free")
	
	ReadOnly.connect("toggled",self,"_on_Readonly_toggled")
	
	ReadOnly.set("custom_icons/checked",IconLoader.load_icon_from_name("read"))
	ReadOnly.set("custom_icons/unchecked",IconLoader.load_icon_from_name("edit"))
	
	add_to_group("vanilla_editor")

func set_wrap_enabled(enabled:bool):
	TextEditor.set_wrap_enabled(enabled)
	TextEditor.update()

func draw_minimap(value:bool):
	TextEditor.draw_minimap(value)
	TextEditor.update()

func color_region(filextension : String): # -----------------------------> dal momento che voglio creare un editor per ogni file, renderò questa funzione singola in base all'estensione del file
	match(filextension):
		"bbs":
			TextEditor.add_color_region("[b]","[/b]",Color8(153,153,255,255),false)
			TextEditor.add_color_region("[i]","[/i]",Color8(153,255,153,255),false)
			TextEditor.add_color_region("[s]","[/s]",Color8(255,153,153,255),false)
			TextEditor.add_color_region("[u]","[/u]",Color8(255,255,102,255),false)
			TextEditor.add_color_region("[url","[/url]",Color8(153,204,255,255),false)
			TextEditor.add_color_region("[code]","[/code]",Color8(192,192,192,255),false)
			TextEditor.add_color_region("[img]","[/img]",Color8(255,204,153,255),false)
			TextEditor.add_color_region("[center]","[/center]",Color8(175,238,238,255),false)
			TextEditor.add_color_region("[right]","[/right]",Color8(135,206,235,255),false)
		"html":
			TextEditor.add_color_region("<b>","</b>",Color8(153,153,255,255),false)
			TextEditor.add_color_region("<i>","</i>",Color8(153,255,153,255),false)
			TextEditor.add_color_region("<del>","</del>",Color8(255,153,153,255),false)
			TextEditor.add_color_region("<ins>","</ins>",Color8(255,255,102,255),false)
			TextEditor.add_color_region("<a","</a>",Color8(153,204,255,255),false)
			TextEditor.add_color_region("<img","/>",Color8(255,204,153,255),true)
			TextEditor.add_color_region("<pre>","</pre>",Color8(192,192,192,255),false)
			TextEditor.add_color_region("<center>","</center>",Color8(175,238,238,255),false)
			TextEditor.add_color_region("<right>","</right>",Color8(135,206,235,255),false)
		"md":
			TextEditor.add_color_region("***","***",Color8(126,186,181,255),false)
			TextEditor.add_color_region("**","**",Color8(153,153,255,255),false)
			TextEditor.add_color_region("*","*",Color8(153,255,153,255),false)
			TextEditor.add_color_region("+ ","",Color8(255,178,102,255),false)
			TextEditor.add_color_region("- ","",Color8(255,178,102,255),false)
			TextEditor.add_color_region("~~","~~",Color8(255,153,153,255),false)
			TextEditor.add_color_region("__","__",Color8(255,255,102,255),false)
			TextEditor.add_color_region("[",")",Color8(153,204,255,255),false)
			TextEditor.add_color_region("`","`",Color8(192,192,192,255),false)
			TextEditor.add_color_region('"*.','"',Color8(255,255,255,255),true)
			TextEditor.add_color_region("# ","",Color8(105,105,105,255),true)
			TextEditor.add_color_region("## ","",Color8(128,128,128,255),true)
			TextEditor.add_color_region("### ","",Color8(169,169,169,255),true)
			TextEditor.add_color_region("#### ","",Color8(192,192,192,255),true)
			TextEditor.add_color_region("##### ","",Color8(211,211,211,255),true)
			TextEditor.add_color_region("###### ","",Color8(255,255,255,255),true)
			TextEditor.add_color_region("> ","",Color8(172,138,79,255),true)
		"cfg":
			TextEditor.add_color_region("[","]",Color8(153,204,255,255),false)
			TextEditor.add_color_region('"','"',Color8(255,255,102,255),false)
			TextEditor.add_color_region(';','',Color8(128,128,128,255),true)
		"ini":
			TextEditor.add_color_region("[","]",Color8(153,204,255,255),false)
			TextEditor.add_color_region('"','"',Color8(255,255,102,255),false)
			TextEditor.add_color_region(';','',Color8(128,128,128,255),true)
		_:
			pass

func clean_editor():
	TextEditor.set_text("")
	LastModifiedIcon.texture = IconLoader.load_icon_from_name("save")
	LastModified.set_text("")
	FileList.invalidate()
	current_filename = ""
	current_path = ""

func new_file_open(file_content : String, last_modified : Dictionary, current_file_path : String):
	current_path = current_file_path
	current_filename = current_file_path.get_file()
	color_region(current_filename.get_extension())
	TextEditor.set_text(file_content)
	update_lastmodified(last_modified,"save")
	FileList.invalidate()
	count_characters()

func update_lastmodified(last_modified : Dictionary, icon : String):
	LastModified.set_text(str(last_modified.hour)+":"+str(last_modified.minute)+"  "+str(last_modified.day)+"/"+str(last_modified.month)+"/"+str(last_modified.year))
	LastModifiedIcon.texture = IconLoader.load_icon_from_name(icon)

func new_file_create(file_name):
	TextEditor.set_text("")
	
	FileList.invalidate()

func _on_Readonly_toggled(button_pressed):
	if button_pressed:
		ReadOnly.set_text("Read Only")
		TextEditor.readonly = (true)
	else:
		ReadOnly.set_text("Can Edit")
		TextEditor.readonly = (false)

func _on_TextEditor_text_changed():
	LastModifiedIcon.texture = IconLoader.load_icon_from_name("saveas")
	count_characters()
	emit_signal("text_changed")

func count_characters():
	var counted : int = 0
	for line in TextEditor.get_line_count():
		counted += TextEditor.get_line(line).length()
	c_counter.set_text(str(counted))

func _on_LineEdit_text_changed(new_text):
	var linecount = TextEditor.get_line_count()
	if new_text != "":
		var found
		var find = false
		for line in range(0,linecount):
			for column in range(0,TextEditor.get_line(line).length()):
				found = TextEditor.search( new_text, search_flag, line , column )
				if found.size():
					if found[1] == line:
#						if not find:
						TextEditor.select(line,found[0],found[1],found[0]+new_text.length())
#							find = true
				else:
					TextEditor.select(0,0,0,0)
	else:
		TextEditor.select(0,0,0,0)

func _on_matchcase_toggled(button_pressed):
	if button_pressed:
		search_flag = 1
	else:
		if $SearchBox/wholewords.is_pressed():
			search_flag = 2
		else:
			search_flag = 0
	_on_LineEdit_text_changed($SearchBox/LineEdit.get_text())

func _on_wholewords_toggled(button_pressed):
	if button_pressed:
		search_flag = 2
	else:
		if $SearchBox/matchcase.is_pressed():
			search_flag = 1
		else:
			search_flag = 0
	_on_LineEdit_text_changed($SearchBox/LineEdit.get_text())

func _on_close_pressed():
	SearchBox.hide()

func open_searchbox():
	if SearchBox.visible:
		SearchBox.hide()
	else:
		SearchBox.show()
		SearchBox.get_node("LineEdit").grab_focus()

func _on_Button_pressed():
	var linecount = TextEditor.get_line_count()-1
	var old_text = $ReplaceBox/replace.get_text()
	var new_text = $ReplaceBox/with.get_text()
	var text = TextEditor.get_text()
	TextEditor.set_text(text.replace(old_text,new_text))

func open_replacebox():
	if ReplaceBox.visible:
		ReplaceBox.hide()
	else:
		ReplaceBox.show()
		ReplaceBox.get_node("replace").grab_focus()

func _on_close2_pressed():
	ReplaceBox.hide()

func _on_LineEdit_focus_entered():
	_on_LineEdit_text_changed($SearchBox/LineEdit.get_text())
