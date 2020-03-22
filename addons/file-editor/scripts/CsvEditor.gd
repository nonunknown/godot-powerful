tool
extends Control

var IconLoader = preload("res://addons/file-editor/scripts/IconLoader.gd").new()
var LastOpenedFiles = preload("res://addons/file-editor/scripts/LastOpenedFiles.gd").new()

onready var Table = $Editor/TableContainer/ScrollContainer/Table
onready var AlignBTN = $Editor/Buttons/align_bt.get_popup()
onready var EditBTN = $Editor/Buttons/edit_bt.get_popup()
onready var FileInfo = $Editor/FileInfo
onready var ReadOnly = $Editor/FileInfo/Readonly

onready var Horizontal = $Editor/Horizontal
onready var Vertical = $Editor/TableContainer/Vertical

var current_file_path : String = ""

var rows : int 
var columns : int
var csv_delimiter : String
var filepath : String

signal update_file()

func _ready():
	add_to_group("csv_editor")
	connect_signals()
	
	load_icons()

func connect_signals():
	AlignBTN.connect("id_pressed",self,"on_align_pressed")
	EditBTN.connect("id_pressed",self,"on_edit_pressed")
	ReadOnly.connect("toggled",self,"_on_Readonly_toggled")

func load_icons():
	$Editor/Buttons/align_bt.set_button_icon(IconLoader.load_icon_from_name("align"))
	$Editor/Buttons/edit_bt.set_button_icon(IconLoader.load_icon_from_name("edit_"))
	
	AlignBTN.set_item_icon(0,IconLoader.load_icon_from_name("text-left"))
	AlignBTN.set_item_icon(1,IconLoader.load_icon_from_name("text-center"))
	AlignBTN.set_item_icon(2,IconLoader.load_icon_from_name("text-right"))
	AlignBTN.set_item_icon(3,IconLoader.load_icon_from_name("text-fill"))
	
	EditBTN.set_item_icon(0,IconLoader.load_icon_from_name("row"))
	EditBTN.set_item_icon(1,IconLoader.load_icon_from_name("column"))
	EditBTN.set_item_icon(3,IconLoader.load_icon_from_name("save"))
	
	ReadOnly.set("custom_icons/checked",IconLoader.load_icon_from_name("read"))
	ReadOnly.set("custom_icons/unchecked",IconLoader.load_icon_from_name("edit"))

func open_csv_file(filepath : String, csv_delimiter : String) -> void:
	self.filepath = filepath
	var csv = File.new()
	csv.open(filepath,File.READ)
	var rows : Array = []
	var columns = -1
	while not csv.eof_reached():
		rows.append(csv.get_csv_line(csv_delimiter))
		if columns == -1:
			columns = rows[0].size()
	csv.close()
	self.csv_delimiter = csv_delimiter
	load_file_in_table(rows,columns)
	ReadOnly.pressed = (true)
	$Editor/FileInfo/delimiter.set_text(csv_delimiter)

func load_file_in_table(rows : Array, columns : int) -> void:
	Table.set_columns(columns)
	for row in rows:
		add_row(row.size(),"",row)
	update_dimensions(rows.size()-1,columns)

func add_row(columns : int, cell_text : String = "", cell2text : PoolStringArray = []):
	for i in range(0,columns):
		if cell2text.size()<1:
			var cell = LineEdit.new()
			cell.set_h_size_flags(2)
			cell.set_h_size_flags(3)
			cell.set_text(cell_text)
			Table.add_child(cell)
			if ReadOnly.pressed:
				cell.set_editable(false)
		
		else: 
			if cell2text[i]!="":
				var cell = LineEdit.new()
				cell.set_h_size_flags(2)
				cell.set_h_size_flags(3)
				Table.add_child(cell)
				if cell2text:
					cell.set_text(cell2text[i])
				else:
					cell.set_text(cell_text)
				if ReadOnly.pressed:
					cell.set_editable(false)

func add_column(rows : int ,cell_text : String  = ""):
	for i in range(0,rows):
		var cell = LineEdit.new()
		cell.set_h_size_flags(2)
		cell.set_h_size_flags(3)
		Table.add_child(cell)
		Table.move_child(cell,(columns)*(i+1)-1)
		cell.set_text(cell_text)
		if ReadOnly.pressed:
			cell.set_editable(false)

func on_align_pressed(index : int) -> void:
	for cell in Table.get_children():
		cell.set_align(index)

func on_edit_pressed(index :int) -> void:
	match index:
		0:
			update_dimensions(rows+1,columns)
			add_row(columns)
		1:
			update_dimensions(rows,columns+1)
			add_column(rows)
		3:
			save_table()

func table_ruler(rows : int, columns : int):
	for child in Vertical.get_children():
		child.queue_free()
	for child in Horizontal.get_children():
		child.queue_free()
	for i in range(0,rows):
		var lb = Label.new()
		lb.set_h_size_flags(2)
		lb.set_h_size_flags(3)
		lb.set_text(str(i+1))
		Vertical.add_child(lb)
	var lb = Label.new()
	lb.set_text(" ")
	Horizontal.add_child(lb)
	for j in range(0,columns):
		var lb2 = Label.new()
		lb2.set_h_size_flags(2)
		lb2.set_h_size_flags(3)
		lb2.set_align(1)
		lb2.set_text(str(j+1))
		Horizontal.add_child(lb2)

func update_dimensions(rows : int, columns : int):
	self.rows = rows
	self.columns = columns
	table_ruler(rows,columns)
	Table.set_columns(columns)
	FileInfo.get_node("rows").set_text(str(rows))
	FileInfo.get_node("columns").set_text(str(columns))

func _on_Readonly_toggled(button_pressed):
	if button_pressed:
		ReadOnly.set_text("Read Only")
		for cell in Table.get_children():
			cell.set_editable(false)
	else:
		ReadOnly.set_text("Can Edit")
		for cell in Table.get_children():
			cell.set_editable(true)

func save_table():
	var content : Array = []
	var column = 0
	var row_ : PoolStringArray = []
	for cell in Table.get_children():
		if column < columns:
			row_.append(cell.get_text())
			column+=1
		else:
			content.append(row_)
			row_ = []
			row_.append(cell.get_text())
			column = 1
	content.append(row_)
	
	var file = File.new()
	file.open(filepath, File.WRITE)
	for line in content:
		file.store_csv_line(line,"|")
	file.close()
	
	emit_signal("update_file")
