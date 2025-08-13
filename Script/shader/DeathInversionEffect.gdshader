shader_type canvas_item;

// 【核心修正】在顶部添加这一行，明确声明我们要使用屏幕纹理
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	COLOR.rgb = vec3(1.0) - texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
}