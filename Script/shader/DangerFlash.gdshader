shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0, 0.1, 0.1, 1.0); // 鲜红色

void fragment() {
    // 【核心修正】记住节点原本的透明度（也就是 Tween 正在平滑修改的那个值）
    float tween_alpha = COLOR.a; 
    
    // 计算边缘暗角圆环
    float dist = distance(UV, vec2(0.5));
    float vignette = smoothstep(0.3, 0.7, dist);
    
    // 输出颜色，并把 Tween 的透明度乘进去！这样过渡才会生效！
    COLOR = flash_color;
    COLOR.a *= vignette * tween_alpha; 
}