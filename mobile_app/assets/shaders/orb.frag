#version 460 core

#include <flutter/runtime_effect.glsl>

// ─── Uniforms passed from Dart ───
uniform vec2 uSize;         // widget size in pixels
uniform float uTime;        // animated time
uniform vec3 uColor;        // emotion color (rgb 0-1)
uniform float uState;       // 0=idle, 1=listening, 2=speaking
uniform float uAmplitude;   // 0-1 amplitude (faked or real)

out vec4 fragColor;

// ─── 3D simplex noise (Ashima) ───
vec4 permute(vec4 x) { return mod(((x*34.0)+1.0)*x, 289.0); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float snoise(vec3 v) {
  const vec2 C = vec2(1.0/6.0, 1.0/3.0);
  const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
  vec3 i  = floor(v + dot(v, C.yyy));
  vec3 x0 = v - i + dot(i, C.xxx);
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min(g.xyz, l.zxy);
  vec3 i2 = max(g.xyz, l.zxy);
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1.0 + 3.0 * C.xxx;
  i = mod(i, 289.0);
  vec4 p = permute(permute(permute(
    i.z + vec4(0.0, i1.z, i2.z, 1.0))
    + i.y + vec4(0.0, i1.y, i2.y, 1.0))
    + i.x + vec4(0.0, i1.x, i2.x, 1.0));
  float n_ = 1.0/7.0;
  vec3 ns = n_ * D.wyz - D.xzx;
  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_);
  vec4 x = x_ * ns.x + ns.yyyy;
  vec4 y = y_ * ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);
  vec4 b0 = vec4(x.xy, y.xy);
  vec4 b1 = vec4(x.zw, y.zw);
  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));
  vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
  vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
  vec3 p0 = vec3(a0.xy, h.x);
  vec3 p1 = vec3(a0.zw, h.y);
  vec3 p2 = vec3(a1.xy, h.z);
  vec3 p3 = vec3(a1.zw, h.w);
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
  p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot(m*m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}

// Layered noise
float fbm(vec3 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 3; i++) {
    v += a * snoise(p);
    p *= 2.0;
    a *= 0.5;
  }
  return v;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize.xy;
  vec2 p = uv * 2.0 - 1.0;

  float dist = length(p);
  if (dist > 1.0) {
    fragColor = vec4(0.0);
    return;
  }

  // Fake 3D depth
  float z = sqrt(1.0 - dist * dist);
  vec3 pos = vec3(p, z);

  // Slow rotation
  float rot = uTime * 0.15;
  mat3 rotMat = mat3(
    cos(rot), 0.0, sin(rot),
    0.0,      1.0, 0.0,
    -sin(rot), 0.0, cos(rot)
  );
  pos = rotMat * pos;

  // Noise speed varies by state
  float noiseSpeed = 0.3;
  float noiseScale = 1.5;
  float displaceStrength = 0.15;

  if (uState > 0.5 && uState < 1.5) {
    // Listening — faster, sharper
    noiseSpeed = 0.8;
    displaceStrength = 0.22 + uAmplitude * 0.3;
    noiseScale = 2.0;
  } else if (uState > 1.5) {
    // Speaking — wavy, rhythmic
    noiseSpeed = 0.55;
    displaceStrength = 0.18 + uAmplitude * 0.35;
    noiseScale = 1.8;
  }

  // Layered flowing noise
  float n1 = fbm(pos * noiseScale + vec3(uTime * noiseSpeed, 0.0, 0.0));
  float n2 = fbm(pos * noiseScale * 1.5 + vec3(0.0, uTime * noiseSpeed * 0.7, 0.0));
  float noise = (n1 + n2 * 0.5) * displaceStrength;

  // Distance-based falloff
  float falloff = 1.0 - dist;

  // ── Fresnel rim glow ──
  float fresnel = pow(1.0 - z, 2.5);

  // ── Speaking mode radial ripple ──
  float ripple = 0.0;
  if (uState > 1.5) {
    float ringT = uTime * 1.2 - dist * 3.5;
    ripple = sin(ringT) * 0.5 + 0.5;
    ripple *= (1.0 - dist) * uAmplitude * 1.2;
  }

  // ── Color mixing ──
  vec3 baseColor = uColor;
  vec3 lightColor = mix(baseColor, vec3(1.0), 0.7);
  vec3 deepColor = mix(baseColor, vec3(0.0, 0.0, 0.05), 0.35);

  // Cloud color from noise
  vec3 cloudColor = mix(deepColor, lightColor, smoothstep(-0.4, 0.6, noise));

  // Add fresnel rim
  cloudColor = mix(cloudColor, lightColor, fresnel * 0.6);

  // Add speaking ripple
  cloudColor = mix(cloudColor, vec3(1.0), ripple * 0.4);

  // Bright core near center
  float coreDist = length(p - vec2(-0.08, -0.1));
  float core = smoothstep(0.2, 0.02, coreDist);
  cloudColor = mix(cloudColor, vec3(1.0), core * 0.85);

  // Alpha with soft edge
  float alpha = smoothstep(1.0, 0.75, dist);

  // Extra brightness pulse for listening/speaking
  float statePulse = 0.0;
  if (uState > 0.5) {
    statePulse = uAmplitude * 0.15;
  }
  cloudColor += statePulse;

  fragColor = vec4(cloudColor, alpha);
}