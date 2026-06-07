#pragma header

uniform vec4 noteColor;

void main() {
	vec4 texColor = flixel_texture2D(bitmap, openfl_TextureCoordv);

	if (texColor.a > 0.0) {
		texColor.rgb = texColor.rgb * noteColor.rgb;
	}
	
	gl_FragColor = texColor;
}
