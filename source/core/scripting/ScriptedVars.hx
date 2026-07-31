package core.scripting;

import game.PlayState;

class ScriptedVars {
	public function new() {}

	public static function gameplayVars(script:ScriptHandler, game:PlayState) {
		script.expose('SONG', PlayState.SONG);
		script.expose('instance', PlayState.instance);
		script.expose('health', game.playStateConfig.health);

		script.expose('healthBarBG', game.controllerHUD.healthBarBG);
		script.expose('healthBar', game.controllerHUD.healthBar);
		script.expose('healthBarY', game.controllerHUD.healthBarY);
		script.expose('iconP1', game.controllerHUD.iconP1);
		script.expose('iconP2', game.controllerHUD.iconP2);
		script.expose('skipCountdown', game.countDown.skipCountdown);

		script.expose('strumsByChar', game.noteController.strumsByChar);

	}
}
