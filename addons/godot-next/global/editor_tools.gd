# EditorTools
# author: willnationsdev
# brief_description: A utility for any features useful in the context of the Editor
tool
extends Reference
class_name EditorTools

static func is_in_edited_scene(p_node: Node):
    if not p_node.is_inside_tree():
        return false
    var edited_scene := p_node.get_tree().edited_scene_root
    if p_node == edited_scene:
        return true
    return edited_scene.is_parent_of(p_node)
