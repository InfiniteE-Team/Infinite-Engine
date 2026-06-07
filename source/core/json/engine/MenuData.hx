package core.json.engine;

import core.json.extensions.AudioData;
import core.json.extensions.SpriteData.ObjectData;
import core.json.extensions.TweenData;
import core.json.extensions.TweenData.LoopAnimData;
import core.enums.ElementType;

typedef MenuData = {
	var elements:Array<Element>;
}

typedef Element = {
	var type:ElementType;

	// identity
	var ?id:String; // id unique

	var ?props:ObjectData;
	var ?audio:AudioData;

	var ?children:Array<Element>;

	// 
	var ?anchorX:Float; // 0=left  0.5=center  1=right
	var ?anchorY:Float; // 0=top  0.5=center  1=bottom
	var ?pivotX:Float;
	var ?pivotY:Float;

	var ?camera:String;
	var ?clipContent:Bool;

	var ?velocityX:Float;
	var ?velocityY:Float;
	var ?repeatX:Bool;
	var ?repeatY:Bool;

	// animations
	var ?tweenIn:TweenData;
	var ?tweenOut:TweenData;
	var ?loopAnim:LoopAnimData;
	var ?startDelay:Float;
	var ?timeline:String; // group elements to animate together

	// interaction
	var ?focusable:Bool;
	var ?enabled:Bool;
	var ?onClick:String;
	var ?onHover:String;
	var ?navigateTo:String;

	var ?vars:Dynamic;
}