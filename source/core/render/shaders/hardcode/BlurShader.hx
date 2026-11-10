package core.render.shaders.hardcode;

class BlurShader extends flixel.system.FlxAssets.FlxShader {
	@:glFragmentSource('
		#pragma header
		uniform float uBlurAmount;
		void main()
		{
			vec2 uv    = openfl_TextureCoordv;
			vec2 texel = vec2(uBlurAmount) / openfl_TextureSize;

			vec4 c = vec4(0.0);

			c += flixel_texture2D(bitmap, uv + texel * vec2(-2.0, -2.0)) *  1.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2(-1.0, -2.0)) *  4.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2( 0.0, -2.0)) *  7.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2( 1.0, -2.0)) *  4.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2( 2.0, -2.0)) *  1.0;

			c += flixel_texture2D(bitmap, uv + texel * vec2(-2.0, -1.0)) *  4.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2(-1.0, -1.0)) * 16.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2( 0.0, -1.0)) * 26.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2( 1.0, -1.0)) * 16.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2( 2.0, -1.0)) *  4.0;

			c += flixel_texture2D(bitmap, uv + texel * vec2(-2.0,  0.0)) *  7.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2(-1.0,  0.0)) * 26.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2( 0.0,  0.0)) * 41.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2( 1.0,  0.0)) * 26.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2( 2.0,  0.0)) *  7.0;

			c += flixel_texture2D(bitmap, uv + texel * vec2(-2.0,  1.0)) *  4.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2(-1.0,  1.0)) * 16.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2( 0.0,  1.0)) * 26.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2( 1.0,  1.0)) * 16.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2( 2.0,  1.0)) *  4.0;

			c += flixel_texture2D(bitmap, uv + texel * vec2(-2.0,  2.0)) *  1.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2(-1.0,  2.0)) *  4.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2( 0.0,  2.0)) *  7.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2( 1.0,  2.0)) *  4.0;
			c += flixel_texture2D(bitmap, uv + texel * vec2( 2.0,  2.0)) *  1.0;

			gl_FragColor = c / 273.0;
		}
	')
	public function new(blurAmount:Float = 3.0) {
		super();
		uBlurAmount.value = [blurAmount];
	}

	public inline function setBlur(amount:Float):Void
		uBlurAmount.value = [amount];
}
