// Godot 4 "Ultimate Effects" Shader (CRT + SlowMo)
shader_type canvas_item;

// --- CRT 参数 ---
uniform float scanline_intensity: hint_range(0.0, 1.0) = 0.1;
uniform float barrel_distortion: hint_range(0.0, 0.5) = 0.15;
uniform float chromatic_abberation: hint_range(0.0, 0.05) = 0.005;
uniform float noise_intensity: hint_range(0.0, 0.2) = 0.05;
uniform float scanline_count: hint_range(100.0, 1000.0) = 300.0;

// --- 【新增】SlowMo 参数 ---
// 我们用一个 "effect_mix" 变量来控制 SlowMo 效果的“开启程度” (0=关, 1=完全开启)
uniform float slow_mo_mix: hint_range(0.0, 1.0) = 0.0;
uniform float saturation: hint_range(0.0, 1.0) = 0.5;
uniform float contrast: hint_range(1.0, 2.0) = 1.2;
uniform float vignette_intensity: hint_range(0.0, 1.0) = 0.8;
uniform float vignette_smoothness: hint_range(0.1, 5.0) = 0.5;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;


float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}


void fragment() {
    // 1. 【畸变】先计算出正确的采样坐标
    vec2 centered_uv = SCREEN_UV - 0.5;
    float r2 = dot(centered_uv, centered_uv);
    vec2 distorted_uv = centered_uv * (1.0 - r2 * barrel_distortion);
    distorted_uv += 0.5;

    // 2. 【色差】基于畸变后的坐标，进行三次采样
    vec2 offset = centered_uv * chromatic_abberation;
    float r = texture(SCREEN_TEXTURE, distorted_uv - offset).r;
    float g = texture(SCREEN_TEXTURE, distorted_uv).g;
    float b = texture(SCREEN_TEXTURE, distorted_uv + offset).b;
    vec3 base_color = vec3(r, g, b);

    // --- 3. 【SlowMo 效果】 ---
    float luminance = dot(base_color, vec3(0.299, 0.587, 0.114));
    vec3 grayscale_color = vec3(luminance);
    vec3 desaturated_color = mix(grayscale_color, base_color, saturation);
    vec3 contrasted_color = (desaturated_color - 0.5) * contrast + 0.5;
    float dist_from_center = distance(SCREEN_UV, vec2(0.5));
    float vignette = smoothstep(0.8, vignette_smoothness, dist_from_center);
    vec3 vignetted_color = mix(contrasted_color, contrasted_color * (1.0 - vignette), vignette_intensity);

    // 使用 slow_mo_mix，在“CRT基础色”和“SlowMo处理后的颜色”之间进行混合
    vec3 slowmo_mixed_color = mix(base_color, vignetted_color, slow_mo_mix);

    // --- 4. 【扫描线和噪点】应用在最终的颜色上 ---
    float scanline = sin(distorted_uv.y * scanline_count);
    vec3 scanlined_color = slowmo_mixed_color * (1.0 - scanline * scanline_intensity);
    float noise = (random(SCREEN_UV + mod(TIME, 10.0)) - 0.5) * noise_intensity;
    vec3 final_color = scanlined_color + noise;

    // 5. 【输出】保留原始 Alpha
    COLOR = vec4(final_color, texture(SCREEN_TEXTURE, SCREEN_UV).a);
}