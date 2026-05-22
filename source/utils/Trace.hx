package utils;
class Trace
{
    static var message:Array<String> = [];
    public static function traceOnce(text:String)
    {
        if (!message.contains(text))
        {
            trace(text);
            message.push(text);
        }
    }
}