

const float PI = 3.1415926535897932384626433832795;
const float TWOPI = 2 * PI;


float rand(float seed)
{
	return fract(sin(seed) * 1231534.9);
}

float rand(vec2 seed) { 
    return rand(dot(seed, vec2(12.9898, 783.233)));
}

//random vector with length 1
vec2 rand2(vec2 seed)
{
	float r = rand(seed) * TWOPI;
	return vec2(cos(r), sin(r));
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
