#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;         // 0.0 -> 1.0
    float winWidth;
    float winHeight;
    float transitionStep;   // Softness
    float transitionAngle;  // New variable: Angle in degrees (e.g., 45.0)
} ubuf;

layout(binding = 1) uniform sampler2D oldSource;
layout(binding = 2) uniform sampler2D newSource;

void main() {

    // 1. Correct Aspect Ratio Distortion
    vec2 uv = qt_TexCoord0;
    float winRatio = ubuf.winWidth / ubuf.winHeight;
    uv.x *= winRatio;

    vec4 oldTex = texture(oldSource, qt_TexCoord0);
    vec4 newTex = texture(newSource, qt_TexCoord0);

    float softness = ubuf.transitionStep / 100.0;

    // 2. Convert Angle from Degrees to Radians
    // GLSL trigonometric functions expect radians: radians = degrees * (PI / 180.0)
    float angleRad = radians(ubuf.transitionAngle);

    // 3. Generate the Direction Vector using Cosine and Sine
    vec2 direction = vec2(cos(angleRad), sin(angleRad));

    // 4. Project the current pixel onto our wipe direction line
    float currentPixelProj = dot(uv, direction);

    // 5. Dynamic Bounds Tracking
    // Since the angle changes, the furthest corner changes. 
    // We check all 4 corners to find the absolute maximum projection length.
    float c1 = dot(vec2(0.0, 0.0), direction);
    float c2 = dot(vec2(winRatio, 0.0), direction);
    float c3 = dot(vec2(0.0, 1.0), direction);
    float c4 = dot(vec2(winRatio, 1.0), direction);
    
    float minProj = min(min(c1, c2), min(c3, c4));
    float maxProj = max(max(c1, c2), max(c3, c4));

    // 6. Scale progress perfectly between the absolute minimum and maximum bounds
    float totalRange = maxProj - minProj;
    float currentWipePosition = minProj + ubuf.progress * (totalRange + softness);

    // 7. Calculate the smooth blend factor along the edge
    float blendFactor = smoothstep(currentWipePosition - softness, currentWipePosition, currentPixelProj);

    // 8. Blend and Output
    vec4 imgTex = mix(newTex, oldTex, blendFactor);
    fragColor = imgTex * ubuf.qt_Opacity;

}
