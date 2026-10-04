package game.controllers;

import game.objects.sprites.notes.Note;
import modding.scripting.ScriptHandler;

class NoteTypeManager {
    var handlers:Map<String, ScriptHandler> = [];

    public function new() {}

    public function initFromNotes(notes:Array<Dynamic>):Void {
        for (data in notes) {
            var type:String = data.type ?? 'normal';
            if (type == 'normal' || type == '' || handlers.exists(type))
                continue;

            var path = Paths.getPath('notetypes/$type', 'script');
            if (path == null || !sys.FileSystem.exists(path))
                continue;

            var handler = new ScriptHandler(null);
            handler.load(path);
            handler.executeAll();
            handler.call('onCreate', []);
            handlers.set(type, handler);
        }
    }

    public function onNoteHit(note:Note):Void {
        var handler = handlers.get(note.noteType);
        if (handler != null)
            handler.call('onNoteHit', [note]);
    }

    public function onNoteMiss(note:Note):Void {
        var handler = handlers.get(note.noteType);
        if (handler != null)
            handler.call('onNoteMiss', [note]);
    }

    public function onNoteGenerate(note:Note):Void {
        var handler = handlers.get(note.noteType);
        if (handler != null)
            handler.call('onNoteGenerate', [note]);
    }

    public function destroy():Void {
        for (handler in handlers)
            handler.destroy();
        handlers = null;
    }
}