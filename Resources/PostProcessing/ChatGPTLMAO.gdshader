shader_type spatial;
render_mode unshaded, cull_disabled;

const vec2 vertices[3] = {vec2(-1,-1), vec2(3,-1), vec2(-1, 3)};

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest_mipmap;
uniform sampler2D depth_texture: hint_depth_texture, filter_nearest_mipmap;
uniform sampler2D color_palette;
uniform int num_colors = 16;
uniform float SCREEN_PIXEL_SIZE = 16;
uniform float pixel_size = 8.0;
uniform float outline_size = 1.0;

void fragment() {
    // Calculate the position within the low-resolution pixel grid
    vec2 pixel_pos = floor(SCREEN_UV * pixel_size) / pixel_size;
    
    // Retrieve the color of the low-resolution pixel
    vec4 pixel_color = texture(SCREEN_TEXTURE, pixel_pos);
    
    // Calculate the outline color
    vec4 outline_color = vec4(0.0, 0.0, 0.0, 1.0);
    if (abs(pixel_pos.x - SCREEN_UV.x) < outline_size / SCREEN_PIXEL_SIZE || 
        abs(pixel_pos.y - SCREEN_UV.y) < outline_size / SCREEN_PIXEL_SIZE) {
        outline_color.rgb = vec3(1.0, 1.0, 1.0);
    }
    
    // Calculate the final color with highlights, shadows, and outlines
    vec4 final_color = pixel_color + outline_color;
    
    // Output the final color
    ALBEDO = final_color.rgb;
}
void vertex() {
    POSITION = vec4(vertices[VERTEX_ID],0.0,1.0);
}