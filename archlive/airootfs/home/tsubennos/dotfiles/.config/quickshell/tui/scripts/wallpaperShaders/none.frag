#version 440

layout(location = 0) in vec2 qt_TexCoord0;

layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
} ubuf;

layout(binding = 2) uniform sampler2D newSource;

void main() {

    vec4 imgTex = texture(newSource, qt_TexCoord0);

    fragColor = imgTex * ubuf.qt_Opacity;

}

