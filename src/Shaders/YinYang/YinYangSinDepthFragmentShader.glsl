uniform float     uAlpha;
uniform sampler2D uAudioTexture;
uniform float     uTime;
uniform float     uHighFrequency;
uniform float     uLowFrequency;
uniform float     uColorStrength;
uniform float     uHover;
uniform float     uRotate;
varying vec2      vUv; // Coordenadas UV del fragmento



// Make a black and white circle
vec4 circleBW(vec4 currentColor, vec2 st, vec2 center, float radius) {
    float dist = length(st - center);

    if (dist < radius) {
        vec3 color = vec3(0.0);
        if (st.y > center.y) {
            color += vec3(1.0);
        }
        if (st.y < center.y) {
            color += vec3(0.0, uColorStrength, 0.0);
        }
        return vec4(color, 1.0);
    } 
    return currentColor;    
}

// Make a circle
vec4 circle(vec4 currentColor, vec2 st, vec2 center, float radius, vec3 color) {
    float dist = length(st - center);

    if (dist < radius) {
        return vec4(color, 1.0);
    } 
    return currentColor;
}



#if DEPTH_PACKING == 3200
	uniform float opacity;
#endif
#include <common>
#include <packing>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
varying vec2 vHighPrecisionZW;
void main() {
	#include <clipping_planes_fragment>
	vec4 diffuseColor = vec4( 1.0 );
	#if DEPTH_PACKING == 3200
		diffuseColor.a = opacity;
	#endif



    // Center of the plane
    vec2 center = vec2(0.5, 0.5);

    // Calculate rotation matrix based on uTime (do 16 cycles and then reverse)
    float angle = sin(uTime * 0.025) * 32.0 * 3.14159265 * uRotate;  // 2pi radiants are 360deg, so whe are rotating 16 times
    mat2 rotation = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    // Translate coordinates to the center of the object
    vec2 translated = vUv - center;
    // Rotate coordinates
    vec2 rotated = rotation * translated;    
    // Translate coordinates to their original position
    vec2 finalCoords = rotated + center;

    // yin yang circle radius
    float radius = 0.25;
    // Base color
    vec4 color = vec4(0.0, 0.0, 0.0, (uAlpha + uHover) * 0.80);


    float dist = length(finalCoords - center);
    // get angle in rads of current position from center
    float rad = atan(finalCoords.y - center.y, finalCoords.x - center.x);
    float normAngle = 0.0;

//    rad = -PI + mod(uTime, TAU);

    // Divide the circle into two halfs and make a mirror 
    // I use linear audio textute form 0 to 1 in one half and in the other half i use the audio texture from 1 to 0.
    if (rad < 0.0) {
        normAngle = ((rad + PI) / PI);
    } else {
        normAngle = (((rad - PI) / PI));
    }

    normAngle = mod(normAngle + uTime * 0.25, 1.0);
    
    // Use the audio texture to obtain the radius based in the angle
    float audioValue = (texture2D(uAudioTexture, vec2(normAngle, 0.0)).g - 0.5) * 0.55;
//    float audioValue = texture2D(uAudioTexture, vec2(normAngle, 0.0)).r * 0.25;
    dist -= audioValue;

    if (dist < radius) { // fill
    //if (dist > radius - 0.3 && dist < radius) { // Line
        if (rad >= 0.0) {
            color = vec4(1.0, 1.0, 1.0, 1.0);
        }
        else {
            color = vec4(0.0, uColorStrength, 0.0, 1.0);
        }
    } 

    // First big circle black / white
   // color = circleBW(color, finalCoords, center, 0.25);    
    // White left circle 
    color = circle(color, finalCoords, vec2(0.25 + 0.125, 0.5), 0.125, vec3(1.0, 1.0, 1.0));
    // Black right circle
    color = circle(color, finalCoords, vec2(0.75 - 0.125, 0.5), 0.125, vec3(0.0, uColorStrength, 0.0));
    // Black left mini circle 
    float miniRadiusB = 0.0625 * 0.35 + uHighFrequency;
    color = circle(color, finalCoords, vec2(0.25 + 0.125, 0.5), miniRadiusB, vec3(0.0, uColorStrength, 0.0));
    // White right mini circle
    float miniRadiusW = 0.0625 * 0.35 + uLowFrequency;
    color = circle(color, finalCoords, vec2(0.75 - 0.125, 0.5), miniRadiusW, vec3(1.0, 1.0, 1.0));
    
    
    // Apply the round hover border
//    color = borderRoundRect(color, vec2(1.0, 1.0), 0.125);


    diffuseColor = color;
//    gl_FragColor = vec4(color.r);
    if (color.a == 0.0) discard;



	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <logdepthbuf_fragment>
	float fragCoordZ = 0.5 * vHighPrecisionZW[0] / vHighPrecisionZW[1] + 0.5;
	
    #if DEPTH_PACKING == 3200
		gl_FragColor = vec4( vec3( 1.0 - fragCoordZ ), opacity );
	#elif DEPTH_PACKING == 3201
		gl_FragColor = packDepthToRGBA( fragCoordZ );
	#endif

}