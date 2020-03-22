tool
extends Spatial
class_name Label3D

export(String, MULTILINE) var text = "Text" setget set_text
export(float) var text_scale = 0.01 setget set_text_scale
export(float) var extrude = 0.0 setget set_extrude
export(Font) var font setget set_font;

export(int, "Left", "Right", "Center", "Fill") var align setget set_align

export(Color) var color = Color(0.6, 0.6, 0.6) setget set_color
export(float, 0, 1) var metallic = 0.0 setget set_metallic
export(float, 0, 1) var roughness = 0.5 setget set_roughness

export(int) var max_steps = 256 setget set_max_steps
export(float) var step_size = 1.0 setget set_step_size

var label
var viewport
var proxy
var material

func _ready():
	for i in range(get_child_count()):
		remove_child(get_child(0))
	
	viewport = preload("text_viewport.tscn").instance()
	label = viewport.get_node("Label")
	add_child(viewport)
	
	proxy = MeshInstance.new()
	proxy.mesh = CubeMesh.new()
	proxy.material_override = preload("label_3d.material").duplicate()
	material = proxy.material_override
	
	var view_texture = viewport.get_texture()
	view_texture.flags = Texture.FLAG_FILTER
	material.set_shader_param("text", view_texture)
	add_child(proxy)
	
	set_align(align)
	set_font(font)
	set_text(text)
	set_text_scale(text_scale)
	set_extrude(extrude)
	
	set_color(color)
	set_metallic(metallic)
	set_roughness(roughness)
	
	set_max_steps(max_steps)
	set_step_size(step_size)


func set_text(string):
	text = string;
	if label:
		label.text = text
		label.rect_size = Vector2()
		label.force_update_transform()
		
		var size = label.rect_size
		viewport.size = size
		
		viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
		yield(get_tree(), "idle_frame")
		
		label.rect_size = Vector2()
		label.force_update_transform()
		
		size = label.rect_size
		viewport.size = size
		
		yield(get_tree(), "idle_frame")
		viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
		
		proxy.scale.x = size.x * text_scale
		proxy.scale.y = size.y * text_scale

func set_text_scale(scale):
	text_scale = scale
	if label:
		var size = label.rect_size
		if proxy:
			proxy.scale.x = size.x * text_scale
			proxy.scale.y = size.y * text_scale

func set_extrude(ext):
	extrude = ext
	
	if proxy:
		proxy.scale.z = extrude if extrude != 0 else 1
		material.set_shader_param("extrude", extrude != 0)
		
		if extrude == 0 and proxy.mesh is CubeMesh:
			proxy.mesh = QuadMesh.new()
			proxy.mesh.size = Vector2(2, 2)
		elif proxy.mesh is QuadMesh:
			proxy.mesh = CubeMesh.new()

func set_font(f):
	font = f
	if label:
		if font:
			label.add_font_override("font", font)
		else:
			label.add_font_override("font", preload("default_font.tres"))
		set_text(text)

func set_align(al):
	align = al
	if label:
		match align:
			0:
				label.align = Label.ALIGN_LEFT
			1:
				label.align = Label.ALIGN_RIGHT
			2:
				label.align = Label.ALIGN_CENTER
			3:
				label.align = Label.ALIGN_FILL
	
	set_text(text)

func set_color(col):
	color = col
	if material:
		material.set_shader_param("albedo", color)

func set_metallic(metal):
	metallic = metal
	if material:
		material.set_shader_param("metallic", metallic)

func set_roughness(rough):
	roughness = rough
	if material:
		material.set_shader_param("roughness", roughness)

func set_max_steps(max_s):
	max_steps = max(max_s, 8)
	if material:
		material.set_shader_param("maxSteps", max_steps)

func set_step_size(step_s):
	step_size = max(step_s, 0)
	if material:
		material.set_shader_param("stepSize", step_size)
