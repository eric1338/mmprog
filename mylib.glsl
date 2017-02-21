

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






/*
vec3 getTwoColorBackground(vec2 coord, vec3 color1, vec3 color2) {
	float f1 = cos(coord.x + 0.2);
	float f2 = cos(coord.y + 0.1);
	
	float color1Factor = f1 * 0.5 + f2 * 0.5;
	float color2Factor = 1 - color1Factor;
	
	color1Factor *= 0.25;
	color2Factor *= 0.25;
	
	return color1 * 0.05 + color1 * color1Factor + color2 * 0.4 + color2 * color2Factor;
	//return vec3(0.0, 0.1 + greenFactor, 0.4 + blueFactor) * 0.4;
}
*/


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
