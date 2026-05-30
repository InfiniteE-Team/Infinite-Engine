#pragma header

uniform vec3 r;
uniform vec3 g;
uniform vec3 b;
uniform float mult;
uniform vec2 blocksize;

vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
	vec2 texCoord = coord;
	vec2 blocks = openfl_TextureSize / blocksize;
	if (blocksize.x > 1. && blocksize.y > 1.) texCoord = floor(texCoord * blocks) / blocks;
	
	vec4 color = flixel_texture2D(bitmap, texCoord);
	vec4 newColor = vec4(min(color.r * r + color.g * g + color.b * b, vec3(color.a)), color.a);
	color = mix(color, newColor, mult);
	
	if (!hasTransform)
		return color;

	if (color.a == 0. || mult == 0.)
		return color * openfl_Alphav;

	if (color.a > 0.)
		return vec4(color.rgb, color.a);
	return vec4(0.);
}

void main() {
	gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
}