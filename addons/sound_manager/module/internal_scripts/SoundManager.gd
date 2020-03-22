extends SoundManagerModule

####################################################################
#	SOUND MANAGER MODULE FOR GODOT 3.2
#			Version 3.0
#			© Xecestel
####################################################################
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
#####################################
#variables#
export (String, DIR) var BGM_DIR_PATH	= "";
export (String, DIR) var BGS_DIR_PATH	= "";
export (String, DIR) var SFX_DIR_PATH	= "";
export (String, DIR) var MFX_DIR_PATH	= "";
export (bool) var preload_resources		= false;
export (bool) var preinstantiate_nodes	= false;

onready var BGM_Audiostream		= get_node("BGM");
onready var BGS_Audiostreams	= $BackgroundSounds.get_children();
onready var SE_Audiostreams		= $SoundEffects.get_children();
onready var ME_Audiostreams		= $MusicEffects.get_children();
onready var soundmgr_dir_rel_path = self.get_script().get_path().get_base_dir();

var bgm_playing				: String;
var bgs_playing				: Array		= [ "BGS0" ];
var se_playing				: Array		= [ "SE0" ];
var me_playing				: Array		= [ "ME0" ];

var bgm_bus					: String = "Master";
var bgs_bus					: String = "Master";
var sfx_bus					: String = "Master";
var mfx_bus					: String = "Master";

var Preloaded_Resources : Dictionary = {};
var Instantiated_Nodes : Dictionary = {
	"BGS"	:	[],
	"SFX"	:	[],
	"MFX"	:	[]
	};
###########

func _ready() -> void:
	if(ProjectSettings.get_setting("editor_plugins/enabled") &&
	Array(ProjectSettings.get_setting("editor_plugins/enabled")).has("sound_manager")):
			get_sound_manager_settings();
			load_settings();
			
	if (preload_resources && Preloaded_Resources.empty()):
		print_debug("Preloading...");
		self.preload_audio_files();
	if (preinstantiate_nodes):
		print_debug("Instantiating nodes...");
		self.preinstance_nodes();
#end

#####################################
#	SOUND MANAGER SETTINGS HANDLING	#
#####################################

#Load the Sound Manager settings from the JSON file:  SoundManager.json
func get_sound_manager_settings()-> void:
	var data_settings : Dictionary;
	var file: File = File.new();
	file.open("res://addons/sound_manager/SoundManager.json", File.READ);
	var json : JSONParseResult = JSON.parse(file.get_as_text());
	file.close();
	if (typeof(json.result) == TYPE_DICTIONARY):
		data_settings = json.result;
		BGM_DIR_PATH = data_settings["BGM_DIR_PATH"];
		BGS_DIR_PATH = data_settings["BGS_DIR_PATH"];
		SFX_DIR_PATH = data_settings["SFX_DIR_PATH"];
		MFX_DIR_PATH = data_settings["MFX_DIR_PATH"];
		
		bgm_bus = data_settings["BGM_BUS_NAME"];
		bgs_bus = data_settings["BGS_BUS_NAME"];
		sfx_bus = data_settings["SFX_BUS_NAME"];
		mfx_bus = data_settings["MFX_BUS_NAME"];
	
		Audio_Files_Dictionary = data_settings["Dictionary"];
		
		preload_resources = data_settings["PRELOAD_RES"];
		preinstantiate_nodes = data_settings["PREINSTANTIATE_NODES"];
	else:
		print_debug("Failed to load the sound manager's settings file: " + 'res://addons/sound_manager/SoundManager.json');
		return;
#end


func load_settings() -> void:
	BGM_DIR_PATH = self.normalize_path(BGM_DIR_PATH);
	BGS_DIR_PATH = self.normalize_path(BGS_DIR_PATH);
	SFX_DIR_PATH = self.normalize_path(SFX_DIR_PATH);
	MFX_DIR_PATH = self.normalize_path(MFX_DIR_PATH);
	
	BGM_Audiostream.set_bus(bgm_bus);
	BGS_Audiostreams[0].set_bus(bgs_bus);
	SE_Audiostreams[0].set_bus(sfx_bus);
	ME_Audiostreams[0].set_bus(mfx_bus);
#end


func normalize_path(path : String) -> String:
	if (path == "res://"):
		path = path.substr(0, 5);
	return path;
#end

#####################
#	BGM HANDLING	#
#####################

#Plays a given bgm
func play_bgm(bgm : String, from_position : float = 0.0, reset_to_defaults : bool = true) -> void:
	if (bgm == "" || bgm == null):
		print_debug("No BGM selected.");
		return;
	if (self.is_bgm_playing(bgm)):
		return;
	
	var bgm_file_name = bgm.get_file() if (self.is_audio_file(bgm)) else Audio_Files_Dictionary.get(bgm);
	if (bgm_file_name == null):
		print_debug("Error: file not found " + bgm);
		return;
	
	var Stream;
	if (Preloaded_Resources.has(bgm_file_name)):
		print_debug("Resource preloaded");
		Stream = Preloaded_Resources.get(bgm_file_name);
	else:
		var bgm_file_path;
		if (bgm_file_name.get_base_dir() == "" || bgm_file_name.get_base_dir() == BGM_DIR_PATH || bgm_file_name.get_base_dir() == BGM_DIR_PATH + "/"):
			bgm_file_path = BGM_DIR_PATH + "/" + bgm_file_name if (bgm.get_base_dir() == "" || bgm.get_base_dir() == BGM_DIR_PATH || bgm.get_base_dir() == BGM_DIR_PATH + "/") else bgm;
		else:
			bgm_file_path = bgm_file_name;
		Stream = load(bgm_file_path);
		
		if (Stream == null):
			print_debug("Failed to load file from path: " + bgm_file_path);
			return;
	
	self.stop_bgm();
	self.pause_bgm(false);
	
	if (reset_to_defaults):
		self.set_bgm_pitch_scale(1.0);
		self.set_bgm_volume_db(0.0);
	BGM_Audiostream.set_stream(Stream);
	BGM_Audiostream.play(from_position);
	bgm_playing = bgm;
#end

func stop_bgm(bgm : String = "") -> void:
	if (bgm != ""):
		if (self.is_bgm_playing(bgm)):
			BGM_Audiostream.stop();
			return;
			
	BGM_Audiostream.stop();
#end

func is_bgm_playing(bgm : String = "") -> bool:
	if (bgm == null || bgm == ""):
		return BGM_Audiostream.is_playing();
	return (bgm_playing == bgm && BGM_Audiostream.is_playing());
#end

func set_bgm_volume_db(volume_db : float) -> void:
	BGM_Audiostream.set_volume_db(volume_db);
#end

func get_bgm_volume_db() -> float:
	return BGM_Audiostream.get_volume_db();
#end

func set_bgm_pitch_scale(pitch : float) -> void:
	BGM_Audiostream.set_pitch_scale(pitch);
#end

func get_bgm_pitch_scale() -> float:
	return BGM_Audiostream.get_pitch_scale();
#end

func pause_bgm(paused : bool) -> void:
	BGM_Audiostream.set_stream_paused(paused);
#end

func is_bgm_paused() -> bool:
	return BGM_Audiostream.get_paused();
#end


#####################
#	BGS HANDLING	#
#####################

#Plays a given bgm
func play_bgs(bgs : String, reset_to_defaults : bool = true, override_current_sound : bool = true, sound_to_override : String = "") -> void:
	if (bgs == "" || bgs == null):
		print_debug("No BGS selected.");
		return;
	BGS_Audiostreams = $BackgroundSounds.get_children();
		
	var bgs_name = Audio_Files_Dictionary.get(bgs) if (Audio_Files_Dictionary.has(bgs)) else bgs;
	if (Instantiated_Nodes["BGS"].has(bgs_name.get_basename())):
		var bgs_index = Instantiated_Nodes["BGS"].find(bgs_name.get_basename());
		BGS_Audiostreams[bgs_index].play();
		return;
		
	if (override_current_sound):
		if (self.is_bgs_playing(bgs)):
			return;
			
	var bgs_file_name = bgs.get_file() if (self.is_audio_file(bgs)) else Audio_Files_Dictionary.get(bgs);
	if (bgs_file_name == null):
		print_debug("Error: file not found " + bgs);
		return;
		
	var Stream;
	if (Preloaded_Resources.has(bgs_file_name)):
		Stream = Preloaded_Resources.get(bgs_file_name);
	else:
		var bgs_file_path;
		if (bgs_file_name.get_base_dir() == "" || bgs_file_name.get_base_dir() == BGS_DIR_PATH || bgs_file_name.get_base_dir() == BGS_DIR_PATH + "/"):
			bgs_file_path = BGS_DIR_PATH + "/" + bgs_file_name if (bgs.get_base_dir() == "" || bgs.get_base_dir() == BGS_DIR_PATH || bgs.get_base_dir() == BGS_DIR_PATH + "/") else bgs;
		else:
			bgs_file_path = bgs_file_name;
		Stream = load(bgs_file_path);
		
		if (Stream == null):
			print_debug("Failed to load file from path: " + bgs_file_path);
			return;
		
	var bgs_index = 0;
	
	if (override_current_sound):
		if (sound_to_override != "" && sound_to_override != null):
			bgs_index = bgs_playing.find(sound_to_override);
			
		if (bgs_index < 0):
			print_debug("Sound not found: " + sound_to_override);
			return;
	else:
		bgs_index = self.add_background_sound(bgs);
		
	BGS_Audiostreams[bgs_index].set_stream(Stream);
	BGS_Audiostreams[bgs_index].play();
	if (BGS_Audiostreams[bgs_index].get_script() != null):
		BGS_Audiostreams[bgs_index].set_sound_name(bgs);
	if (bgs_index < bgs_playing.size()):
		bgs_playing[bgs_index] = bgs;
	else:
		bgs_playing.append(bgs);
	if (reset_to_defaults):
		self.set_bgs_pitch_scale(1.0, bgs_playing[bgs_index]);
		self.set_bgs_volume_db(0.0, bgs_playing[bgs_index]);
#end

func stop_bgs(bgs : String = "") -> void:
	var bgs_index = 0;
	if (bgs != "" && bgs != null):
		if (self.is_bgs_playing(bgs)):
			bgs_index = bgs_playing.find(bgs);
			if (BGS_Audiostreams[bgs_index].get_script() != null):
				BGS_Audiostreams[bgs_index].stop();
				self.erase_background_sound(bgs);
				bgs_playing.erase(bgs);
				return;
	BGS_Audiostreams[bgs_index].stop();
#end

func is_bgs_playing(bgs : String = "") -> bool:
	var bgs_index = self.find_bgs(bgs);
	
	if (bgs_index < 0):
		return false;
	elif (bgs_index >= 1):
		return true;
			
	return BGS_Audiostreams[0].is_playing();
#end

func set_bgs_volume_db(volume_db : float, bgs : String = "") -> void:
	var bgs_index = self.find_bgs(bgs);
	if (bgs_index < 0):
		print_debug("Sound not found: " + bgs);
		return;
	BGS_Audiostreams[bgs_index].set_volume_db(volume_db);
#end

func get_bgs_volume_db(bgs : String = "") -> float:
	var bgs_index = self.find_bgs(bgs);
	if (bgs_index < 0):
		print_debug("Sound not found: " + bgs);
		return -1.0;
	return BGS_Audiostreams[bgs_index].get_volume_db();
#end
	
func set_bgs_pitch_scale(pitch : float, bgs : String = "") -> void:
	var bgs_index = self.find_bgs(bgs);
	if (bgs_index < 0):
		print_debug("Sound not found: " + bgs);
		return;
	BGS_Audiostreams[bgs_index].set_pitch_scale(pitch);
#end

func get_bgs_pitch_scale(bgs : String = "") -> float:
	var bgs_index = self.find_bgs(bgs);
	if (bgs_index < 0):
		print_debug("Sound not found: " + bgs);
		return -1.0;
			
	return BGS_Audiostreams[bgs_index].get_pitch_scale();
#end
	
func pause_bgs(paused : bool, bgs : String = "") -> void:
	var bgs_index = self.find_bgs(bgs);
	if (bgs_index < 0):
		print_debug("Sound not foun: " + bgs);
		return;
	BGS_Audiostreams[bgs_index].set_stream_paused(paused);
#end

func is_bgs_paused(bgs : String = "") -> bool:
	var bgs_index = self.find_bgs(bgs);
	if (bgs_index < 0):
		print_debug("Sound not found: " + bgs);
		return false;
		
	return BGS_Audiostreams[bgs_index].get_stream_paused();
#end

#############################
#	SOUND EFFECTS HANDLING	#
#############################

#Plays selected Sound Effect
func play_se(sound_effect : String, reset_to_defaults : bool = true, override_current_sound : bool = true, sound_to_override : String = "") -> void:
	if (sound_effect == "" || sound_effect == null):
		print_debug("No sound effect selected.");
		return;
	SE_Audiostreams = $SoundEffects.get_children();
	
	var se_name = Audio_Files_Dictionary.get(sound_effect) if (Audio_Files_Dictionary.has(sound_effect)) else sound_effect;
	if (Instantiated_Nodes["SFX"].has(se_name.get_basename()) && override_current_sound):
		if (self.is_se_playing(sound_effect)):
			return;
		print_debug("Preinstantiated node: " + se_name);
		var se_index = Instantiated_Nodes["SFX"].find(se_name.get_basename());
		SE_Audiostreams[se_index].play();
		return;

	if (override_current_sound):
		if (self.is_se_playing(sound_effect)):
			return;
		
	var sound_effect_file_name = sound_effect.get_file() if (self.is_audio_file(sound_effect)) else Audio_Files_Dictionary.get(sound_effect);
	if (sound_effect_file_name == null):
		print_debug("Error: file not found " + sound_effect);
		return;
		
	var Stream;
	if (Preloaded_Resources.has(sound_effect_file_name)):
		Stream = Preloaded_Resources.get(sound_effect_file_name);
		print_debug("Resource preloaded: " + se_name);
	else:
		var sound_effect_path;
		if (sound_effect_file_name.get_base_dir() == "" || sound_effect_file_name.get_base_dir() == SFX_DIR_PATH || sound_effect_file_name.get_base_dir() == SFX_DIR_PATH + "/"):
			sound_effect_path = SFX_DIR_PATH + "/" + sound_effect_file_name if (sound_effect.get_base_dir() == "" || sound_effect.get_base_dir() == SFX_DIR_PATH || sound_effect.get_base_dir() == SFX_DIR_PATH + "/") else sound_effect;
		else:
			sound_effect_path = sound_effect_file_name;
		Stream = load(sound_effect_path);
		
		if (Stream == null):
			print_debug("Failed to load file from path: " + sound_effect_path);
			return;
	
	var se_index = 0;
	
	if (override_current_sound):
		if (sound_to_override != "" && sound_to_override != null):
			se_index = se_playing.find(sound_to_override);
			
		if (se_index < 0):
			print_debug("Sound not found: " + sound_to_override);
			return;
	else:
		se_index = self.add_sound_effect(sound_effect);
	
	SE_Audiostreams[se_index].set_stream(Stream);
	SE_Audiostreams[se_index].play();
	if (SE_Audiostreams[se_index].get_script() != null):
		SE_Audiostreams[se_index].set_sound_name(sound_effect);
	if (se_index < se_playing.size()):
		se_playing[se_index] = sound_effect;
	else:
		se_playing.append(sound_effect);
		
	if (reset_to_defaults):
		self.set_se_pitch_scale(1.0, se_playing[se_index]);
		self.set_se_volume_db(0.0, se_playing[se_index]);
#end

#Stops selected Sound Effect
func stop_se(sound_effect : String = "") -> void:
	var se_index = 0;
	if (sound_effect != "" && sound_effect != null):
		if (self.is_se_playing(sound_effect)):
			se_index = se_playing.find(sound_effect);
			if (SE_Audiostreams[se_index].get_script() != null):
				SE_Audiostreams[se_index].stop();
				self.erase_sound_effect(sound_effect);
				se_playing.erase(sound_effect);
				return;
	SE_Audiostreams[se_index].stop();
#end

#Returns true if the selected Sound Effect is already playing
func is_se_playing(sound_effect : String = "") -> bool:
	if (sound_effect != "" || sound_effect != null):
		var se_index = se_playing.find(sound_effect);
		if (se_index < 0):
			return false;
		elif (se_index >= 1):
			return true;
			
	return SE_Audiostreams[0].is_playing();
#end

func set_se_volume_db(volume_db : float, sound_effect : String = "") -> void:
	var se_index = self.find_se(sound_effect);
	if (se_index < 0):
		print_debug("Sound not found: " + sound_effect);
		return;
	SE_Audiostreams[se_index].set_volume_db(volume_db);
#end

func get_se_volume_db(sound_effect : String = "") -> float:
	var se_index = self.find_se(sound_effect);
	if (se_index < 0):
		print_debug("Sound not found: " + sound_effect);
		return -1.0;
	return SE_Audiostreams[se_index].get_volume_db();
#end
	
func set_se_pitch_scale(pitch : float, sound_effect : String = "") -> void:
	var se_index = self.find_se(sound_effect);
	if (se_index < 0):
		print_debug("Sound not found: " + sound_effect);
		return;
	SE_Audiostreams[se_index].set_pitch_scale(pitch);
#end

func get_se_pitch_scale(sound_effect : String = "") -> float:
	var se_index = self.find_se(sound_effect);
	if (se_index < 0):
		print_debug("Sound not found: " + sound_effect);
		return -1.0;
	return SE_Audiostreams[se_index].get_pitch_scale();
	
func pause_se(paused : bool, sound_effect : String = "") -> void:
	var se_index = self.find_se(sound_effect);
	if (se_index < 0):
		print_debug("Sound not found: " + sound_effect);
		return;
	SE_Audiostreams[se_index].set_stream_paused(paused);
#end

func is_se_paused(sound_effect : String = "") -> bool:
	var se_index = self.find_se(sound_effect);
	if (se_index < 0):
		print_debug("Sound not found: " + sound_effect);
		return false;
	return SE_Audiostreams[se_index].get_stream_paused();
#end

#############################
#	Music Effects Handling	#
#############################

func play_me(music_effect : String, reset_to_defaults : bool = true, override_current_sound : bool = true, sound_to_override : String = "") -> void:
	if (music_effect == "" || music_effect == null):
		print_debug("No sound effect selected.");
		return;
	ME_Audiostreams = $MusicEffects.get_children();
	
	var me_name = Audio_Files_Dictionary.get(music_effect) if (Audio_Files_Dictionary.has(music_effect)) else music_effect;
	if (Instantiated_Nodes["MFX"].has(me_name.get_basename())):
		var me_index = Instantiated_Nodes["MFX"].find(me_name.get_basename());
		ME_Audiostreams[me_index].play();
		return;
		
	if (override_current_sound):
		if (self.is_me_playing(music_effect)):
			return;
	
	
	var music_effect_file_name = music_effect.get_file() if (self.is_audio_file(music_effect)) else Audio_Files_Dictionary.get(music_effect);
	if (music_effect_file_name == null):
		print_debug("Error: file not found " + music_effect);
		return;
	
	var Stream;
	if (Preloaded_Resources.has(music_effect_file_name)):
		Stream = Preloaded_Resources.get(music_effect_file_name);
	else:
		var music_effect_path;
		if (music_effect_file_name.get_base_dir() == "" || music_effect_file_name.get_base_dir() == MFX_DIR_PATH || music_effect_file_name.get_base_dir() == MFX_DIR_PATH + "/"):
			music_effect_path = MFX_DIR_PATH + "/" + music_effect_file_name if (music_effect.get_base_dir() == "" || music_effect.get_base_dir() == MFX_DIR_PATH || music_effect.get_base_dir() == MFX_DIR_PATH + "/") else music_effect;
		else:
			music_effect_path = music_effect_file_name;
		Stream = load(music_effect_path);
		
		if (Stream == null):
			print_debug("Failed to load file from path: " + music_effect_path);
			return;
		
	var me_index = 0;
	
	if (override_current_sound):
		if (sound_to_override != "" && sound_to_override != null):
			me_index = me_playing.find(sound_to_override);
			
			if (me_index < 0):
				print_debug("Sound not found: " + sound_to_override);
				return;
		else:
			me_index = add_music_effect(music_effect);
		
	ME_Audiostreams[me_index].set_stream(Stream);
	ME_Audiostreams[me_index].play();
	if (ME_Audiostreams[me_index].get_script() != null):
		ME_Audiostreams[me_index].set_sound_name(music_effect);
	if (me_index < me_playing.size()):
		me_playing[me_index] = music_effect;
	else:
		me_playing.append(music_effect);
	if (reset_to_defaults):
		self.set_me_pitch_scale(1.0, me_playing[me_index]);
		self.set_me_volume_db(0.0, me_playing[me_index]);
#end

func stop_me(music_effect : String = "") -> void:
	var me_index = 0;
	if (music_effect != "" && music_effect != null):
		if (self.is_me_playing(music_effect)):
			me_index = me_playing.find(music_effect);
			if (ME_Audiostreams[me_index].get_script() != null):
				ME_Audiostreams[me_index].stop();
				self.erase_music_effect(music_effect);
				me_playing.erase(music_effect);
				return;
	ME_Audiostreams[me_index].stop();
#end

func is_me_playing(music_effect : String = "") -> bool:
	if (music_effect != "" || music_effect != null):
		var me_index = me_playing.find(music_effect);
		if (me_index < 0):
			return false;
		elif (me_index >= 1):
			return true;
	return ME_Audiostreams[0].is_playing();
#end

func set_me_volume_db(volume_db : float, music_effect : String = "") -> void:
	var me_index = self.find_me(music_effect);
	if (me_index < 0):
		print_debug("Sound not found: " + music_effect);
		return;
	ME_Audiostreams[me_index].set_volume_db(volume_db);
#end

func get_me_volume_db(music_effect : String = "") -> float:
	var me_index = self.find_me(music_effect);
	if (me_index < 0):
		print_debug("Sound not found: " + music_effect);
		return -1.0;
	return ME_Audiostreams[me_index].get_volume_db();
#end
	
func set_me_pitch_scale(pitch : float, music_effect : String = "") -> void:
	var me_index = self.find_me(music_effect);
	if (me_index < 0):
		print_debug("Soud not found: " + music_effect);
		return;
		
	ME_Audiostreams[me_index].set_pitch_scale(pitch);
#end

func get_me_pitch_scale(music_effect : String = "") -> float:
	var me_index = self.find_me(music_effect);
	if (me_index < 0):
		print_debug("Sound not found: " + music_effect);
		return -1.0;
	return ME_Audiostreams[me_index].get_pitch_scale();
#end

func pause_me(paused : bool, music_effect : String = "") -> void:
	var me_index = self.find_me(music_effect);
	if (me_index < 0):
		print_debug("Sound not found: " + music_effect);
		return;
	ME_Audiostreams[me_index].set_stream_paused(paused);
#end

func is_me_paused(music_effect : String = "") -> bool:
	var me_index = self.find_me(music_effect);
	if (me_index < 0):
		print_debug("Sound not found: " + music_effect);
		return false;
	return ME_Audiostreams[me_index].get_stream_paused();
#end


#################################
#		GETTERS AND SETTERS		#
#################################

#Returns the name of the currently playing (or last played) bgm
func get_playing_bgm() -> String:
	return bgm_playing;
#end

#Returns the name of the currently playing (or last played) bgs
func get_playing_bgs() -> Array:
	return bgs_playing;
#end

#Returns the name of the currently playing sound effects
func get_playing_se_array() -> Array:
	return se_playing;
#end

#Returns the name of the currently playing music effects
func get_playing_me() -> Array:
	return me_playing;
#end

#Returns the config dictionary
func get_configuration_dictionary() -> Dictionary:
	return Audio_Files_Dictionary;
#end

#Returns the file name of the given stream name
#Returns null if an error occures.
func get_config_value(stream_name : String) -> String:
	return Audio_Files_Dictionary.get(stream_name);
#end

#Allows you to change or add a stream file and name to the dictionary in runtime
func set_config_key(new_stream_name : String, new_stream_file : String) -> void:
	if (new_stream_file == "" || new_stream_name == ""):
		print_debug("Invalid arguments");
		return;
	
	Audio_Files_Dictionary[new_stream_name] = new_stream_file;
	
	if (preload_resources):
		self.preload_resource_from_string(new_stream_file);
#end

func enable_preload_resources(enabled : bool = true) -> void:
	self.preload_resources = enabled;
#end

func is_preload_resources_enabled() -> bool:
	return self.preload_resources;
#end

#Allows to add a new voice to the Audio Files Dictionary
func add_to_dictionary(audio_name : String, audio_file : String) -> void:
	Audio_Files_Dictionary[audio_name] = audio_file;

#############################
#	RESOURCE PRELOADING		#
#############################

func preload_resources_from_list(files_list : Array) -> void:
	if (preload_resources):
		print_debug("Resources already preloaded.");
		return;
			
	for file in files_list:
		if (file is String):
			self.preload_resource_from_string(file);
		elif (file is Resource):
			self.preload_resource(file);
#end

func preload_resource(file : Resource) -> void:		
	if (file == null):
		print_debug("Invalid resource passed");
		return;
	
	var file_name = file.get_path().get_file();
	
	Preloaded_Resources[file_name] = file;
#end

func preload_resource_from_string(file : String) -> void:
	var res_dirs = [BGM_DIR_PATH + "/", BGS_DIR_PATH + "/",
					SFX_DIR_PATH + "/", MFX_DIR_PATH + "/"];
	
	var res = null;
	var file_name = file;
	
	if (self.is_import_file(file)):
		file_name = file_name.get_basename();
	elif (self.is_audio_file(file) == false):
		file_name = Audio_Files_Dictionary.get(file);
		if (file_name == null):
			print_debug("Audio File not found in Dictionary");
			return;
	
	if (file_name.match("res://*")):
		res = load(file_name);
		file_name = file_name.get_file();
	else:
		var i = 0;
		while (res == null && i < 4):
			res = load(res_dirs[i] + file_name);
			i += 1;
				
	if (res == null):
			print_debug("An error occured while preloading resource: " + file);
	else:
		Preloaded_Resources[file_name] = res;
#end

func preload_resources_from_dir(path : String) -> void:
	var dir = Directory.new();
	if dir.open(path + "/") == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != ""):
			if (self.is_audio_file(file_name) || self.is_import_file(file_name)):
				self.preload_resource_from_string(file_name);
			file_name = dir.get_next();
	else:
		print_debug("An error occurred when trying to access the path: " + path);
#end

func unload_all_resources(force_unload : bool = false) -> void:
	if (preload_resources):
		if (force_unload == false):
			print_debug("To unload resources with Preload Resources variable on, pass force_unload argument on true");
			return;
		preload_resources = false;
		
	Preloaded_Resources.clear();
#end

func unload_resources_from_list(files_list : Array) -> void:
	for file in files_list:
		if (file is String):
			self.unload_resource_from_string(file);
#end

func unload_resource_from_string(file : String) -> void:
	var file_name = file;
	
	if (self.is_import_file(file)):
		file_name = file_name.get_basename();
	if (self.is_audio_file(file) == false):
		file_name = Audio_Files_Dictionary.get(file);
		if (file_name == null):
			print_debug("Audio File not found in Dictionary");
			return;
	
	if ("res://" in file_name):
		file_name = file_name.get_file();
	
	if (Preloaded_Resources.has(file_name)):
		Preloaded_Resources.erase(file_name);
	else:
		print_debug("An error occured while unloading resource: " + file);
#end

func unload_resources_from_dir(path : String) -> void:
	var dir = Directory.new();
	if dir.open(path + "/") == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != ""):
			if (self.is_audio_file(file_name)):
				self.unload_resource_from_string(file_name);
			file_name = dir.get_next();
	else:
		print_debug("An error occurred when trying to access the path: " + path);
#end

#############################
#	NODES PREINSTANTIATION	#
#############################

func preinstantiate_nodes_from_dir(path : String, type : String) -> void:
	var dir = Directory.new();
	if dir.open(path + "/") == OK:
		dir.list_dir_begin();
		var file_name = dir.get_next();
		var sound_index = 0;
		while (file_name != ""):
			if (self.is_audio_file(file_name) || self.is_import_file(file_name)):
				self.preinstantiate_node_from_string(file_name, type);
			file_name = dir.get_next();
	else:
		print_debug("An error occurred when trying to access the path: " + path);
#end

func preinstantiate_nodes_from_list(files_list : Array, type_list : Array, all_same_type : bool = false) -> void:	
	var index = 0;
	for file in files_list:
		if (file is String):
			if (all_same_type == false):
				index = files_list.find(file);
			self.preinstantiate_node_from_string(file, type_list[index]);
#end
	

func preinstantiate_node_from_string(file : String, type : String) -> void:	
	var Stream = null;
	var file_name = file;
	var sound_index = 0;
	
	if (self.is_import_file(file)):
		file_name = file_name.get_basename();
	elif (self.is_audio_file(file) == false):
		file_name = Audio_Files_Dictionary.get(file);
		if (file_name == null):
			print_debug("Audio File not found in Dictionary");
			return;
	
	if (file_name.match("res://*")):
		Stream = load(file_name);
		file_name = file_name.get_file();
		
	if (Preloaded_Resources.has(file_name)):
		Stream = Preloaded_Resources.get(file_name);
		
	if (type.to_lower() == "bgs"):
		sound_index = self.add_background_sound(file_name, true);
		if (Stream == null):
			Stream = load(BGS_DIR_PATH + "/" + file_name);
		BGS_Audiostreams[sound_index].set_stream(Stream);
	elif (type.to_lower() == "sfx"):
		sound_index = self.add_sound_effect(file_name, true);
		if (Stream == null):
			Stream = load(SFX_DIR_PATH + "/" + file_name);
		SE_Audiostreams[sound_index].set_stream(Stream);
	elif (type.to_lower() == "mfx"):
		sound_index = self.add_music_effect(file_name, true);
		if (Stream == null):
			Stream = load(MFX_DIR_PATH + "/" + file_name);
		ME_Audiostreams[sound_index].set_stream(Stream);
				
	if (Stream == null):
			print_debug("An error occured while creating a node from resource: " + file);
#end

func preinstantiate_node(stream : Resource, type : String) -> void:
	if (stream == null):
		print_debug("Invalid resource passed");
		return;
		
	var file_name = stream.get_path().get_file();
	var sound_index = 0;
	
	if (type.to_lower() == "bgs"):
		sound_index = self.add_background_sound(file_name, true);
		BGS_Audiostreams[sound_index].set_stream(stream);
	elif (type.to_lower() == "sfx"):
		sound_index = self.add_sound_effect(file_name, true);
		SE_Audiostreams[sound_index].set_stream(stream);
	elif (type.to_lower() == "mfx"):
		sound_index = self.add_music_effect(file_name, true);
		ME_Audiostreams[sound_index].set_stream(stream);
#end

func uninstantiate_all_nodes(force_uninstantiation : bool = false) -> void:
	if (preinstantiate_nodes):
		if (force_uninstantiation == false):
			print_debug("To uninstantiate resources with Preinstantiate Nodes on, pass force_uninstantiation argument on true");
			return;
		preinstantiate_nodes = false;
	
	uninstantiate_nodes_from_list(Instantiated_Nodes["BGS"], [ "BGS" ], true);
	uninstantiate_nodes_from_list(Instantiated_Nodes["SFX"], [ "SFX" ], true);
	uninstantiate_nodes_from_list(Instantiated_Nodes["MFX"], [ "MFX" ], true);
#end

func uninstantiate_nodes_from_list(files_list : Array, type_list : Array, all_same_type : bool = false) -> void:
	var index = 0;
	for file in files_list:
		if (file is String):
			if (all_same_type == false):
				index = files_list.find(file);
			self.uninstantiate_node_from_string(file, type_list[index]);
			
func uninstantiate_node_from_string(file : String, type : String) -> void:
	var file_name = file;
	var sound_index = 0;
	
	if (self.is_import_file(file)):
		file_name = file_name.get_basename();
	elif (self.is_audio_file(file) == false):
		file_name = Audio_Files_Dictionary.get(file);
		if (file_name == null):
			print_debug("Audio File not found in Dictionary");
			return;
	
	if ("res://" in file_name):
		file_name = file_name.get_file();
		
	if (type.to_lower() == "bgs"):
		self.erase_background_sound(file_name);
	elif (type.to_lower() == "sfx"):
		self.erase_sound_effect(file_name);
	elif (type.to_lower() == "mfx"):
		self.erase_music_effect(file_name);
#end

func uninstantiate_nodes_from_dir(path : String, type : String) -> void:
	var dir = Directory.new();
	if dir.open(path + "/") == OK:
		dir.list_dir_begin();
		var file_name = dir.get_next();
		var sound_index = 0;
		while (file_name != ""):
			if (self.is_audio_file(file_name)):
				self.uninstantiate_node_from_string(file_name, type);
			file_name = dir.get_next();
	else:
		print_debug("An error occurred when trying to access the path: " + path);
#end

func is_preinstantiate_nodes_enabled() -> bool:
	return preinstantiate_nodes;
#end

#############################
#	INTERNAL METHODS		#
#############################

func add_background_sound(sound_name : String, preinstance : bool = false) -> int:
	var bgs_index;
	var new_audiostream = AudioStreamPlayer.new();
	var background_sound_script = load(soundmgr_dir_rel_path + "/Sounds.gd");
	
	$BackgroundSounds.add_child(new_audiostream);
	if (preinstance == false):
		new_audiostream.set_script(background_sound_script);
		new_audiostream.set_type("BGS");
		new_audiostream.connect_signals(self);
	new_audiostream.set_bus(bgs_bus);
	bgs_index = new_audiostream.get_index();
	if (Instantiated_Nodes["BGS"].has(sound_name.get_basename()) == false):
		Instantiated_Nodes["BGS"].append(sound_name.get_basename());
	BGS_Audiostreams.append(new_audiostream);
	bgs_index = Instantiated_Nodes["BGS"].find(sound_name.get_basename());
	
	return bgs_index;
#end

func erase_background_sound(sound_name : String) -> void:
	var bgs_name = Audio_Files_Dictionary.get(sound_name) if (Audio_Files_Dictionary.has(sound_name)) else sound_name.get_basename();
	var bgs_index = Instantiated_Nodes["BGS"].find(bgs_name);
	
	if (bgs_index < 0):
		return;
		
	Instantiated_Nodes["BGS"].erase(bgs_name);
	BGS_Audiostreams.remove(bgs_index);
	$BackgroundSounds.get_children()[bgs_index].queue_free();
#end

func find_bgs(bgs : String = "") -> int:
	var bgs_index = 0;
	if (bgs != null && bgs != ""):
		bgs_index = bgs_playing.find(bgs);
	return bgs_index;
#end

func _on_BGS_finished(sound_name):
	self.erase_background_sound(sound_name);
#end

func add_sound_effect(sound_name : String, preinstance : bool = false) -> int:
	var se_index;
	var new_audiostream = AudioStreamPlayer.new();
	var sound_effect_script = load(soundmgr_dir_rel_path + "/Sounds.gd");
	
	if (preinstance == false):
		new_audiostream.set_script(sound_effect_script);
		new_audiostream.set_type("SE");
		new_audiostream.connect_signals(self);
	$SoundEffects.add_child(new_audiostream);
	new_audiostream.set_bus(sfx_bus);
	if (Instantiated_Nodes["SFX"].has(sound_name.get_basename()) == false):
		Instantiated_Nodes["SFX"].append(sound_name.get_basename());
	SE_Audiostreams.append(new_audiostream);
	se_index = Instantiated_Nodes["SFX"].find(sound_name.get_basename());
	
	return se_index;
#end

func erase_sound_effect(sound_name : String) -> void:
	var se_name = Audio_Files_Dictionary.get(sound_name) if (Audio_Files_Dictionary.has(sound_name)) else sound_name.get_basename();
	var se_index = Instantiated_Nodes["SFX"].find(se_name);
	
	if (se_index < 0):
		return;
		
	Instantiated_Nodes["SFX"].erase(se_name);
	SE_Audiostreams.remove(se_index);
	$SoundEffects.get_children()[se_index].queue_free();
#end

func find_se(se : String = "") -> int:
	var se_index = 0;
	if (se != null && se != ""):
		se_index = se_playing.find(se);
	return se_index;
#end

func _on_SE_finished(sound_name):
	self.erase_sound_effect(sound_name);
#end

func add_music_effect(sound_name : String, preinstance : bool = false) -> int:
	var me_index;
	var new_audiostream = AudioStreamPlayer.new();
	var music_effects_script = load(soundmgr_dir_rel_path + "/Sounds.gd");
	
	if (preinstance == false):
		new_audiostream.set_script(music_effects_script);
		new_audiostream.set_type("ME");
		new_audiostream.connect_signals(self);
	$MusicEffects.add_child(new_audiostream);
	new_audiostream.set_bus(mfx_bus);
	if (Instantiated_Nodes["MFX"].has(sound_name.get_basename()) == false):
		Instantiated_Nodes["MFX"].append(sound_name.get_basename());
	ME_Audiostreams.append(new_audiostream);
	me_index = Instantiated_Nodes["MFX"].find(sound_name.get_basename());
	
	return me_index;
#end

func erase_music_effect(sound_name : String) -> void:
	var me_index = me_playing.find(sound_name);
	
	if (me_index < 0):
		return;
		
	Instantiated_Nodes["MFX"].erase(sound_name.get_basename());
	me_playing.erase(sound_name);
	ME_Audiostreams.remove(me_index);
	$MusicEffects.get_children()[me_index].queue_free();
#end

func find_me(me : String = "") -> int:
	var me_index = 0;
	if (me != null && me != ""):
		me_index = me_playing.find(me);
	return me_index;
#end

func _on_ME_finished(sound_name):
	self.erase_music_effect(sound_name);
#end

func preload_audio_files() -> void:
	if (BGM_DIR_PATH != null && BGM_DIR_PATH != ""):
		self.preload_resources_from_dir(BGM_DIR_PATH);
	if (BGS_DIR_PATH != null && BGS_DIR_PATH != ""):
		self.preload_resources_from_dir(BGS_DIR_PATH);
	if (SFX_DIR_PATH != null && SFX_DIR_PATH != ""):
		self.preload_resources_from_dir(SFX_DIR_PATH);
	if (MFX_DIR_PATH != null && MFX_DIR_PATH != ""):
		self.preload_resources_from_dir(MFX_DIR_PATH);
#end

func preinstance_nodes() -> void:
	if (BGS_DIR_PATH != null && BGS_DIR_PATH != ""):
		bgs_playing.remove(0);
		BGS_Audiostreams.remove(0);
		$BackgroundSounds.get_children()[0].free();
		preinstantiate_nodes_from_dir(BGS_DIR_PATH, "BGS");
	if (SFX_DIR_PATH != null && SFX_DIR_PATH != ""):
		se_playing.remove(0);
		SE_Audiostreams.remove(0);
		$SoundEffects.get_children()[0].free();
		preinstantiate_nodes_from_dir(SFX_DIR_PATH, "SFX");
	if (MFX_DIR_PATH != null && MFX_DIR_PATH != ""):
		se_playing.remove(0);
		ME_Audiostreams.remove(0);
		$MusicEffects.get_children()[0].free();
		preinstantiate_nodes_from_dir(MFX_DIR_PATH, "MFX");
#end

func is_audio_file(file_name : String) -> bool:
	return	(file_name.get_extension() == "wav" ||
			file_name.get_extension() == "ogg" ||
			file_name.get_extension() == "opus");
#end

func is_import_file(file_name : String) -> bool:
	return (file_name.get_extension() == "import" &&
			self.is_audio_file(file_name.get_basename()));
#end
