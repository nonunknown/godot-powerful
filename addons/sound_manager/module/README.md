## SOUND MANAGER MODULE FOR GODOT 3.2
## Version 3.0
## © Xecestel 2019
## Licensed Under MPL 2.0 (see below)

This Sound Manager gives the users a better control over the audio of their games. Setting the SoundManager.tscn scene as an AutoLoad on the ProjectSettings it is possible to play every sound of the game using just simple method calls. No more long AudioStreamPlayer lists inside your scenes nor long method to handle the audio inside every script.
It also gives you a better control over the Background Music. With this script it will not stop between scenes anymore, giving you the power to stop it and play  it whenever and however you want.


## How does it work?
This script uses some methods (you can see them below) that basically replace the default AudioStreamPlayer methods for easier usage. The only thing you need is to place all your game's sounds and musics of the same type (sound effects, bgms, bgss, music effects) on the same directories.


## Configuration
To use this script you have to set the scene as an AutoLoad in the ProjectSettings/AutoLoad tab. Remember: you need to set as an AutoLoad the scene (.tscn file) not the script (.gd file).

Configure the script is pretty simple:
First things first: if loading the scene from your editor throws you dependency issue with the script, just fix it clicking on the little folder icon on the left and selecting the SoundManager.gd file from you project directory.
First of all, you have to tell the script where your files are located. To do so, the script exports three variables: `BGM_DIR_PATH`, `BGS_DIR_PATH`, `SFX_DIR_PATH`, `MFX_DIR_PATH`. Open the SoundManager scene on the Godot editor and use the property tab to select the directories. They can be wherever you want inside your project main directory.

At this point, you have to use the dictionary. It allows you to use different strings for method calls and for the file names. This way, even if your audio file is called "*sfx_audio_jump.ogg*", you can set it in the dictionary to call it as a simple "Jump", adding a simple row `"Jump" : "sfx_audio_jump.ogg"`. This way, whenever you want to play that particular audio file, you will just have to call `SoundManager.play_se("Jump")` and the script will do the rest. If you want to play a file that is not on the default audio directory, you can also use the absolute path as a value on the Dictionary (`"Jump" : "res://sfx_audio_jump_ogg"`).
The dictionary is located inside the SoundManager_config file. You can place it wherever you want inside your project directory.
You can also edit the dictionary file from inside the scene editor, by working on the custom property. On the dictionary there is a placeholder key-value pair to give you an hint on the formatting expected from Godot.
You can also play sounds using their file names or absolute path. So if you want to play, from the example above, `"sfx_audio_jump.ogg"` you can either call `play_se("Jump")`, `play_se("sfx_audio_jump.ogg")` or `play_se("res://Assets/Audio/sfx_audio_jump.ogg")`. If you want to populate the dictionary, to just change the file names to something easier to remember or just use absolute paths it's up to you!

There are also other two useful, more advanced, variables:
- "Preload Resources". It's a boolean variable: if you set it to true the module will automatically load every audio resource from the given paths at `_ready()`. Note that this will slow down game start (especially in projects with a long list of audio files) but will make it faster to play sounds. It's completely optional.
- "Preinstantiate nodes". It's another boolean variable: if it's set to true the module will instantiate every needed AudioStreamPlayer node from start. This will make playing multiple sounds at once much faster, but note that it may also slow down your game.

## Methods
The main methods of this script are just 12, three for each section of the script (Background Music, Background Sounds, Sound Effects and Music Effecs), plus some useful setters and getters.

### Main Methods
#### Background Music
The main methods are basically the same but with some differents for background musics (see below), the only difference between them in the method calls is the suffix on the name (`play_bgm` instead of `play_me` for example, or `is_bgm_playing` instead of `is_me_playing`). They can be summarized in three categories:

- `func play(audio : String, reset_to_defaults : bool = true) -> void`: this method lets you play the selected audio, passed as a string. If the audio is already playing, it won't do anything to avoid weird outcomes (or it will replace the previous one for BGMs). The `reset_to_defaults` argument lets you decide if you want the default values for the player property or not. It's useful if you often change volume and pitch (default value: `true`). Note that you can't use `play_bgm` to play a sound effect or music effect and vice versa.

- `func stop(audio : String = "") -> void`: this method lets you stop the stream from playing. The argument (default value: `""`) gives you the ability to tell the stream to stop only if a specific sound is playing. Note that you can't use `stop_bgm` to stop a sound effect or music effect and vice versa.

- `func is_playing(audio : String = "") -> bool`: this method returns `true` if the selected stream is plaing and `false` if not. The argument (default value: `""`) gives you the ability to check if is playing a specific audio file by passing its name. Note that you can't use `is_bgm_playing` to check on a sound effect or music effect and vice versa.

#### Music Effects, Sound Effects and Background Sounds
You can also play multiple music effects, multiple sound effects and multiple background sounds at once! This means that the methods to work with them are a little bit different in the method calls and require some more words:

- `func play(sound : String, reset_to_defaults : bool = true, override_current_sound : bool = true, sound_to_override : String = "") -> void`: this method is basically the same as the other `play` methods, but comes with some more arguments. `override_current_sound` is an optional boolean variable that allows you to tell the Sound Manager to just replace an already playing sound with a new one. The default value is `true`, but if you go with a `false` the Sound Manager will play the sound without stopping the others, simultaneously. If you go with `true`, however, you can also decide which sound you want to override, by adding the sound name in the optional `sound_to_override` argument. If you don't do that, the Sound Manager automatically overrides the main stream (the one that is already on the scene).

- `stop` and `is_playing` are basically te same as the other sections, they just work differently internally. Note that whenever a Sound Effect or a Background Sound stream player stops (besides the main one), it's deleted from the scene.

- All the getters and setters now require the sound name in order to work. This argument is however always optional: if you don't put any argument in the method call, they'll just assume you are referring to the main AudioStreamPlayer.

- The `get_playing` method now returns an Array of all the currently playing sounds.

### Getters and Setters
- `func set_volume_db(volume_db : float) -> void`: this method allows you to change the selected stream volume via script. `volume_db` is the volume in decibels. (`set_bgm_volume_db` for bgm)

- `func get_volume_db() -> float`: this method return the volume of the given stream. (`get_bgm_volume_db` for bgm)

- `func set_pitch_scale(pitch : float) -> void`: this method allows you to set the pitch scale of the selected stream via script. (`set_bgm_pitch_scale` for bgm)

- `func get_pitch_scale() -> float`: this method returns the pitch scale of the given stream. (`get_bgm_pitch_scale` for bgm)

- `func pause(paused : bool) -> void`: this method allows you to pause or unpause the selected stream. (`pause_bgm` for bgm)

- `func is_paused() -> bool)`: this method returns `true` if the selected stream is paused. (`is_bgm_paused` for bgm)

- `func get_playing() -> String`: this methods (one for each type of audio) return a String contaning the currently playing or last played bgm, bgs, se, or me. (`get_playing_bgm` for bgm)

- `func get_configuration_dictionary() -> Dictionary`: this method returns the configuration dictionary as the user configured it.

- `func get_config_value(stream_name : String) -> String`: this method returns the file name of the given stream name. Returns `null` if an error occured.

- `func set_config_key(new_stream_name : String, new_stream_file : String) -> void`: this method allows the user to edit an existng value on the configuration dictionary, or add a new one in runtime. `new_stream_name` is the name of your choice for the stream (the key in the dictionary), while `new_stream_file` is the name of the file linked to it (the value in the dictionary).

- `func add_to_dictionary(audio_name : String, audio_file : String) -> void`: this method allows you to add a new voice to the dictionary in real time. `audio_name` is the name which you are going to call the audio with (the key in the Dictionary). `audio_file` is the file you want to play. It can be the file name (if the file is in the default audio dir path), or the absolute path for the file.


### Resource Preloading
There are also some useful methods to manage resource preloading:

- `func preload_resources_from_list(files_list : Array) -> void`: this method allows you to preload only a specific list of audio files. The content of the `files_list` array must be a recognizable sound name String, such as an absolute path, a file name, a sound name stored on the `Audio_Files_Dictionary` or even an already loaded sound `Resource`. This method is especially useful when you want to preload only certain sounds and not all of them, maybe because you know you will need them on the specific scene you're programming. Note that if the `Preload Resources` variable is enabled, this method will do nothing.

- `func preload_resources_from_dir(path : String) -> void`: this method lets you preload every audio file located in a specific directory (passed via the `path` string argument). This is especially useful if you are using a different folder from the standard directory that you set on the dock for some audio files and want to preload them too without having to write a full list of files. This can be used alongside the automatic preload process.

- `func preload_resource(file : Resource) -> void`: this is mainly an internal method, but in any case you can still use it to preload a specific file. The `file` argument must be an already loaded sound `Resource`. You can basically see this method as a way to store a loaded resource to use it on the Sound Manager as you please. The module will store this variable linking it to the file name as it would do with any other preloaded resource, so to play the sound you just have to use the file name or the sound name you used on the Audio Files Dictionary.

- `func preload_resource_from_string(file : String) -> void`: this is mainly an internal method, but in any case you can still use it to preload a specific file. For the `file` string argument rules, read the above rules about `files_list` array rules. Although this method exists and can be used, it's probably better to use the `preload_resources_from_list` method for almost any uses of this feature.

- `func unload_all_resources(force_unload : bool = false) -> void`: this method allows you to unload every previously preloaded audio file. It's especially useful when used in combo with the `preload_resources_from_list` to unload at the end of a scene any resource you loaded at the start of the scene. The `force_unload` argument (default: `false`) will let you unload preloaded resources even if the `Preload Resources` variable is set to on. Note that this will unload **all** preloaded resources, so it basically overrides the `Preload Resources` feature. If the `force_unload` argument is set to off, however, the method will do nothing if called while `Preload Resources` is on.

- `func unload_resources_from_list(files_list : Array) -> void`: this method allows you to pass a list of preloaded resources you want to unload. The files have to be Strings, but can be passed in any format (absolute path, file name, sound name). Note that thay can't be loaded Resources (why are you passing a loaded Resource if you want to unload it in the first place?)

- `func unload_resource_from_string(file : String) -> void`: this method allows you to unload a previously loaded resource passed by a string. The string can be passed in any format (absolute path, sound name, file name).

- `func unload_resources_from_dir(path : String) -> void`: this method lets you unload every audio file located in a specific directory (passed via the `path` string argument). This is especially useful if you preloaded a different folder from the standard directory that you set on the dock for some audio files and want to unload them too without having to write a full list of files. This can be used alongside the automatic preload process. 

- `func is_preload_resources_enabled() -> bool`: this method returns true if the module has been set to preload resources. This method will also return false if you preload specific files from a list, as that doesn't ovveride the `Preload Resources` variable.

### Nodes Preinstantiation
There are also some useful methods to manage nodes preinstantiation (to play multiple sounds of the same type at once):

- `func preinstantiate_nodes_from_dir(path : String, type : String) -> void`: this method lets you preinstantiate every needed node based on a directory content (given its `path`). This is especially useful if you are using a different folder from the standard directory that you set on the dock for some audio files and want to preinstantiate them too without having to write a full list of files. This can be used alongside the automatic preinstantiation process. The only catch is that every sound located in the given directory must be of the same sound type (BGM, BGS, SFX or MFX).

- `func preinstantiate_nodes_from_list(files_list : Array, type_list : Array, all_same_type : bool = false) -> void`: this method allows you to pass a list of files you want to preinstantiate a node for. The files have to be Strings, but can be passed in any format (absolute path, file name, sound name). Pay attention: the `type_list` argument is used to tell the module which type does any sound you passed have. The indexes of the `type_list` must coincide with the indexes of the `files_list`.  If the `all_same_type` argument is passed as true, you can pass a single element array for the `type_list` implying that all the files you're passing are of the same sound type.

- `func preinstantiate_node_from_string(file : String, type : String) -> void`: this method allows you to instantiate a node for a specific audio file passed by a string. The string can be passed in any format (absolute path, sound name, file name). The `type` string is the type of the audio and must be either `BGS`, `SFX` or `MFX`.

- `func preinstantiate_node(stream : Resource, type : String) -> void`: this method allows you to instantiate a node for a specific audio file passed as an already loaded Resource. The file can be accessed afterwards with a sound name or a file name. The `type` string is the type of the audio and must be either `BGS`, `SFX` or `MFX`.

- `func uninstantiate_all_nodes(force_uninstantiation : bool = false) -> void`: this method allows you to uninstantiate every previously instantiated node. It's especially useful when used in combo with the `preinstantiate_nodes_from_list` to uninstantiate at the end of a scene any node you instantiated at the start of the scene. The `force_uninstantiation` argument (default: `false`) will let you uninstantiate nodes even if the `Preinstantiate Nodes` variable is set to on. Note that this will uninstantiate **all** instantiated resources, so it basically overrides the `Preinstantiate Nodes` feature. If the `force_uninstantiation` argument is set to off, however, the method will do nothing if called while `Preinstantiate Nodes` is on.

- `func uninstantiate_nodes_from_list(files_list : Array, type_list : Array, all_same_type : bool = false) -> void)`: this method allows you to pass a list of preinstantiated nodes you want to uninstantiate. The nodes have to be Strings, but can be passed in any format (absolute path, file name, sound name). Pay attention: the `type_list` argument is used to tell the module which type does any sound you passed have. The indexes of the `type_list` must coincide with the indexes of the `files_list`.  If the `all_same_type` argument is passed as true, you can pass a single element array for the `type_list` implying that all the files you're passing are of the same sound type.

- `func uninstantiate_node_from_string(file : String, type : String) -> void`: this method allows you to uninstantiate a previously instantiated node passed by a string. The string can be passed in any format (absolute path, sound name, file name). The `type` string is the type of the audio and must be either `BGS`, `SFX` or `MFX`.

- `func uninstantiate_nodes_from_dir(path : String, type : String) -> void`: this method lets you uninstantiate every instantiated node based on a directory content (given its path). This is especially useful if you are using a different folder from the standard directory that you set on the dock for some audio files and want to uninstantiate them too without having to write a full list of files. This can be used alongside the automatic preinstantiation process. The only catch is that every sound located in the given directory must be of the same sound type (BGM, BGS, SFX or MFX).

- `func is_preinstantiate_nodes_enabled() -> bool`: this method returns true if the module has been set to preinstantiate nodes. This method will also return false if you instantiate specific nodes from a list, as that doesn't ovveride the `Preinstantiate Nodes` variable.


## IMPORTANT NOTES:
With the Sound Manager Module 3.0 update, this module was updated for Godot Engine 3.2, so we can't assure that it will still be compatible with Godot Engine 3.1 from this version onward.

If this docs wasn't enough for you to understand how this module works, or you just want to see it in action, check out my game [*50 Years Later*](https://gitlab.com/Xecestel/50-years-later).

You cannot use this SoundManager to handle AudioStreamPlayer2D or AudioStreamPlayer3D nodes. Those kind of players can only be handled inside the scenes that need to play them.

If you have issues or concerns about this script you can contact me by opening an issue ticket on my [GitLab](https://gitlab.com/xecestel). You can also find me on Twitter ([@Xecestel](https://twitter.com/xecestel)) if you want to contact me.


# Credits
I'd like to thank Simón Olivo (@sarturo) for the help and support he's providing on this project.


# Licenses
Sound Manager Module
Copyright (C) 2019  Celeste Privitera

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at [https://mozilla.org/MPL/2.0/](https://mozilla.org/MPL/2.0/).

You can find more informations in the LICENSE.txt file.


# Changelog

### Version 1.0
- Script complete.

### Version 1.1
- Added getters and setters.

### Version 1.2
- Improved `stop` methods.
- Fixed a bug in the `play_me` method code.

### Version 1.3
- Audio File Dictionary exported to the scene editor: now you can edit it from the scene itself.
- Bug fix: fixed a code line on the `stop_bgm` method.
- Moved the scripts into the internal_scripts folder and the scene outside to make it more visible.

### Version 1.3.1
- Bug fixes

### Version 1.3.2
- Fixed script dependency bug (thanks to @sarturoDev!)

### version 1.4
- Added BGS node to control Background Sounds (like rain or birds chirping)
- Added new setters and getters for node properties, like volume and pitch

### Version 1.5
- Now you can play more sound effects at once

### Version 1.5.1
- Moved files on a single directory

### Version 1.5.2
- Fixed a bug in SoundEffects.gd script

### Version 1.6
- Now the dictionary is optional: see configuration section for more informations
- Bug fix and optimizations

### Version 1.7
- Now you can play multiple Background Sounds at once
- Fixed bugs, improved optimization and readability

### Version 1.8
- Now you can play multiple Music Effects at once
- Fixed bugs, improved readability

## Version 2.0
- Now the module is part of the Sound Manager Plugin

## Version 2.1
- Added optional resource preloading

## Version 2.2
- Added optional node pre-instantiation

## Version 2.3
- Now you can pass absolute path to the module to play sounds

## Version 2.4
- Improved preloading feature
- Improved absolute path passing feature
- Updated docs
- Bug fixes

## Version 2.5
- Now the module doesn't require the plugin anymore in order to work

## Version 2.5.1
- Bug fixes

## Version 2.5.2
- Bug fixes

## Version 2.5.3
- Improved manual preloading: now you can pass already loaded resources

## Version 2.5.4
- Bug fixes

## Version 2.5.5
- Bug fixes

## Version 2.6
- Added manual preinstantiation: now you can preinstantiate selected nodes
- Improved manual preloading
- Bug fixes and general improvements

## Version 2.7
- Now you can add voices in the Audio Files Dictionary in runtime
- Now you can add in the Dictionary absolute paths as values

## Version 3.0
- Added compatibility with Godot Engine 3.2

## Version 3.1
- Fixed some bugs on preinstantiation and preloading of resources
