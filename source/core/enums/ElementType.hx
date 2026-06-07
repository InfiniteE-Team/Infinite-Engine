package core.enums;

@:enum abstract ElementType(String) from String to String {
	var Sprite = "sprite";
	var Animated = "animated";
	var Graphic = "graphic";
	var Group = "group";
	var Sound = "sound";
	var CustomClass = "custom_class";
	var CustomClassGroup = "custom_class_group";
	var Character = "character";
}