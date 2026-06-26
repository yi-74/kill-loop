// 径向模糊 Shader (Radial Blur)
shader_type canvas_item;

// 模糊强度 (在代码里会被 Tween 动态修改)
uniform float blur_strength : hint_range(0.0, 0.1) = 0.0; 
// 屏幕中心点
uniform vec2 blur_center = vec2(0.5, 0.5); 
// 采样数，越大越平滑但更消耗性能，15 是个好平衡
uniform int samples : hint_range(5, 30) = 15; 

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // 计算当前像素到中心的向量
    vec2 dir = SCREEN_UV - blur_center;
    vec4 color = vec4(0.0);
    
    // 沿着中心点向外进行多次采样，并把颜色加起来
    for (int i = 0; i < samples; i++) {
        // 计算每一次采样的偏移比例
        float scale = 1.0 - blur_strength * (float(i) / float(samples - 1));
        color += texture(SCREEN_TEXTURE, blur_center + dir * scale);
    }
    
    // 取平均值，得出最终颜色
    COLOR = color / float(samples);
}
