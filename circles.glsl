#version 330

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform vec3 iMouse;

const float PI = 3.1415926535897932384626433832795;
const float TWOPI = 2 * PI;
const float EPSILON = 10e-4;

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


const vec2 CENTER = vec2(0.5);


bool isNotInCircle(float start, float end, vec2 coord) {
	float dist = distance(CENTER, coord);
	
	return dist < start || dist > end;
}


float getCircleValue(float start, float end, vec2 randVec, vec2 coord) {
	if (isNotInCircle(start, end, coord)) return 0;
	
	float r1 = rand(vec2(start, end));
	float r2 = rand(r1);
	
	float aStart = min(r1, r2);
	float aEnd = max(r1, r2);
	
	vec2 timeVec = vec2(iGlobalTime, iGlobalTime) * 0.1;
	
	vec2 twelve = normalize(rand2(randVec) + timeVec - CENTER);
	vec2 curr = normalize(coord - CENTER);
	
	float x = dot(twelve, curr) * 0.5 + 0.5;
	
	float circleSize = 0.6;
	
	return (x < circleSize) ? 1 : -1;
}

float getCirclesValue(vec2 coord) {
	float circleValue = 0;
	
	for (float i = 1; i < 10; i++) {
		float f = max(6 - (iGlobalTime / 1.0), 1.0);
		float start = (i / 10) * f;
		float size = 0.05 * f;
		vec2 randVec = vec2(i / 10.0, i / 10.0 + 0.05);
		circleValue += getCircleValue(start, start + size, randVec, coord);
	}
	
	return circleValue;
}


vec3 getBGColor(vec2 coord) {
	float yf = 1;
	float xf = 0.0;
	
	float dx1 = coord.y * yf + coord.x * xf;
	float dx2 = (1 - coord.y) * yf + (1 - coord.x) * xf;
	
	return vec3(1, 0.0, 0.34) * dx1 + vec3(0.5, 0.0, 0.2) * dx2;
	//return vec3(0, 0.7, 1) * dx1 + vec3(0, 0.4, 1.0) * dx2;
	//return vec3(0.0, 0.9, 0.8) * dx1 + vec3(0.0, 0.5, 0.4) * dx2;
}


void main() {
	//coordinates in range [0,1]
    vec2 coord = gl_FragCoord.xy/iResolution;
	
	coord.x *= iResolution.x / iResolution.y;
	
	float circlesValue = getCirclesValue(coord);
	
	vec3 color = vec3(circlesValue);
	
	if (circlesValue < 0.05) color = getBGColor(coord);
	
    gl_FragColor = vec4(color, 1.0);
}
