#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;         // 0.0 -> 1.0
    float winWidth;
    float winHeight;
    float transitionStep;   // Maps to total thickness of the ripple zone
    float posX;             // Mouse X (0.0 -> 1.0)
    float posY;             // Mouse Y (0.0 -> 1.0)
} ubuf;

layout(binding = 1) uniform sampler2D oldSource;
layout(binding = 2) uniform sampler2D newSource;

// --- NOISE ENGINE FUNCTIONS ---
float hash1d(float n) {
    return fract(sin(n) * 43758.5453123);
}

float noise1d(float x) {
    float i = floor(x);
    float f = fract(x);
    float u = f * f * (3.0 - 2.0 * f);
    return mix(hash1d(i), hash1d(i + 1.0), u);
}

void main() {
    // 1. ISOLATED TUNING CONFIGURATION (Change these to tweak the look)
    // -----------------------------------------------------------------
    float BASE_AMPLITUDE  = 0.08;  // Overall refractive strength of the water
    float RIPPLE_COUNT    = 4.2;    // How many ripple rings oscillate inside the band
    
    // Organic Warp Settings
    float WARP_BUMPS      = 1.0;    // Number of organic bends around the circle perimeter
    float WARP_STRENGTH   = 0.015;  // How deformed the circle is (Kept low for subtlety)
    
    // Trailing Wobble Settings
    float TRAIL_DURATION  = 0.85;   // At what progress (0.0-1.0) the trailing wobble fully dies out
    float TRAIL_SPEED     = 1.0;   // How fast the settling water oscillates over time
    float TRAIL_FREQ      = 20.0;   // Distance frequency of the settling background waves
    float TRAIL_AMP       = 0.01;  // Amplitude of the residual wobble (Keep it very small!)
    // -----------------------------------------------------------------

    // 2. Coordinate & Aspect Ratio Setup
    vec2 uv = qt_TexCoord0;
    float winRatio = ubuf.winWidth / ubuf.winHeight;
    uv.x *= winRatio;
    vec2 center = vec2(ubuf.posX * winRatio, ubuf.posY);

    vec4 oldTex = texture(oldSource, qt_TexCoord0);
    vec4 newTex = texture(newSource, qt_TexCoord0);

    // 3. Distance & Direction Calculations
    vec2 delta = uv - center;
    float dist = distance(uv, center);
    vec2 dir = normalize(delta);
    float angle = atan(delta.y, delta.x);

    // 4. Subtle Organic Shape Warp
    float shapeWobble = noise1d(angle * WARP_BUMPS);

    // 5. Dynamic Corner Bounds Tracking
    float maxDistX = max(center.x, winRatio - center.x);
    float maxDistY = max(center.y, 1.0 - center.y);
    float maxRadius = sqrt(maxDistX * maxDistX + maxDistY * maxDistY);
    
    float waveWidth = ubuf.transitionStep / 100.0; 
    float currentWavePos = ubuf.progress * (maxRadius + waveWidth + WARP_STRENGTH);
    
    // Apply tuned-down shape deformation to the wavefront position
    currentWavePos -= shapeWobble * WARP_STRENGTH;

    vec2 displacedUV = qt_TexCoord0;

    // 6. Primary Shockwave Ring (Inside the active moving ring)
    if (dist >= currentWavePos - waveWidth && dist <= currentWavePos) {
        float progressInsideWave = (currentWavePos - dist) / waveWidth;
        
        // Multi-crest pattern mixed with per-crest amplitude randomizer
        float waveFrequency = RIPPLE_COUNT * 3.141592; 
        float wavePattern = sin(progressInsideWave * waveFrequency);
        float crestRandomizer = noise1d(progressInsideWave * 10.0);
        
        float edgeTaper = sin(progressInsideWave * 3.141592);
        float finalAmplitude = BASE_AMPLITUDE * edgeTaper * (0.4 + crestRandomizer * 0.6);
        
        displacedUV -= (dir / winRatio) * (wavePattern * finalAmplitude); 
    }
    // 7. NEW FEATURE: Trailing Subtle Wobble (Behind the main wave)
    else if (dist < currentWavePos - waveWidth && ubuf.progress < TRAIL_DURATION) {
        // Linear fade out factor for the trail as the overall progress goes on
        float trailFade = 1.0 - (ubuf.progress / TRAIL_DURATION);
        
        // Create an ongoing temporal wave animation using progress as a clock
        float timeComponent = ubuf.progress * TRAIL_SPEED;
        float spaceComponent = dist * TRAIL_FREQ;
        
        // Create traveling ripples that fade out over time and distance from the shockwave
        float trailPattern = sin(spaceComponent - timeComponent);
        float finalTrailAmp = TRAIL_AMP * trailFade * smoothstep(0.0, 0.3, dist);
        
        displacedUV -= (dir / winRatio) * (trailPattern * finalTrailAmp);
    }

    // 8. Base Transition Blending
    float blendFactor = smoothstep(currentWavePos - waveWidth, currentWavePos, dist);
    blendFactor = abs(1.0 - blendFactor);

    // Re-sample textures using finalized displacement coordinates
    vec4 finalOld = texture(oldSource, displacedUV);
    vec4 finalNew = texture(newSource, displacedUV);

    vec4 imgTex = mix(finalOld, finalNew, blendFactor);
    fragColor = imgTex * ubuf.qt_Opacity;
}
