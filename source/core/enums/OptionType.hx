package core.enums;

enum OptionType {
	CHECKBOX;
	NUMBER(min:Float, max:Float, step:Float);
	STRING(options:Array<String>);
}
