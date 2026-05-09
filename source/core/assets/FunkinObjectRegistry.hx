package core.assets;

class FunkinObjectRegistry extends FunkinSprite {
    public var registry:Map<String, FunkinSprite> = new Map();
    public var id:String;

    public function new(id:String, x:Float, y:Float)
    {
        super(x, y);
        this.id = id;
        registry.set(id, this);
    }

    public function get(id:String):FunkinSprite
    {
        return registry.get(id);
    }

    public function existsId(id:String):Bool
    {
        return registry.exists(id);
    }

    override public function destroy():Void
    {
        registry.remove(id);
        super.destroy();
    }
}