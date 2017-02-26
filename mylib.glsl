

const float PI = 3.1415926535897932384626433832795;
const float TWOPI = 2 * PI;


float rand(float seed) {
	return fract(sin(seed) * 1231534.9);
}

float rand(vec2 seed) { 
    return rand(dot(seed, vec2(12.9898, 783.233)));
}

float pnRand(float seed) {
	return rand(seed) * 2 - 1;
}

float pnRand(vec2 seed) { 
    return rand(seed) * 2 - 1;
}

//random vector with length 1
vec2 rand2(vec2 seed) {
	float r = rand(seed) * TWOPI;
	return vec2(cos(r), sin(r));
}


vec2 getAdjustedCoord(vec2 coord, float ratio, float zoom) {
	vec2 newCoord = coord - vec2(0.5);
	
	newCoord.x *= ratio;
	
	newCoord *= zoom;
	
	return newCoord;
}

float getBackgroundNoise(vec2 coord) {
	vec2 i = floor(coord); // integer position

	//random value at nearest integer positions
	float v00 = rand(i);
	float v10 = rand(i + vec2(1, 0));
	float v01 = rand(i + vec2(0, 1));
	float v11 = rand(i + vec2(1, 1));
	
	vec2 f = fract(coord);
	vec2 weight = f; // linear interpolation
	weight = smoothstep(0, 1, f); // cubic interpolation

	float x1 = mix(v00, v10, weight.x);
	float x2 = mix(v01, v11, weight.x);
	return mix(x1, x2, weight.y);
}

float getBackgroundFBM(vec2 coord) {
	// Properties
	int octaves = 6;
	float lacunarity = 2.5;
	float gain = 0.5;
	// Initial values
	float amplitude = 0.5;
	float value = 0;
	
	// Loop of octaves
	for (int i = 0; i < octaves; ++i) {
		value += amplitude * getBackgroundNoise(coord);
		coord *= lacunarity;
		amplitude *= gain;
	}
	
	return value;
}

vec3 getBackgroundFogColor(vec2 coord, vec3 fogColor, float fogFactor) {
	return fogColor * getBackgroundFBM(coord) * fogFactor;
}

vec3 getTwoColorBackground(vec2 coord, vec3 color1, vec3 color2) {
	float f1 = cos(coord.x + 0.2);
	float f2 = cos(coord.y + 0.1);
	
	float color1Factor = f1 * 0.5 + f2 * 0.5;
	float color2Factor = 1 - color1Factor;
	
	color1Factor *= 0.55;
	color2Factor *= 0.55;
	
	return color1 * 0.25 + color1 * color1Factor + color2 * 0.25 + color2 * color2Factor;
}

vec3 getTwoColorFogBackground(vec2 coord, vec3 color1, vec3 color2, vec3 fogColor, float fogFactor) {
	return getTwoColorBackground(coord, color1, color2) + getBackgroundFogColor(coord, fogColor, fogFactor);
}


float mySmoothstep(float value, float zeroStart, float oneEnd) {
	if (value < zeroStart) return 0.0;
	if (value > oneEnd) return 1.0;
	
	return (value - zeroStart) / (oneEnd - zeroStart);
}

float mySmoothstep2(float value, float zeroStart, float stepSize) {
	return mySmoothstep(value, zeroStart, zeroStart + stepSize);
}

float myReverseSmoothstep(float value, float oneStart, float zeroEnd) {
	return 1 - mySmoothstep(value, oneStart, zeroEnd);
}

float myReverseSmoothstep2(float value, float oneStart, float stepSize) {
	return myReverseSmoothstep(value, oneStart, oneStart + stepSize);
}
