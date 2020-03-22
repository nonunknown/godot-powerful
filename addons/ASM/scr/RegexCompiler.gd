class_name RegexCompiler

static func do_search():
	var now = OS.get_ticks_msec()
	var scr = load("res://addons/ASM/base/base_scr.gd")
	print(scr.has_method("st_init_sname"))
	var methods = scr.get_script_method_list()
	for method in methods:
		print(method.name)
#	var methods_to_check = ""
	#range start in 70 cuz there are basic methods unnecessary to read
#	var s:String = "st_init_idle()/st_update_idle()"
#	var compile:String = "st_(init|update|exit)_(idle|walk)"
#	var regex:RegEx = RegEx.new()
#	regex.compile(compile)
#	for result in regex.search_all(methods_to_check):
#		if result:
#			print(result.get_string())
#		else:
#			print("no match")
	now = OS.get_ticks_msec() - now
	print("done in"+str(now)+"msec")
