# Use Cases

1. Have you ever wanted to have an overrideable print method in Objects?
    - Variant.to_string(value)
2. Have you ever wanted to get a type as a string, regardless of whether it's an Object (return `get_class()`), or a built-in, e.g. int (return "int")?
    - Variant.get_type(value)
3. Have you ever wanted multiple scripts per Node?
    - CallbackDelegator node + Behavior resources
    - Supply a "base_type" script or click to initialize the default one.
    - This CallbackDelegator has a private property of a new "ResourceSet" type; it's a collection of unique-script resource instances housing types which...
        1. can see the CallbackDelegator node as an 'owner' property.
        2. can be toggled on and off as an 'enabled' property.
        3. receive Node notification callbacks that have been delegated to them by the CallbackDelegator node.
    - This is much more efficient than simply having a large number of child nodes.
        1. Resources are more lightweight than scripts.
        2. One can directly save and load Resources from the filesystem.
        3. Better than nodes, one can expand each resource into its own sub-inspector within a single Inspector "view", viewing all the data at once.
4. Have you ever wanted to wrap an engine type, script type, or scene type under a single API?
    - ClassType
    - It stores a reference to a *type*. This means it can represent "Node" engine class, "MyNode" script class, anonymous scripts and anonymous scenes equally.
    - ClassType.new(<type>) functions with <type> being...
        - the string name of the class.
        - a reference to the script or scene.
        - a path to the script or scene.
        - an instance of an example object.
            - Supplying a Script or PackedScene will revert to the previous cases
            - Providing a Node that is the root of a scene will load that scene (since that is an approximation of the Node's type)
            - Providing an Object with a script will load that script (since that is the Object's type)
            - Providing an Object without a script will set the ClassType.name to be the Object.get_class() value
    - `.instance()` returns an instance of the type
    - `.get_type_class()` returns the string name of the type
    - `.get_type_parent()` returns a ClassType representing the base class of the type.
        - Anonymous script vs. named script doesn't matter. Uses `Script.get_base_script()`.
        - Also fetches base scene from a PackedScene instance
        - If there are no more inherited scenes, a PackedScene will defer first to the root node's script, then to the engine type of the root Node.
    - `.get_inheritors_list()` returns a list of the types' derived types.
    - The `res` property is the script or scene associated with the type. Therefore, one can get a script class by name with `ClassType.new("MyType").res`.
5. Have you ever wanted to search through your project folder and identify files which match certain criteria?
    - FileSearch
    - Has a variety of .search_<criteria>(p_param, p_starting_directory = "res://", p_do_a_recursive_search = true) methods
6. Have you ever wanted to create singletons that exist even in the editor context?
    - Singletons
    - This Reference type stores a static database of all Reference-derived types which can be fetched by their script.
    - `Singletons.fetch(MyType)` will return an instance of MyType and ensure that only one instance of it is managed by the Singletons database.
    - Can implement one's own static method which converts `Singletons.fetch(MyType)` to `MyType.fetch()`.
6. Have you ever wanted to send signals to child nodes, resources or even references but you don't want to define all the possible signals in the instance?
    - MessageDispatcher
    - Allows any object to register a function that handles a specific message_type.
    - Emit a message on the dispatcher and it sends it to all relevant handlers or discards it if no handlers were registered.
7. Have you ever wanted to create a flat gradient with hard transitions?
	- DiscreteGradientTexture
	- It works like the GradientTexture but ignores the color interpolation of the gradient.