import Foundation

enum ShaderSource {
    static let library = """
    #include <metal_stdlib>
    using namespace metal;

    struct Uniforms {
        float4 resolutionTime;
        float4 feedbackSource;
        float4 motion;
        float4 symmetry;
        float4 optics;
        float4 colorA;
        float4 colorB;
        float4 signalA;
        float4 signalB;
        float4 finishA;
        float4 finishB;
        float4 finishC;
        float4 modes;
        float4 audio;
    };

    struct VertexOut {
        float4 position [[position]];
        float2 uv;
    };

    vertex VertexOut passthroughVertex(uint vertexID [[vertex_id]]) {
        float2 positions[6] = {
            float2(-1.0, -1.0),
            float2(1.0, -1.0),
            float2(-1.0, 1.0),
            float2(-1.0, 1.0),
            float2(1.0, -1.0),
            float2(1.0, 1.0)
        };

        float2 uvs[6] = {
            float2(0.0, 1.0),
            float2(1.0, 1.0),
            float2(0.0, 0.0),
            float2(0.0, 0.0),
            float2(1.0, 1.0),
            float2(1.0, 0.0)
        };

        VertexOut out;
        out.position = float4(positions[vertexID], 0.0, 1.0);
        out.uv = uvs[vertexID];
        return out;
    }

    float2 rotate2(float2 p, float angle) {
        float s = sin(angle);
        float c = cos(angle);
        return float2(c * p.x - s * p.y, s * p.x + c * p.y);
    }

    float hash21(float2 p) {
        p = fract(p * float2(123.34, 456.21));
        p += dot(p, p + 45.32);
        return fract(p.x * p.y);
    }

    float noise2d(float2 p) {
        float2 i = floor(p);
        float2 f = fract(p);
        float a = hash21(i);
        float b = hash21(i + float2(1.0, 0.0));
        float c = hash21(i + float2(0.0, 1.0));
        float d = hash21(i + float2(1.0, 1.0));
        float2 u = f * f * (3.0 - 2.0 * f);
        return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
    }

    float fbm(float2 p) {
        float sum = 0.0;
        float amplitude = 0.5;
        for (int i = 0; i < 5; ++i) {
            sum += noise2d(p) * amplitude;
            p = p * 2.02 + float2(18.7, 9.2);
            amplitude *= 0.52;
        }
        return sum;
    }

    float3 palette(float t) {
        float3 a = float3(0.52, 0.45, 0.48);
        float3 b = float3(0.48, 0.42, 0.44);
        float3 c = float3(1.0, 1.0, 1.0);
        float3 d = float3(0.01, 0.21, 0.39);
        return a + b * cos(6.2831853 * (c * t + d));
    }

    float3 paletteMode(float t, float mode, float reactivePulse) {
        float3 spectral = palette(t);

        if (mode < 0.5) {
            return spectral;
        }

        if (mode < 1.5) {
            float3 minter = 0.5 + 0.5 * cos(6.2831853 * (float3(0.02, 0.34, 0.67) + t * 1.18 + float3(0.0, 0.16, 0.33)));
            minter = pow(minter, float3(0.62));
            minter += reactivePulse * float3(0.36, 0.18, 0.52);
            return saturate(minter);
        }

        if (mode < 2.5) {
            float3 prismIce = float3(0.12, 0.42, 0.82) + float3(0.48, 0.50, 0.22) * cos(6.2831853 * (t + float3(0.0, 0.22, 0.46)));
            return saturate(prismIce + reactivePulse * 0.18);
        }

        if (mode < 3.5) {
            float3 lavaChrome = float3(0.54, 0.08, 0.02) + float3(0.42, 0.30, 0.62) * cos(6.2831853 * (t * 1.05 + float3(0.0, 0.18, 0.44)));
            return saturate(lavaChrome + reactivePulse * float3(0.18, 0.08, 0.22));
        }

        float mono = saturate(t);
        float3 lumaGhost = mix(float3(0.04, 0.06, 0.08), float3(0.92, 0.96, 1.0), mono);
        lumaGhost += reactivePulse * float3(0.08, 0.18, 0.24);
        return saturate(lumaGhost);
    }

    float3 hueRotate(float3 color, float angle) {
        float s = sin(angle);
        float c = cos(angle);
        float3x3 matrix = float3x3(
            float3(0.299 + 0.701 * c + 0.168 * s, 0.587 - 0.587 * c + 0.330 * s, 0.114 - 0.114 * c - 0.497 * s),
            float3(0.299 - 0.299 * c - 0.328 * s, 0.587 + 0.413 * c + 0.035 * s, 0.114 - 0.114 * c + 0.292 * s),
            float3(0.299 - 0.300 * c + 1.250 * s, 0.587 - 0.588 * c - 1.050 * s, 0.114 + 0.886 * c - 0.203 * s)
        );
        return saturate(matrix * color);
    }

    float2 foldKaleidoscope(float2 p, float segments) {
        if (segments < 1.5) {
            return p;
        }

        float radius = length(p);
        float angle = atan2(p.y, p.x);
        float halfSector = 3.14159265 / max(segments, 1.0);
        angle = fmod(angle, halfSector * 2.0);
        angle = abs(angle - halfSector);
        return float2(cos(angle), sin(angle)) * radius;
    }

    float3 sourceField(float2 p, float time, constant Uniforms& u) {
        float reactive = u.modes.y * u.modes.z;
        float detail = max(u.finishC.w, 0.1);
        float pulseDrive = mix(u.finishC.x, u.audio.y, reactive);
        float shimmerDrive = mix(0.0, u.audio.z, reactive);
        float radius = length(p) + 0.001;
        float angle = atan2(p.y, p.x);
        float plasma = sin(p.x * (8.0 + detail * 8.0 + shimmerDrive * 8.0) + time * (1.7 + pulseDrive * 2.0))
            + sin(p.y * (11.0 + detail * 7.0) - time * (1.1 + reactive * 1.6))
            + sin((p.x + p.y) * (7.0 + detail * 6.0) + time * (0.7 + shimmerDrive));
        float tunnel = sin((12.0 + detail * 20.0 + pulseDrive * 28.0) / radius + angle * (5.0 + reactive * 3.0) - time * (4.0 + pulseDrive * 5.0));
        float twister = sin(p.y * (18.0 + detail * 24.0) + time * (5.4 + reactive * 3.2) + sin(p.x * 5.0 + time) * (5.0 + shimmerDrive * 4.0));
        float raster = sin((p.y + sin(p.x * 6.0 + time) * 0.03) * (90.0 + detail * 180.0 + pulseDrive * 120.0) + time * (8.0 + reactive * 4.0));
        float rings = sin(radius * (26.0 + detail * 24.0 + shimmerDrive * 18.0) - time * (4.5 + reactive * 3.0) + fbm(p * 2.8) * (5.0 + shimmerDrive * 3.0));
        float moire = sin((p.x * 120.0 + sin(time * 2.0) * 20.0) * (p.y * 80.0 + cos(time * 1.4) * 15.0 + pulseDrive * 12.0));

        float2 z = p * (2.8 + detail * 4.8);
        float fractal = 0.0;
        for (int i = 0; i < 4; ++i) {
            z = abs(z) / clamp(dot(z, z), 0.18, 4.0) - 0.86;
            fractal += exp(-4.2 * abs(length(z) - 0.9));
        }

        float2 cell = floor((p + 1.8) * (18.0 + detail * 18.0));
        float xorish = sin((cell.x + fmod(cell.x + cell.y, 2.0) * cell.y) * 0.32 + time * 4.5);
        float noiseField = fbm(p * 4.5 + time * 0.2);

        float signal = 0.0;
        signal += plasma * u.signalA.x;
        signal += tunnel * u.signalA.y;
        signal += twister * u.signalA.z;
        signal += raster * u.signalA.w;
        signal += rings * u.signalB.x;
        signal += moire * u.signalB.y;
        signal += fractal * u.signalB.z;
        signal += noiseField * u.signalB.w;
        signal += xorish * u.finishA.x;
        signal /= max(
            1.0,
            u.signalA.x + u.signalA.y + u.signalA.z + u.signalA.w +
            u.signalB.x + u.signalB.y + u.signalB.z + u.signalB.w + u.finishA.x
        );

        float pulse = sin(time * (2.4 + u.finishC.x * 12.0 + pulseDrive * 10.0) + radius * (6.0 + reactive * 5.0) + u.audio.w * 6.2831853) * 0.5 + 0.5;
        float shimmer = fbm(p * (6.0 + detail * 10.0 + shimmerDrive * 8.0) + time * (0.15 + reactive * 0.2));
        float t = signal * 0.5 + 0.5 + pulse * (0.14 + reactive * 0.18) + shimmer * (0.22 + reactive * 0.12) + reactive * u.audio.x * 0.24;
        return paletteMode(t, u.modes.x, reactive * (u.audio.y + u.audio.z * 0.6));
    }

    float3 sampleFeedback(texture2d<float> prevTexture, sampler linearSampler, float2 p, float2 res, float fieldValue, constant Uniforms& u) {
        float reactive = u.modes.y * u.modes.z;
        float2 aspect = float2(res.x / max(res.y, 1.0), 1.0);
        float radius = length(p);
        float angle = atan2(p.y, p.x);
        float2 vortex = normalize(float2(-p.y, p.x) + 0.0001);

        float2 warped = rotate2(p, u.feedbackSource.w + fieldValue * 0.08);
        warped *= 1.0 / max(0.36, u.feedbackSource.z);
        warped += u.motion.xy * 0.12;
        warped += vortex * u.motion.z * (0.04 + radius * 0.08);
        warped += float2(sin(p.y * 6.0 + u.resolutionTime.z * 1.8), cos(p.x * 7.0 - u.resolutionTime.z * 1.3)) * u.motion.w * 0.03;
        warped += fieldValue * u.finishB.z * 0.08;
        warped += float2(cos(angle * max(u.optics.x, 1.0) + u.resolutionTime.z), sin(angle * max(u.optics.x, 1.0) - u.resolutionTime.z)) * u.symmetry.w * 0.05;
        warped += float2(cos(u.audio.w * 6.2831853 + angle), sin(u.audio.w * 6.2831853 - angle)) * reactive * u.audio.y * 0.05;
        warped = mix(warped, float2(abs(warped.x), abs(warped.y)), saturate(u.symmetry.y));

        float2 uv = warped / aspect + 0.5;
        uv = clamp(uv, 0.001, 0.999);
        float split = u.colorB.y;
        float2 offset = float2(split, split * 0.58);

        float r = prevTexture.sample(linearSampler, clamp(uv + offset, 0.001, 0.999)).r;
        float g = prevTexture.sample(linearSampler, uv).g;
        float b = prevTexture.sample(linearSampler, clamp(uv - offset, 0.001, 0.999)).b;
        float3 feedback = float3(r, g, b);

        float3 echoes = float3(0.0);
        if (u.optics.w > 0.001) {
            for (int i = 1; i <= 3; ++i) {
                float factor = float(i) / 3.0;
                float2 echoUV = clamp(uv + vortex * u.optics.w * 0.024 * factor + float2(fieldValue, -fieldValue) * 0.015 * factor, 0.001, 0.999);
                echoes += prevTexture.sample(linearSampler, echoUV).rgb * (0.16 / factor);
            }
        }

        return feedback + echoes * u.optics.w;
    }

    fragment float4 feedbackFragment(
        VertexOut in [[stage_in]],
        texture2d<float> prevTexture [[texture(0)]],
        sampler linearSampler [[sampler(0)]],
        constant Uniforms& u [[buffer(0)]]
    ) {
        float2 res = u.resolutionTime.xy;
        float time = u.resolutionTime.z;
        float reactive = u.modes.y * u.modes.z;

        float2 uv = in.uv;
        if (u.finishC.z > 0.001) {
            float grid = mix(res.x, 42.0, saturate(u.finishC.z));
            uv = (floor(uv * grid) + 0.5) / grid;
        }

        float2 aspect = float2(res.x / max(res.y, 1.0), 1.0);
        float2 p = (uv - 0.5) * aspect;
        p = rotate2(p, u.feedbackSource.w * 0.45);
        p = foldKaleidoscope(p, floor(u.symmetry.x + 0.5));
        p = mix(p, float2(cos(atan2(p.y, p.x) * max(u.optics.x, 1.0)), sin(atan2(p.y, p.x) * max(u.optics.x, 1.0))) * length(p), saturate(u.symmetry.z * 0.35));
        p += float2(sin(p.y * 3.0 + time * 1.2), cos(p.x * 4.0 - time * 0.9)) * u.motion.w * 0.04;

        float3 source = sourceField(p, time, u);
        float fieldValue = dot(source, float3(0.2126, 0.7152, 0.0722));
        float2 refractOffset = float2(cos(fieldValue * 6.2831853 + time + u.audio.w * 6.2831853), sin(fieldValue * 6.2831853 - time - u.audio.w * 3.1415926)) * u.optics.y * (0.05 + reactive * 0.03);
        float3 feedback = sampleFeedback(prevTexture, linearSampler, p + refractOffset, res, fieldValue, u);
        float3 reflection = sampleFeedback(prevTexture, linearSampler, float2(-p.x, p.y), res, fieldValue, u) * u.optics.z;

        float2 texel = 1.0 / max(res, 1.0);
        float3 glow = float3(0.0);
        glow += prevTexture.sample(linearSampler, clamp(uv + float2(texel.x, 0.0), 0.001, 0.999)).rgb;
        glow += prevTexture.sample(linearSampler, clamp(uv + float2(-texel.x, 0.0), 0.001, 0.999)).rgb;
        glow += prevTexture.sample(linearSampler, clamp(uv + float2(0.0, texel.y), 0.001, 0.999)).rgb;
        glow += prevTexture.sample(linearSampler, clamp(uv + float2(0.0, -texel.y), 0.001, 0.999)).rgb;
        glow *= 0.25;

        float strobeGate = 1.0;
        if (u.finishC.y > 0.001) {
            float pulse = fract(time * (4.0 + u.finishC.x * 12.0 + reactive * u.audio.y * 8.0) + u.audio.w);
            strobeGate = mix(1.0, step(0.28, pulse), saturate(u.finishC.y));
        }

        float3 combined = source * u.feedbackSource.y + feedback * u.feedbackSource.x + reflection * 0.28;
        combined += (glow - feedback) * u.finishA.w * 0.48;
        combined = mix(combined, source + feedback * 0.72, saturate(u.motion.z * 0.3 + u.optics.w * 0.4));
        combined *= mix(1.0, 0.55 + strobeGate * 0.65, saturate(u.finishC.y));
        combined += reactive * u.audio.z * 0.12;
        combined *= 1.0 + reactive * u.audio.y * 0.26;

        float luma = dot(combined, float3(0.2126, 0.7152, 0.0722));
        combined = mix(combined, float3(luma), saturate(u.colorB.z * 0.68));
        combined = hueRotate(combined, u.colorA.x * 6.2831853);

        float average = (combined.r + combined.g + combined.b) / 3.0;
        combined = mix(float3(average), combined, max(u.colorA.y, 0.0));
        combined = (combined - 0.5) * u.colorA.z + 0.5;
        combined += u.colorA.w;
        combined = pow(saturate(combined), float3(max(u.colorB.x, 0.05)));

        float scan = sin(uv.y * res.y * 1.1 + time * 1.2) * 0.5 + 0.5;
        combined *= 1.0 - scan * u.finishA.y * 0.18;

        float grain = (hash21(uv * res + time) - 0.5) * u.finishA.z;
        combined += grain;

        if (u.modes.x > 0.5 && u.modes.x < 1.5) {
            combined = pow(saturate(combined), float3(0.82));
            combined += reactive * u.audio.x * float3(0.08, 0.02, 0.12);
        }

        if (u.colorB.w > 0.001) {
            combined = mix(combined, 1.0 - combined, saturate(u.colorB.w));
        }

        float vignette = smoothstep(1.28, 0.18, length((uv - 0.5) * 2.0));
        combined *= mix(1.0, vignette, saturate(u.finishB.y));
        combined *= 0.92 + u.finishC.w * 0.18;

        return float4(saturate(combined), 1.0);
    }

    fragment float4 copyFragment(
        VertexOut in [[stage_in]],
        texture2d<float> sceneTexture [[texture(0)]],
        sampler linearSampler [[sampler(0)]]
    ) {
        return float4(sceneTexture.sample(linearSampler, in.uv).rgb, 1.0);
    }
    """
}
