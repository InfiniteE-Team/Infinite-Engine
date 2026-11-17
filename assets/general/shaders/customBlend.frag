#pragma header

uniform sampler2D sourceSwag;
uniform sampler2D backgroundSwag;
uniform int blendMode;

vec3 blendOverlay(vec3 base, vec3 blend) {
    return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), step(vec3(0.5), base));
}

vec3 blendHardLight(vec3 base, vec3 blend) {
    return blendOverlay(blend, base);
}

vec3 blendDarken(vec3 base, vec3 blend) {
    return min(base, blend);
}

vec3 blendLighten(vec3 base, vec3 blend) {
    return max(base, blend);
}

vec3 blendDifference(vec3 base, vec3 blend) {
    return abs(base - blend);
}

vec3 blendExclusion(vec3 base, vec3 blend) {
    return base + blend - 2.0 * base * blend;
}

vec3 rgb2hsl(vec3 c) {
    float maxC = max(c.r, max(c.g, c.b));
    float minC = min(c.r, min(c.g, c.b));
    float delta = maxC - minC;
    float l = (maxC + minC) / 2.0;
    float s = 0.0;
    if(delta > 0.0)
        s = delta / (1.0 - abs(2.0 * l - 1.0));
    float h = 0.0;
    if(delta > 0.0) {
        if(maxC == c.r)
            h = mod((c.g - c.b) / delta, 6.0);
        else if(maxC == c.g)
            h = (c.b - c.r) / delta + 2.0;
        else
            h = (c.r - c.g) / delta + 4.0;
        h /= 6.0;
    }
    return vec3(h, s, l);
}

float hue2rgb(float p, float q, float t) {
    if(t < 0.0)
        t += 1.0;
    if(t > 1.0)
        t -= 1.0;
    if(t < 1.0 / 6.0)
        return p + (q - p) * 6.0 * t;
    if(t < 0.5)
        return q;
    if(t < 2.0 / 3.0)
        return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
    return p;
}

vec3 hsl2rgb(vec3 hsl) {
    float h = hsl.x, s = hsl.y, l = hsl.z;
    if(s == 0.0)
        return vec3(l);
    float q = l < 0.5 ? l * (1.0 + s) : l + s - l * s;
    float p = 2.0 * l - q;
    return vec3(hue2rgb(p, q, h + 1.0 / 3.0), hue2rgb(p, q, h), hue2rgb(p, q, h - 1.0 / 3.0));
}

float lum(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 clipColor(vec3 c) {
    float l = lum(c);
    float n = min(c.r, min(c.g, c.b));
    float x = max(c.r, max(c.g, c.b));
    if(n < 0.0)
        c = l + (c - l) * l / (l - n);
    if(x > 1.0)
        c = l + (c - l) * (1.0 - l) / (x - l);
    return c;
}

vec3 setLum(vec3 c, float l) {
    float d = l - lum(c);
    return clipColor(c + d);
}

vec3 setSat(vec3 c, float s) {
    float cMin = min(c.r, min(c.g, c.b));
    float cMax = max(c.r, max(c.g, c.b));
    if(cMax > cMin) {
        c = (c - cMin) * s / (cMax - cMin);
    } else {
        c = vec3(0.0);
    }
    return c;
}

vec3 blendHue(vec3 base, vec3 blend) {
    return setLum(setSat(blend, length(base - vec3(lum(base)))), lum(base));
}

vec3 blendSaturation(vec3 base, vec3 blend) {
    return setLum(setSat(base, length(blend - vec3(lum(blend)))), lum(base));
}

vec3 blendColor(vec3 base, vec3 blend) {
    return setLum(blend, lum(base));
}

vec3 blendLuminosity(vec3 base, vec3 blend) {
    return setLum(base, lum(blend));
}

vec3 blendInvert(vec3 base, vec3 blend) {
    return 1.0 - blend;
}

void main() {
    vec2 uv = openfl_TextureCoordv;

    vec4 src = texture2D(sourceSwag, uv);
    vec4 bg = texture2D(backgroundSwag, uv);

    vec3 srcRgb = src.a > 0.0 ? src.rgb / src.a : vec3(0.0);
    vec3 bgRgb = bg.a > 0.0 ? bg.rgb / bg.a : vec3(0.0);

    vec3 blended;

    // NORMAL=0, ADD=1, MULTIPLY=2, SCREEN=3, OVERLAY=4, HARDLIGHT=5,
    // DARKEN=6, LIGHTEN=7, DIFFERENCE=8, EXCLUSION=9,
    // HUE=10, SATURATION=11, COLOR=12, LUMINOSITY=13, INVERT=14
    if(blendMode == 4)
        blended = blendOverlay(bgRgb, srcRgb);
    else if(blendMode == 5)
        blended = blendHardLight(bgRgb, srcRgb);
    else if(blendMode == 6)
        blended = blendDarken(bgRgb, srcRgb);
    else if(blendMode == 7)
        blended = blendLighten(bgRgb, srcRgb);
    else if(blendMode == 8)
        blended = blendDifference(bgRgb, srcRgb);
    else if(blendMode == 9)
        blended = blendExclusion(bgRgb, srcRgb);
    else if(blendMode == 10)
        blended = blendHue(bgRgb, srcRgb);
    else if(blendMode == 11)
        blended = blendSaturation(bgRgb, srcRgb);
    else if(blendMode == 12)
        blended = blendColor(bgRgb, srcRgb);
    else if(blendMode == 13)
        blended = blendLuminosity(bgRgb, srcRgb);
    else if(blendMode == 14)
        blended = blendInvert(bgRgb, srcRgb);
    else
        blended = srcRgb; // fallback: NORMAL

    float outA = src.a + bg.a * (1.0 - src.a);
    vec3 outC = outA > 0.0 ? (blended * src.a + bgRgb * bg.a * (1.0 - src.a)) / outA : vec3(0.0);

    gl_FragColor = vec4(outC, outA);
}