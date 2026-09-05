import flixel.util.FlxColor;

function onStepHit(step) {
	switch (step) {
		case 416:
			var grayGame = CustomShader.applyToCamera('gray', camGame);
			var grayHUD = CustomShader.applyToCamera('gray', camHUD);

			grayGame.setFloat('grey', 1.0);
			grayHUD.setFloat('grey', 1.0);

			FlxG.camera.flash(FlxColor.WHITE, 0.5);
			stage.getObject('stageback').destroy();
			stage.getObject('stage_light_LEFT').destroy();
			stage.getObject('stage_light_RIGHT').destroy();
			stage.getObject('stagefront').destroy();
			stage.getObject('stagecurtains').destroy();
			cameraController.defaultZoom = 0.4;
	}
}
