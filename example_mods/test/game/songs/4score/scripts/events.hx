import flixel.util.FlxColor;

function postCreate() {
	modchartSystem.prepareMod('test', () -> new DrunkModifier(), -1);

	modchartSystem.easeMod(104.0, 8.0, FlxEase.linear, {
		test: 0.7
	});
}

function onStepHit(step:Int) {
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
			FlxTween.tween(healthBar, {y: healthBar.y + 600, angle: healthBar.angle + 20}, 1.2);
			FlxTween.tween(healthBarBG, {y: healthBarBG.y + 600, angle: healthBarBG.angle + 20}, 1.2);
			FlxTween.tween(iconP1, {y: iconP1.y + 600, angle: iconP1.angle + 20}, 1.2);
			FlxTween.tween(iconP2, {y: iconP2.y + 600, angle: iconP2.angle + 20}, 1.2);

			cameraController.defaultZoom = 0.4;

			events.triggerEvent('Change Scroll Speed', [3]);

		case 730:
			events.triggerEvent('Change Scroll Speed', [1.0]);
		case 734:
			events.triggerEvent('Change Scroll Speed', [3]);
		case 991:
			FlxG.camera.flash(FlxColor.BLACK, 0.5);
			events.triggerEvent('Change Scroll Speed', [1.0]);
			cameraController.defaultZoom = 0.8;
		case 1065:
			events.triggerEvent('Change Scroll Speed', [0.2]);
			cameraController.defaultZoom = 1.0;
		case 1073:
			events.triggerEvent('Change Scroll Speed', [3.0]);
			cameraController.defaultZoom = 0.4;
	}
}
