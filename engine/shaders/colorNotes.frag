#pragma header

uniform vec4 noteColor;

void main() {
    vec4 texColor = flixel_texture2D(bitmap, openfl_TextureCoordv);

    if (texColor.a > 0.0) {
        vec3 straight = texColor.rgb / texColor.a;

        straight *= noteColor.rgb;

        texColor.rgb = straight * texColor.a;
    }

    gl_FragColor = texColor;
}