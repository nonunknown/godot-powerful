class_name GadgetQuat
extends GadgetVector4
tool

static func supports_type(value) -> bool:
	return value is Quat
