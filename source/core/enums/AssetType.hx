package core.enums;

enum abstract AssetType(String) from String to String {
    var DATA = "data";
    var JSON = "json";
    var FONT = "font";
    var IMAGE = "image";
    var SOUND = "sound";
    var MUSIC = "music";
    var SONG_AUDIO = "songAudio";
    var ANIMATED = "animated";
    var XML = "xml";
    var SONG_SCRIPT = "songScript";
    var SHADERS = "shaders";
    var STATE = "state";
    var STATES = "states";
    var SUBSTATE = "substate";
    var SUBSTATES = "substates";
    var SCRIPT = "script";
    var DEFAULT = "default";
}