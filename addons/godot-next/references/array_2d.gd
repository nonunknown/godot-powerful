# Array2D
# author: willnationsdev
# brief_description: A 2D Array class
extends Reference
class_name Array2D

##### SIGNALS #####

##### CONSTANTS #####

##### PROPERTIES #####

var data: Array = []

##### NOTIFICATIONS #####

func _init(p_array: Array = []):
	data = p_array

##### OVERRIDES #####

##### VIRTUAL METHODS #####

##### PUBLIC METHODS #####

func has_cell(p_row: int, p_col: int) -> bool:
	return len(data) > p_row and len(data[p_row]) > p_col

func set_cell(p_row: int, p_col: int, p_value):
	assert(has_cell(p_row, p_col))
	data[p_row][p_col] = p_value

func get_cell(p_row: int, p_col: int):
	assert(has_cell(p_row, p_col))
	return data[p_row][p_col]

func set_cell_if_exists(p_row: int, p_col: int, p_value) -> bool:
	if has_cell(p_row, p_col):
		set_cell(p_row, p_col, p_value)
		return true
	return false

func has_cellv(p_pos: Vector2) -> bool:
	return len(data) > p_pos.x and len(data[p_pos.x]) > p_pos.y

func set_cellv(p_pos: Vector2, p_value):
	assert(has_cellv(p_pos))
	data[p_pos.x][p_pos.y] = p_value

func get_cellv(p_pos: Vector2):
	assert(has_cellv(p_pos))
	return data[p_pos.x][p_pos.y]

func set_cellv_if_exists(p_pos: Vector2, p_value) -> bool:
	if has_cellv(p_pos):
		set_cellv(p_pos, p_value)
		return true
	return false

func get_row(p_idx: int):
	assert(len(data) > p_idx)
	assert(p_idx >= 0)
	return data[p_idx].duplicate()

func get_col(p_idx: int):
	var result = []
	for a_row in data:
		assert(len(a_row) > p_idx)
		assert(p_idx >= 0)
		result.push_back(a_row[p_idx])
	return result

func get_row_ref(p_idx: int):
	assert(len(data) > p_idx)
	assert(p_idx >= 0)
	return data[p_idx]

func get_rows() -> Array:
	return data

func set_row(p_idx: int, p_row):
	assert(len(data) > p_idx)
	assert(p_idx >= 0)
	assert(len(data) == len(p_row))
	data[p_idx] = p_row

func set_col(p_idx: int, p_col):
	assert(len(data) > 0 and len(data[0]) > 0)
	assert(len(data) == len(p_col))
	var idx = 0
	for a_row in data:
		assert(len(a_row) > p_idx)
		assert(p_idx >= 0)
		a_row[p_idx] = p_col[idx]
		idx += 1

func insert_row(p_idx: int, p_array: Array):
	if p_idx < 0:
		data.append(p_array)
	else:
		data.insert(p_idx, p_array)

func insert_col(p_idx: int, p_array: Array):
	var idx = 0
	for a_row in data:
		if p_idx < 0:
			a_row.append(p_array[idx])
		else:
			a_row.insert(p_idx, p_array[idx])
		idx += 1

func append_row(p_array: Array):
	insert_row(-1, p_array)

func append_col(p_array: Array):
	insert_col(-1, p_array)

func sort_row(p_idx: int):
	_sort_axis(p_idx, true)

func sort_col(p_idx: int):
	_sort_axis(p_idx, false)

func sort_row_custom(p_idx: int, p_obj: Object, p_func: String):
	_sort_axis_custom(p_idx, true, p_obj, p_func)

func sort_col_custom(p_idx: int, p_obj: Object, p_func: String):
	_sort_axis_custom(p_idx, false, p_obj, p_func)

func duplicate() -> Array2D:
	return (load(get_script().resource_path) as GDScript).new(data.duplicate()) as Array2D

func hash() -> int:
	return hash(self)

func shuffle():
	for a_row in data:
		a_row.shuffle()

func empty() -> bool:
	return len(data) == 0

func size() -> int:
	if len(data) <= 0:
		return 0
	return len(data) * len(data[0])

func resize(p_height: int, p_width: int):
	data.resize(p_height)
	for i in range(len(data)):
		data[i] = []
		data[i].resize(p_width)

func resizev(p_dimensions: Vector2):
	resize(int(p_dimensions.x), int(p_dimensions.y))

func clear():
	data = []

func fill(p_value):
	for a_row in range(data.size()):
		for a_col in range(data[a_row].size()):
			data[a_row][a_col] = p_value

func fill_row(p_idx: int, p_value):
	assert(p_idx >= 0)
	assert(len(data) > p_idx)
	assert(len(data[0]) > 0)
	var arr = []
	for i in len(data[0]):
		arr.push_back(p_value)
	data[p_idx] = arr

func fill_col(p_idx: int, p_value):
	assert(p_idx >= 0)
	assert(len(data) > 0)
	assert(len(data[0]) > p_idx)
	var arr = []
	for i in len(data):
		arr.push_back(p_value)
	set_col(p_idx, arr)

func remove_row(p_idx: int):
	assert(p_idx >= 0)
	assert(len(data) > p_idx)
	data.remove(p_idx)

func remove_col(p_idx: int):
	assert(len(data) > 0)
	assert(p_idx >= 0 and len(data[0]) > p_idx)
	for a_row in data:
		a_row.remove(p_idx)

func count(p_value) -> int:
	var count = 0
	for a_row in data:
		for a_col in a_row:
			if p_value == data[a_row][a_col]:
				count += 1
	return count

func has(p_value) -> bool:
	for a_row in data:
		for a_col in a_row:
			if p_value == data[a_row][a_col]:
				return true
	return false

func invert() -> Array2D:
	data.invert()
	return self

func invert_row(p_idx: int) -> Array2D:
	assert(p_idx >= 0 and len(data) > p_idx)
	data[p_idx].invert()
	return self

func invert_col(p_idx: int) -> Array2D:
	assert(len(data) > 0)
	assert(p_idx >= 0 and len(data[0]) > p_idx)
	var col = get_col(p_idx)
	col.invert()
	set_col(p_idx, col)
	return self

func bsearch_row(p_idx: int, p_value, p_before: bool) -> int:
	assert(p_idx >= 0 and len(data) > p_idx)
	return data[p_idx].bsearch(p_value, p_before)

func bsearch_col(p_idx: int, p_value, p_before: bool) -> int:
	assert(len(data) > 0)
	assert(p_idx >= 0 and len(data[0]) > p_idx)
	var col = get_col(p_idx)
	col.sort()
	return col[p_idx].bsearch(p_value, p_before)

func find(p_value) -> Vector2:
	for a_row in data:
		for a_col in a_row:
			if p_value == data[a_row][a_col]:
				return Vector2(a_row, a_col)
	return Vector2(-1, -1)

func rfind(p_value) -> Vector2:
	var i: int = len(data) - 1
	var j: int = len(data[0]) - 1
	while i:
		while j:
			if p_value == data[i][j]:
				return Vector2(i, j)
			j -= 1
		i -= 1
	return Vector2(-1, -1)

func transpose() -> Array2D:
	var array = (load(get_script().resource_path) as GDScript).new() as Array2D
	array.resize(len(data), len(data[0]))
	for i in range(len(data[0])):
		array.append_row(get_col(i))
	return array

##### CONNECTIONS #####

##### PRIVATE METHODS #####

func _sort_axis(p_idx: int, p_is_row: bool):
	if p_is_row:
		data[p_idx].sort()
		return
	var col = get_col(p_idx)
	col.sort()
	set_col(p_idx, col)

func _sort_axis_custom(p_idx: int, p_is_row: bool, p_obj: Object, p_func: String):
	if p_is_row:
		data[p_idx].sort_custom(p_obj, p_func)
		return
	var col = get_col(p_idx)
	col.sort_custom(p_obj, p_func)
	set_col(p_idx, col)
