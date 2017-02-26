#version 330

#include "mylib.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;

uniform float uMusic;
uniform float uCirclesShaderStart;

const float EPSILON = 0.0001;

const vec2 CENTER = vec2(0.0, 0.0);


const float NUMBER_OF_CIRCLES = 10;
const float CIRCLE_THICKNESS = 0.03;
const float CIRCLE_STEP = 0.06;


float getShaderStart() {
	return uCirclesShaderStart;
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

vec4 getCircleColor(int index) {
	//if (index == 1) return vec4(1.0, 0.0, 0.4, 1.0);
	
	//return vec4(0.0, 0.2, 0.8, 1.0);
	
	if (index == 1) return vec4(0.963, 0.89, 0.741, 1.0);
	if (index == 2) return vec4(0.936, 0.7, 0.62, 1.0);
	if (index == 3) return vec4(0.7, 0.5, 0.515, 1.0);
	
	return vec4(0.45, 0.383, 0.43, 1.0);
}

vec4 getCirclesColor(vec2 coord) {
	vec4 circlesColor = vec4(0);
	
	for (int i = 1; i <= NUMBER_OF_CIRCLES; i++) {
		float start = i * CIRCLE_STEP + uMusic * 0.000 * i;
		float thickness = CIRCLE_THICKNESS;
		
		float randStart = rand(i * 0.4);
		float randSpeed = rand(i * 0.7);
		
		float size = mySmoothstep2(getTime(), (i - 1) * 0.8, 2) * 0.25;
		
		size += 0.245;
		
		if (getTime() > 7) size += (getTime() - 7) * 0.092;
		
		float circleValue = getCircleValue(start, start + thickness, size, randStart, randSpeed, coord);
		
		if (circleValue > 0.001) {
			circlesColor = getCircleColor(i) * circleValue;
		}
		
		//circleValue += getCircleValue(start, start + thickness, size, randStart, randSpeed, coord);
	}
	
	return circlesColor;
}


vec3 getBackgroundColor(vec2 coord) {
	return vec3(0.254, 0.242, 0.29);
	//return getTwoColorBackground(coord, vec3(0.1, 0.11, 0.12), vec3(0.2, 0.22, 0.24) * 1.2);
}




void main() {
	//coordinates in range [0,1]
	vec2 coord = gl_FragCoord.xy / iResolution;
	
	vec2 newCoord = getAdjustedCoord(coord, iResolution.x / iResolution.y, 0.25 + getTime() * 0.07);
	
	vec4 circlesColor = getCirclesColor(newCoord);
	
	vec4 color = circlesColor.a > 0.01 ? circlesColor : vec4(getBackgroundColor(coord), 1.0);
	
    gl_FragColor = color;
}
