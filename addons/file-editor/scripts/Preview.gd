tool
extends WindowDialog

var IconLoader = preload("res://addons/file-editor/scripts/IconLoader.gd").new()
var LastOpenedFiles = preload("res://addons/file-editor/scripts/LastOpenedFiles.gd").new()

onready var TextPreview = $Container/TextPreview
onready var TablePreview = $Container/TablePreview

signal image_downloaded()
signal image_loaded()

var imgBuffer : Image

func _ready():
	TextPreview.hide()
	TablePreview.hide()

func print_preview(content : String):
	TextPreview.append_bbcode(content)
	TextPreview.show()

func print_bb(content : String):
	TextPreview.append_bbcode(content)
	TextPreview.show()

func print_markdown(content : String):
	var result = ""
	var bolded = []
	var italics = []
	var striked = []
	var coded = []
	var linknames = []
	var images = []
	var links = []
	var lists = []
	var underlined = []
	
	var regex = RegEx.new()
	regex.compile('\\*\\*(?<boldtext>.*)\\*\\*')
	result = regex.search_all(content)
	if result:
		for res in result:
			bolded.append(res.get_string("boldtext"))
	
	regex.compile('\\_\\_(?<underlinetext>.*)\\_\\_')
	result = regex.search_all(content)
	if result:
		for res in result:
			underlined.append(res.get_string("underlinetext"))
	
	regex.compile("\\*(?<italictext>.*)\\*")
	result = regex.search_all(content)
	if result:
		for res in result:
			italics.append(res.get_string("italictext"))
	
	regex.compile("~~(?<strikedtext>.*)~~")
	result = regex.search_all(content)
	if result:
		for res in result:
			striked.append(res.get_string("strikedtext"))
	
	regex.compile("`(?<coded>.*)`")
	result = regex.search_all(content)
	if result:
		for res in result:
			coded.append(res.get_string("coded"))
	
	regex.compile("[+-*](?<element>\\s.*)")
	result = regex.search_all(content)
	if result:
		for res in result:
			lists.append(res.get_string("element"))
	
	regex.compile("(?<img>!\\[.*?\\))")
	result = regex.search_all(content)
	if result:
		for res in result:
			images.append(res.get_string("img"))
	
	regex.compile("\\[(?<linkname>.*?)\\]|\\((?<link>[h\\.]\\S*?)\\)")
	result = regex.search_all(content)
	if result:
		for res in result:
			if res.get_string("link")!="":
				links.append(res.get_string("link"))
			if res.get_string("linkname")!="":
				linknames.append(res.get_string("linkname"))
	
	for bold in bolded:
		content = content.replace("**"+bold+"**","[b]"+bold+"[/b]")
	for italic in italics:
		content = content.replace("*"+italic+"*","[i]"+italic+"[/i]")
	for strik in striked:
		content = content.replace("~~"+strik+"~~","[s]"+strik+"[/s]")
	for underline in underlined:
		content = content.replace("__"+underline+"__","[u]"+underline+"[/u]")
	for code in coded:
		content = content.replace("`"+code+"`","[code]"+code+"[/code]")
	for image in images:
		var substr = image.split("(")
		var imglink = substr[1].rstrip(")")
		content = content.replace(image,"[img]"+imglink+"[/img]")
	for i in links.size():
		content = content.replace("["+linknames[i]+"]("+links[i]+")","[url="+links[i]+"]"+linknames[i]+"[/url]")
	for element in lists:
		if content.find("- "+element):
			content = content.replace("-"+element,"[indent]-"+element+"[/indent]")
		if content.find("+ "+element):
			content = content.replace("+"+element,"[indent]-"+element+"[/indent]")
		if content.find("* "+element):
			content = content.replace("+"+element,"[indent]-"+element+"[/indent]")
	
	TextPreview.append_bbcode(content)
	TextPreview.show()

func print_html(content : String):
	content = content.replace("<i>","[i]")
	content = content.replace("</i>","[/i]")
	content = content.replace("<b>","[b]")
	content = content.replace("</b>","[/b]")
	content = content.replace("<u>","[u]")
	content = content.replace("</u>","[/u]")
	content = content.replace("<ins>","[u]")
	content = content.replace("</ins>","[/u]")
	content = content.replace("<del>","[s]")
	content = content.replace("</del>","[/s]")
	content = content.replace('<a href="',"[url=")
	content = content.replace('">',"]")
	content = content.replace("</a>","[/url]")
	content = content.replace('<img src="',"[img]")
	content = content.replace('" />',"[/img]")
	content = content.replace('"/>',"[/img]")
	content = content.replace("<pre>","[code]")
	content = content.replace("</pre>","[/code]")
	content = content.replace("<center>","[center]")
	content = content.replace("</center>","[/center]")
	content = content.replace("<right>","[right]")
	content = content.replace("</right>","[/right]")
	
	TextPreview.append_bbcode(content)
	TextPreview.show()

func print_csv(rows : Array):
	TablePreview.columns = rows[0].size()
	for item in rows:
		for string in item:
			var label = Label.new()
			label.text = str(string)
			label.set_h_size_flags(SIZE_EXPAND)
			label.set_align(1)
			label.set_valign(1)
			TablePreview.add_child(label)
	
	
	TablePreview.show()

func _on_Preview_popup_hide():
	queue_free()
