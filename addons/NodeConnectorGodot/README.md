# NodeConnectorGodot
Plugin for the Godot editor that provides a convenient way to connect a bunch of UI elements to a script.

For each of the selected nodes it adds a line to your scene's script like:

`onready var button = find_node("Button");`

Will also add a signal handle for Buttons and TextEdit nodes for their "pressed" and "text_changed" events.

### Demo:

![Gif Demo](demo.gif)


Note: There is one annoyance, that when modifying an existing script Godot doesn't pickup the changes until you unfocus Godot and reopen it.

Icon made by [Freepik](https://www.flaticon.com/authors/freepik) from www.flaticon.com


### How to install:
Once downloaded to your project, create a folder named 'addons' if necessary, then inside 'addons'
create a folder for this plugin ('node-connector' is a good name), move the 'plugin.gd'
script into that directory, under Project Settings > Plugins find the plugin titled 'NodeConnector'
and switch its state to Active.

Alternatively if you use git you could add this plugin as a submodule in the folder mentioned above.

Ex. `git submodule add https://github.com/Rybadour/NodeConnectorGodot.git addons/node-connector`
