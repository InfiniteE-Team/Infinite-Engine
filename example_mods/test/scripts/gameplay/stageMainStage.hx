function postCreate() {
    if (SONG.stage != 'mainStageErect')
        return;

	var adjustColorbf = CustomShader.loadShader('adjust-color');
	var adjustColordad = CustomShader.loadShader('adjust-color');
	var adjustColorgf = CustomShader.loadShader('adjust-color');

	adjustColorbf.setFloat('brightness', -23);
	adjustColorbf.setFloat('hue', 12);
	adjustColorbf.setFloat('contrast', 7);
	adjustColorbf.setFloat('saturation', 0);

    adjustColorgf.setFloat('brightness', -30);
	adjustColorgf.setFloat('hue', -9);
	adjustColorgf.setFloat('contrast', -4);
	adjustColorgf.setFloat('saturation', 0);

    adjustColordad.setFloat('brightness', -33);
	adjustColordad.setFloat('hue', -32);
	adjustColordad.setFloat('contrast', -23);
	adjustColordad.setFloat('saturation', 0);

    for (layer in chars.get('gf').layers)
        layer.shader = adjustColorgf;

	for (layer in chars.get('bf').layers)
        layer.shader = adjustColorbf;

    for (layer in chars.get('dad').layers)
        layer.shader = adjustColordad;
}
