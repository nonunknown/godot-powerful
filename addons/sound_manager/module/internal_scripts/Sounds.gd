extends AudioStreamPlayer

####################################################################
#SOUNDS SCRIPT FOR THE SOUND MANAGER MODULE FOR GODOT 3.1
#			© Xecestel
####################################################################
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
#####################################

#signals#
signal finished_playing(sound_name);
#########

#constants#
enum Type { BGS, SE, ME };
##########

#variables#
var type = Type.BGS;
var sound_name;
###########

func _ready():
	self.set_properties();
#end

func set_sound_name(sound_name : String) -> void:
	self.sound_name = sound_name;
#end

func connect_signals(connect_to : Node) -> void:
	self.connect("finished", self, "_on_self_finished");
	if (self.type == Type.SE):
		self.connect("finished_playing", connect_to, "_on_SE_finished" );
	elif (self.type == Type.BGS):
		self.connect("finished_playing", connect_to, "_on_BGS_finished" );
	elif (self.type == Type.ME):
		self.connect("finished_playing", connect_to, "_on_ME_finished" );
#end

func set_properties(volume_db : float = 0.0, pitch_scale : float = 1.0) -> void:
	self.set_volume_db(volume_db);
	self.set_pitch_scale(pitch_scale);
#end

func set_type (type : String) -> void:
	if (type == "BGS"):
		self.type = Type.BGS;
	elif (type == "SE"):
		self.type = Type.SE;
	elif (type == "ME"):
		self.type = Type.ME;
#end

func _on_self_finished() -> void:
	emit_signal("finished_playing", self.sound_name);
#end
