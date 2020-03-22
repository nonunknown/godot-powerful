# FileSystemLink
# author: willnationsdev
# brief_description: A utility for creating links (file/directory, symbolic/hard).
# API details:
# - All methods' parameters are ordered in Unix fashion, {<target>,<linkpath>}
# - Methods are aliased so that the parameters are implied by the method name.
extends Reference
class_name FileSystemLink

enum LinkTypes {
	SOFT,
	HARD
}

enum TargetTypes {
	FILE,
	DIR,
	WINDOWS_JUNCTION
}

static func mk_hard_file(p_target: String, p_linkpath: String = "") -> int:
	return _make_link(p_target, p_linkpath, TargetTypes.FILE, LinkTypes.HARD)

static func mk_soft_file(p_target: String, p_linkpath: String = "") -> int:
	return _make_link(p_target, p_linkpath, TargetTypes.FILE, LinkTypes.SOFT)

static func mk_hard_dir(p_target: String, p_linkpath: String = "") -> int:
	return _make_link(p_target, p_linkpath, TargetTypes.DIR, LinkTypes.HARD)

static func mk_soft_dir(p_target: String, p_linkpath: String = "") -> int:
	return _make_link(p_target, p_linkpath, TargetTypes.DIR, LinkTypes.SOFT)

static func mk_windows_junction(p_target: String, p_linkpath: String = "") -> int:
	return _make_link(p_target, p_linkpath, TargetTypes.WINDOWS_JUNCTION, LinkTypes.SOFT)

static func _make_link(p_target: String, p_linkpath: String = "", p_target_type = TargetTypes.FILE, p_link_type: int = LinkTypes.SOFT) -> int:
	var params := PoolStringArray()
	var dir := Directory.new()
	var output := []
	var target := ProjectSettings.globalize_path(p_target)
	var linkpath := ProjectSettings.globalize_path(p_linkpath)
	match p_target_type:
		TargetTypes.FILE:
			if not dir.file_exists(target):
				return ERR_FILE_NOT_FOUND
		TargetTypes.DIR, TargetTypes.WINDOWS_JUNCTION:
			if not dir.dir_exists(target):
				return ERR_FILE_NOT_FOUND
	match OS.get_name():
		"Windows":
			match p_link_type:
				LinkTypes.SOFT:
					pass
				LinkTypes.HARD:
					params.append("/H")
				_:
					printerr("Unknown link type passed to FileSystemLink.make_link: ", p_link_type)
					return ERR_INVALID_PARAMETER
			#warning-ignore:unreachable_code
			match p_target_type:
				TargetTypes.FILE:
					pass
				TargetTypes.DIR:
					params.append("/D")
				TargetTypes.WINDOWS_JUNCTION:
					params.append("/J")
				_:
					printerr("Unknown target type passed to FileSystemLink.make_link: ", p_target_type)
					return ERR_INVALID_PARAMETER

			params.append(linkpath)
			params.append(target)
			#warning-ignore:return_value_discarded
			OS.execute("mklink", params, true, output)
			return OK
		"X11", "OSX":
			match p_link_type:
				LinkTypes.SOFT:
					params.append("-s")
				LinkTypes.HARD:
					pass
				_:
					printerr("Unknown link type passed to FileSystemLink.make_link", p_link_type)
					return ERR_INVALID_PARAMETER
			
			match p_target_type:
				TargetTypes.FILE:
					pass
				TargetTypes.DIR:
					params.append("-d")
				TargetTypes.WINDOWS_JUNCTION:
					printerr("Junctions are a Windows feature")
					return ERR_INVALID_PARAMETER
				_:
					printerr("Unknown target type passed to FileSystemLink.make_link: ", p_target_type)
					return ERR_INVALID_PARAMETER

			params.append(target)
			params.append(linkpath)
			#warning-ignore:return_value_discarded
			OS.execute("ln", params, true, output)
			return OK
		_:
			return ERR_UNAVAILABLE
