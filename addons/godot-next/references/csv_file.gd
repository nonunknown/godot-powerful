# CSVFile
# author: willnationsdev
# brief_description: Provides utilities for loading, saving, and editing CSV files.
# dependencies: Array2D
# API details:
# - The data is stored internally as an Array2D. The 0th row is the headers.
# - Use 'get_array()' to fetch the Array2D
# - Use 'get_headers()' to get a Dictionary of the headers (values are their index in the first row)
# - Use 'get_map()' to get a Dictionary of string keys to rows.
#     - if '_uses_map' is true, the key will be generated from the '_get_key()' virtual method (defaults to returning row[0]).
#       Else _map will be empty. Defaults to false.
#     - The CSVFile object dynamically generates properties that match the keys of the _map Dictionary.
# - A .tsv file can be made simply by changing the '_sep' property to "\t".
tool
extends Reference
class_name CSVFile

##### SIGNALS #####

signal file_loaded(p_filepath)
signal file_saved(p_filepath)

##### CONSTANTS #####

const DEFAULT_SEP = ","
const DEFAULT_QUOTE = "\""

##### PROPERTIES #####

var _filepath := ""

var _array := Array2D.new()
var _headers := {}
var _map := {}

var _sep := DEFAULT_SEP
var _quote := DEFAULT_QUOTE
var _uses_map := true

##### NOTIFICATIONS #####

func _init(p_sep: String = DEFAULT_SEP, p_quote: String = DEFAULT_QUOTE, p_uses_map: bool = true):
	_sep = p_sep
	_quote = p_quote
	_uses_map = p_uses_map

func _get(p_property):
	if _map.has(p_property):
		return _map[p_property]

func _set(p_property, p_value):
	if _map.has(p_property):
		_map[p_property] = p_value

func _get_property_list():
	var ret := []
	for a_key in _map:
		ret.append({
			"name": a_key,
			"type": typeof(_map[a_key])
		})
	return ret

##### VIRTUAL METHODS #####

func _get_key(p_row: Array) -> String:
	if not p_row:
		return ""
	return p_row[0]

##### OVERRIDES #####

##### PUBLIC METHODS #####

func load(p_filepath: String) -> int:
	var f = File.new()
	var err = f.open(p_filepath, File.READ)
	if err != OK:
		return err
	_headers.clear()
	_map.clear()
	_array.clear()
	
	var headers = _parse_line(f.get_line())
	_array.append_row(headers)
	for i in range(headers.size()):
		_headers[headers[i]] = i
	
	if not _uses_map:
		for a_header in _headers:
			_map[a_header] = []
	
	#warning-ignore:unused_variable
	var line: String
	while not f.eof_reached():
		var row = _parse_line(f.get_line())
		if _uses_map:
			_map[_get_key(row)] = row
		_array.append_row(row)
	
	f.close()
	_filepath = p_filepath
	emit_signal("file_loaded", p_filepath)
	return OK

func save(p_filepath: String) -> int:
	var f := File.new()
	var err := f.open(p_filepath, File.WRITE)
	if err != OK:
		return err
	for a_row in _array.data:
		var strings := PoolStringArray()
		for a_cell in a_row:
			var text := str(a_cell)
			text = text.replace(_quote, _quote + _quote)
			if text.find(_sep) != -1:
				text = _quote + text + _quote
			strings.push_back(text)
		f.store_line(strings.join(_sep))
	f.close()
	emit_signal("file_saved", p_filepath)
	return OK

func get_headers() -> Dictionary:
	return _headers

func get_map() -> Dictionary:
	return _map

func get_array2d() -> Array2D:
	return _array

func map_has_value(p_key: String, p_header: String) -> bool:
	return _map.has(p_key) and _headers.has(p_header)

func map_get_value(p_key: String, p_header: String):
	if not _uses_map:
		printerr("CSVFile is not using map, but 'get_map_value' was called")
		return null
	if not map_has_value(p_key, p_header):
		return null
	return _map[p_key][_headers[p_header]]

func map_set_value(p_key: String, p_header: String, p_value):
	if not _uses_map:
		printerr("CSVFile is not using map, but 'get_map_value' was called")
		return null
	if not map_has_value(p_key, p_header):
		return null
	_map[p_key][_headers[p_header]] = p_value

##### PRIVATE METHODS #####

func _parse_line(p_line: String) -> Array:
	if not p_line:
		return []
	
	var ret := []
	var val := ""
	
	var in_quotes := false
	var start_collect_char := false
	var double_quotes_in_column := false
	
	var chars := p_line.to_utf8()
	for a_char in chars:
		var s := char(a_char)
		if in_quotes:
			start_collect_char = true
			if s == _sep:
				in_quotes = false
				double_quotes_in_column = false
			else:
				if s == "\"":
					if not double_quotes_in_column:
						val += s
						double_quotes_in_column = true
				else:
					val += s
		else:
			if s == _quote:
				in_quotes = true
				
				if p_line[0] != "\"" and _quote == "\"":
					val += "\""
				
				if start_collect_char:
					val += "\""
			elif s == _sep:
				ret.append(val)
				val = ""
				start_collect_char = false
			elif s == "\r":
				continue
			elif s == "\n":
				break
			else:
				val += s
	ret.append(val)
	return ret

##### SETTERS AND GETTERS #####
