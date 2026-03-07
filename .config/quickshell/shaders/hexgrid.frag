#version 440

layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float u_width;
    float u_height;
    float u_time;
};

void main() {
    // Calculate UV from screen coordinates instead of qt_TexCoord0
    vec2 uv = gl_FragCoord.xy / vec2(u_width, u_height);
    
    // Scale for hex-grid
    vec2 grid_uv = uv * vec2(u_width / 30.0, u_height / 30.0);
    float grid = sin(grid_uv.x * 3.1415) * sin(grid_uv.y * 3.1415);
    float line = step(0.9, grid);
    
    vec3 amber = vec3(0.88, 0.69, 0.17);
    fragColor = vec4(amber * line * 0.5, 0.2 * qt_Opacity);
}
