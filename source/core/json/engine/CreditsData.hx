package core.json.engine;

typedef CreditEntry = {
    var entries:Array<CreditHeader>;
}

typedef CreditHeader = {
    var header:String;
    var body:Array<CreditItem>;
}

typedef CreditItem = {
    var line:String;
}