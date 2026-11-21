package modding.scripting;

import game.PlayState;

class ScriptedVars {
	public function new() {}

	public static function gameplayVars(script:ScriptHandler, game:PlayState):Void {
		script.expose('SONG', PlayState.SONG);
		script.expose('instance', PlayState.instance);
		script.expose('curSong', game.curSong);

		var hud = game.controllerHUD;
		script.expose('healthBarBG', hud.healthBarBG);
		script.expose('healthBar', hud.healthBar);
		script.expose('healthBarY', hud.healthBarY);
		script.expose('iconP1', hud.iconP1);
		script.expose('iconP2', hud.iconP2);
		script.expose('scoreText', hud.scoreText);
		script.expose('combo', hud.combo);

		script.expose('getStrumline', game.noteController.getStrumline);
		script.expose('boyfriend', game.chars.boyfriend);
		script.expose('dad', game.chars.dad);
		script.expose('gf', game.chars.gf);
	}
}
