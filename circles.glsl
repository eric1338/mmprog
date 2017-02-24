#version 330

#include "mylib.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;

const float EPSILON = 0.0001;

const vec2 CENTER = vec2(0.0, 0.0);


const float NUMBER_OF_CIRCLES = 10;
const float CIRCLE_THICKNESS = 0.03;
const float CIRCLE_STEP = 0.06;


float getShaderStart() {
	return 0.3;
}

float getTime() {
	return iGlobalTime - getShaderStart();
}




bool isNotInCircle(float start, float end, vec2 coord) {
	float dist = distance(CENTER, coord);
	
	return dist < start || dist > end;
}



vec2 getTwelve(float randStart, float randSpeed) {
	float factor = 1;
	
	if (randSpeed > 0.5) {
		factor = -1;
		randSpeed -= 0.5;
	}
	
	float x = randStart * 6.28 + getTime() * (randSpeed + 0.2);
	
	x *= factor;
	
	vec2 cn = vec2(sin(x), cos(x)) * 0.5;
	
	return cn;
}


float getCircleValue(float start, float end, float size, float randStart, float randSpeed, vec2 coord) {
	if (isNotInCircle(start, end, coord)) return 0;
	
	vec2 twelve = getTwelve(randStart, randSpeed);
	
	vec2 curr = normalize(coord - CENTER);
	
	float x = dot(twelve, curr) * 0.5 + 0.5;
	
	return (x < size) ? 1 : 0;
}

float getCirclesValue(vec2 coord) {
	float circleValue = 0;
	
	for (float i = 1; i <= NUMBER_OF_CIRCLES; i++) {
		float start = i * CIRCLE_STEP;
		float thickness = CIRCLE_THICKNESS;
		
		float randStart = rand(i * 0.4);
		float randSpeed = rand(i * 0.7);
		
		float size = mySmoothstep2(getTime(), (i - 1) * 0.8, 2) * 0.25;
		
		size += 0.245;
		
		if (getTime() > 7) size += (getTime() - 7) * 0.095;
		
		circleValue += getCircleValue(start, start + thickness, size, randStart, randSpeed, coord);
	}
	
	return circleValue;
}


vec3 getBGColor(vec2 coord) {
	return getTwoColorBackground(coord, vec3(0.1, 0.11, 0.12), vec3(0.2, 0.22, 0.24) * 1.2);
}




void main() {
	//coordinates in range [0,1]
	vec2 coord = gl_FragCoord.xy / iResolution;
	
	vec2 newCoord = getAdjustedCoord(coord, iResolution.x / iResolution.y, 0.25 + getTime() * 0.07);
	
	float circlesValue = getCirclesValue(newCoord);
	
	vec3 color = vec3(circlesValue);
	
	if (circlesValue < 0.05) color = getBGColor(newCoord);
	
    gl_FragColor = vec4(color, 1.0);
}
