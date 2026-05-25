#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float winWidth;
    float winHeight;

    bool special; 

    float transitionStep; 
    float posX; 
    float posY; 
} ubuf;

layout(binding = 1) uniform sampler2D oldSource;
layout(binding = 2) uniform sampler2D newSource;

void main() {
    // 1. Correct Aspect Ratio Distortion
    vec2 uv = qt_TexCoord0;
    float winRatio = ubuf.winWidth / ubuf.winHeight;
    uv.x *= winRatio;
    vec2 center = vec2(ubuf.posX * winRatio, ubuf.posY);

    vec4 oldTex = texture(oldSource, qt_TexCoord0);
    vec4 newTex = texture(newSource, qt_TexCoord0);

    float softness = (ubuf.transitionStep / 100.0);
    float invert = ubuf.special ? 0.0 : 1.0;  

    float dist = distance(uv, center);

    // 2. Dynamically calculate the maximum possible distance to any corner
    // In our scaled aspect-ratio space, the screen limits are X: [0 -> winRatio] and Y: [0 -> 1]
    float maxDistX = max(center.x, winRatio - center.x);
    float maxDistY = max(center.y, 1.0 - center.y);
    float maxRadius = sqrt(maxDistX * maxDistX + maxDistY * maxDistY);

    // 3. Scale radius perfectly
    float currentRadius = ubuf.progress * (maxRadius + softness);

    float blendFactor = smoothstep(currentRadius - softness, currentRadius, dist);
    blendFactor = abs(invert - blendFactor);

    vec4 imgTex = mix(oldTex, newTex, blendFactor);

    fragColor = imgTex * ubuf.qt_Opacity;
}
