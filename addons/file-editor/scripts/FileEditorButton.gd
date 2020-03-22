tool
extends ToolButton

var fileditor_workspace
var fileditor

func _ready():
	connect("pressed",self,"show_fileditor")

func show_fileditor():
	fileditor_workspace.get_children()[0].hide()
	fileditor_workspace.get_children()[1].hide()
	fileditor_workspace.get_children()[2].hide()
	fileditor_workspace.add_child(fileditor)
	fileditor.show()

func load_values(fi, fe):
	fileditor_workspace = fi
	fileditor = fe
