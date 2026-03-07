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
    // Coordinate scaling
    vec2 uv = gl_FragCoord.xy;
    float scale = 40.0;
    
    // Create sharp lines instead of rounded dots
    vec2 grid = abs(fract(uv / scale - 0.5) - 0.5) / (fwidth(uv / scale));
    float line = min(grid.x, grid.y);
    float color_mask = 1.0 - smoothstep(0.0, 1.5, line);
    
    // Amber/Gold DXMD color
    vec3 amber = vec3(0.88, 0.69, 0.17);
    
    // Add a very subtle "scanline" pulse using u_time
    float pulse = 0.8 + 0.2 * sin(u_time * 2.0);
    
    fragColor = vec4(amber * color_mask * pulse, 0.2 * qt_Opacity);
}
