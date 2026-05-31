package utils;

class Trace {
	static var messages:Array<String> = [];

	public static function traceOnce(text:String) {
		if (messages.contains(text))
			return;

		messages.push(text);
/*
        // info for traces
		var stack = haxe.CallStack.callStack();
        var stackStr = haxe.CallStack.toString(stack);

        //trace(stackStr + "stack trace above:");*/

		trace(/*stackStr + */text);
	}

    public static function clear() {
        messages = [];
    }
}
