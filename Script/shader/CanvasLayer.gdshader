// Godot 4 CRT Shader (V2.0 - 已修正语法)
shader_type canvas_item;

// --- 可在编辑器中调整的参数 ---
uniform float scanline_intensity: hint_range(0.0, 1.0) = 0.05; // 扫描线强度 或 扫描线暗度
uniform float barrel_distortion: hint_range(0.0, 0.5) = 0.02; // 桶形畸变 或 画面凸起度
uniform float chromatic_abberation: hint_range(0.0, 0.05) = 0.05; //色差 或 色彩分离度
uniform float noise_intensity: hint_range(0.0, 0.2) = 0.1; //噪点强度 或 信号干扰度
uniform float scanline_count: hint_range(100.0, 1000.0) = 400.0; // 【新增】扫描线数量

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;


float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 centered_uv = SCREEN_UV - 0.5;

    // --- 1. 桶形畸变 ---
    float r2 = dot(centered_uv, centered_uv);
    vec2 distorted_uv = centered_uv * (1.0 - r2 * barrel_distortion);
    distorted_uv += 0.5;

    // --- 2. 色差 ---
    vec2 offset = centered_uv * chromatic_abberation;
    float r = texture(SCREEN_TEXTURE, distorted_uv - offset).r;
    float g = texture(SCREEN_TEXTURE, distorted_uv).g;
    float b = texture(SCREEN_TEXTURE, distorted_uv + offset).b;
    vec3 final_color = vec3(r, g, b);

    // --- 3. 扫描线 ---
    // 【核心修正】我们不再使用 VIEWPORT_SIZE
    // 而是直接用 UV 坐标乘以一个可调的“扫描线数量”参数
    float scanline = sin(distorted_uv.y * scanline_count);
    // 将扫描线叠加上去 (乘以颜色，使其变暗)
    final_color *= 1.0 - scanline * scanline_intensity;

    // --- 4. 噪点 ---
    float noise = (random(SCREEN_UV + mod(TIME, 10.0)) - 0.5) * noise_intensity;
    final_color += noise;

    // 将最终计算出的颜色输出到屏幕
    COLOR = vec4(final_color, 1.0);
}