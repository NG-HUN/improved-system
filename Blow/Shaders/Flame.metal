#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// ---------- noise ----------
static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float vnoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float a = hash21(i);
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

static float fbm(float2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * vnoise(p);
        p *= 2.03;
        a *= 0.5;
    }
    return v;
}

// ---------- candle flame ----------
// Drawn into a rectangle. The wick sits at 10% from the bottom, centred.
//  sway      : bend of the tip, roughly radians (+ = tip to the right)
//  intensity : 0 = out, 1 = fully lit (ignite / extinguish ramps)
//  seed      : per-candle randomness
//  agitation : 0 calm … 1 strongly disturbed (being blown at)
[[ stitchable ]] half4 candleFlame(float2 position, half4 color,
                                   float2 size, float time, float sway,
                                   float intensity, float seed, float agitation) {
    if (intensity <= 0.001) { return half4(0.0); }

    float2 uv = position / size;
    float h = 1.0 - uv.y;               // 0 at bottom, 1 at top
    float x = uv.x - 0.5;
    float t = time + seed * 17.0;

    // breathing height
    float flick = fbm(float2(seed * 3.1, t * 2.1));
    float jitter = (vnoise(float2(t * 9.0, seed * 5.0)) - 0.5) * agitation;
    float heightScale = intensity * (0.82 + 0.22 * flick + 0.25 * jitter);

    float base = 0.10;
    float top = base + 0.70 * heightScale;
    float s = (h - base) / max(top - base, 0.001);
    float sc = clamp(s, 0.0, 1.0);

    // bending: steady sway grows with height, turbulence near the tip
    float wob = (fbm(float2(h * 3.0 - t * 3.0, seed * 7.0 + t * 0.5)) - 0.5)
                * (0.06 + 0.16 * agitation) * smoothstep(0.15, 1.0, sc);
    float bend = sway * 0.30 * sc * sc + wob;
    float xs = x - bend;

    // teardrop profile: round bottom, tapered top
    float b = clamp(sc / 0.40, 0.0, 1.0);
    float roundBottom = sqrt(max(1.0 - (1.0 - b) * (1.0 - b), 0.0));
    float w = 0.19 * roundBottom * pow(max(1.0 - sc, 0.0), 0.95)
              * (0.80 + 0.20 * intensity) + 0.0001;

    float f = 1.0 - abs(xs) / w;        // 1 at centre, 0 at edge
    float inside = step(0.0, s) * step(s, 1.0);
    float body = smoothstep(0.0, 0.42, f) * inside;
    body *= 1.0 - smoothstep(0.80, 1.0, sc) * 0.55;

    float core = smoothstep(0.30, 0.95, f) * (1.0 - smoothstep(0.12, 0.70, sc));

    // palette — warm, honey, not neon
    float3 deep  = float3(0.93, 0.33, 0.07);
    float3 amber = float3(1.00, 0.60, 0.20);
    float3 gold  = float3(1.00, 0.84, 0.50);
    float3 cream = float3(1.00, 0.97, 0.88);

    float3 col = mix(deep, amber, smoothstep(0.0, 0.45, f));
    col = mix(col, gold, smoothstep(0.30, 0.90, f) * (1.0 - 0.55 * sc));
    col = mix(col, cream, core * 0.9);

    // faint blue at the root
    float blue = (1.0 - smoothstep(0.0, 0.20, sc)) * smoothstep(0.0, 0.6, f) * (1.0 - core);
    col = mix(col, float3(0.40, 0.48, 1.0), blue * 0.5);

    // tip cools to deep orange
    col = mix(col, float3(0.86, 0.28, 0.06), smoothstep(0.55, 1.0, sc) * (1.0 - f) * 0.6);

    float a = clamp(body * intensity, 0.0, 1.0);

    // soft halo around the flame
    float2 gp = float2(xs, (h - (base + 0.32 * heightScale)) * 0.55);
    float g = exp(-dot(gp, gp) * 22.0) * 0.60 * intensity;
    g *= smoothstep(0.5, 0.30, abs(x)) * smoothstep(0.0, 0.12, uv.y) * smoothstep(1.0, 0.85, uv.y);
    float3 glowCol = float3(1.0, 0.60, 0.26);

    float3 outC = col * a + glowCol * g * (1.0 - a);
    float outA = a + g * (1.0 - a);
    return half4(half3(outC), half(outA));
}
