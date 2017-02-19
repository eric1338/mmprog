#version 330

#include "mylib.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform vec3 iMouse;

const float EPSILON = 0.0001;



//value noise: random values at integer positions with interpolation inbetween
float noise(float u)
{
	float i = floor(u); // integer position

	//random value at nearest integer positions
	float v0 = rand(i);
	float v1 = rand(i + 1);

	float f = fract(u);
	float weight = f; // linear interpolation
	weight = smoothstep(0, 1, f); // cubic interpolation

	return mix(v0, v1, weight);
}


const vec2 CENTER = vec2(0.5);
const float CIRCLE_MIN = 0.3;
const float CIRCLE_MAX = 0.45;

bool isInCircle(vec2 coord) {
	float dist = distance(CENTER, coord);
	
	return dist >= CIRCLE_MIN && dist <= CIRCLE_MAX;
}




float NUMBER_OF_POINTS = 20.0;


float getMusicFactor() {
	float x = mod(iGlobalTime, 4);
	
	float p1 = 0.1;
	float p2 = 3.9;
	
	return x < p1 ? x * (1 / p1) : max((p2 - (x - p1)) / p2, 0);
}



const float MUSIC_LINE_FREQUENCY = 20;
const float MUSIC_LINE_AMPLITUDE = 0.2;

const float MUSIC_LINE_MINIMUM_AMPLITUDE = 0.05;

const float MUSIC_LINE_THICKNESS = 0.0015;

const float MUSIC_LINE_GLOW_SIZE = 0.001;


float getMusicTest() {
	float modVal = mod(iGlobalTime, 6);
	
	float modF = modVal < 3 ? modVal : 6 - modVal;
	
	return modF;
}

/*
	vec2 threeHand = normalize(vec2(2.1, 0.6) - CENTER);
	vec2 twelveHand = normalize(vec2(4.0, -1.9) - CENTER);
	vec2 coordHand = normalize(coord - CENTER);
	
	float threeHandAngle = dot(threeHand, coordHand) * 0.5 + 0.5;
	float twelveHandAngle = dot(twelveHand, coordHand) * 0.5 + 0.5;
	
	float xValue = threeHandAngle * 2;
	
	float noiseValue1 = noise(xOffset + threeHandAngle * MUSIC_LINE_FREQUENCY);
	float noiseValue2 = noise(xOffset * 0.5 + twelveHandAngle * MUSIC_LINE_FREQUENCY);
	
	float noiseValue = noiseValue1 + noiseValue2;
	
	//float noiseValue = noise(xOffset + xValue * MUSIC_LINE_FREQUENCY);
	
	//xValue = fract(xValue + iGlobalTime * 0.2);


*/


const float MUSIC_LINE_MINIMUM_SPEED = 0.02;
const float MUSIC_LINE_SPEED_FACTOR = 0.1;

vec2 getTwelveHand(float seed) {
	float speedFactor = MUSIC_LINE_MINIMUM_SPEED + rand(seed) * MUSIC_LINE_SPEED_FACTOR;
	float x = speedFactor * (iGlobalTime + 0);
	
	return normalize(vec2(sin(x), cos(x)));
}


float getMusicLineValue(vec2 coord, float xOffset) {
	if (!isInCircle(coord)) return 0;
	
	//vec2 twelveHand = normalize(vec2(0, -1.0));
	
	vec2 twelveHand = getTwelveHand(xOffset);
	
	vec2 coordHand = normalize(coord - CENTER);
	
	float angle = dot(twelveHand, coordHand) * 0.5 + 0.5;
	
	float xValue = angle;
	
	float xV = xOffset + xValue * MUSIC_LINE_FREQUENCY;
	
	float noiseValue = noise(xV);
	
	float noiseValue2 = noise(xOffset + 7 + xValue * MUSIC_LINE_FREQUENCY);
	
	//noiseValue = noiseValue * noiseValue2;
	
	
	
	//float noiseValue = noise(xOffset + xValue * MUSIC_LINE_FREQUENCY);
	
	
	//if (coord.x < CENTER.x) noiseValue = 0;
	
	//xValue = fract(xValue + iGlobalTime * 0.2);
	
	float coordYValue = length(coord - CENTER);
	
	coordYValue = mySmoothstep2(coordYValue, CIRCLE_MIN, CIRCLE_MAX);
	
	float amplitudeFactor = MUSIC_LINE_MINIMUM_AMPLITUDE + getMusicFactor() * MUSIC_LINE_AMPLITUDE;
	
	float requiredYValue = amplitudeFactor * noiseValue;
	
	float yValueDifference = abs(requiredYValue - coordYValue);
	
	return myReverseSmoothstep2(yValueDifference, MUSIC_LINE_THICKNESS, MUSIC_LINE_THICKNESS + MUSIC_LINE_GLOW_SIZE);
}

const float MUSIC_LINE_1_X_OFFSET = 15.0;
const float MUSIC_LINE_2_X_OFFSET = 1.0;
const float MUSIC_LINE_3_X_OFFSET = 2.0;
const float MUSIC_LINE_4_X_OFFSET = 4.0;
const float MUSIC_LINE_5_X_OFFSET = 8.0;

float getMusicLinesValue(vec2 coord) {
	float musicLineValue = 0.0;
	
	musicLineValue += getMusicLineValue(coord, MUSIC_LINE_1_X_OFFSET);
	musicLineValue += getMusicLineValue(coord, MUSIC_LINE_2_X_OFFSET) * 0.6;
	musicLineValue += getMusicLineValue(coord, MUSIC_LINE_3_X_OFFSET) * 0.36;
	musicLineValue += getMusicLineValue(coord, MUSIC_LINE_4_X_OFFSET) * 0.216;
	musicLineValue += getMusicLineValue(coord, MUSIC_LINE_5_X_OFFSET) * 0.1296;
	
	return min(musicLineValue, 1.0);
}

const float POINT_MIN_OFFSET = 0.5;

const float POINT_SPEED_FACTOR = 0.3;

const float POINT_OFFSET_FACTOR = 0.01;

const float POINT_AMPLITUDE = 0.1;


vec2 getPointCenter(float index) {
	float randSpeed = (rand(index) - 0.5) * POINT_SPEED_FACTOR;
	
	float angle = (TWOPI / NUMBER_OF_POINTS) * index + iGlobalTime * randSpeed;
	
	vec2 center = vec2(cos(angle), sin(angle)) * 0.4;
	
	vec2 randSeed = vec2(cos(index), sin(index));
	vec2 offset = rand2(randSeed) * POINT_OFFSET_FACTOR;
	
	//vec2 offset = vec2(0);
	
	float f = min(iGlobalTime * 0.5, 1);
	
	float musicF = getMusicFactor() * POINT_AMPLITUDE + (CIRCLE_MIN + POINT_MIN_OFFSET);
	
	// QUATSCH
	
	return CENTER + center * f * musicF + offset * f;
}


const float POINT_THICKNESS = 0.001;

const float POINT_GLOW_SIZE = 0.0005;

float getPointValue(vec2 coord, float index) {
	vec2 center = getPointCenter(index);
	
	float dist = distance(coord, center);
	
	float thickness = 0.001;
	
	return myReverseSmoothstep2(dist, POINT_THICKNESS, POINT_THICKNESS + POINT_GLOW_SIZE);
}


float getPointsValue(vec2 coord) {
	if (!isInCircle(coord)) return 0;
	
	float step = TWOPI / 20.0;
	
	float val = 0.0;
	
	for (float i = 0; i < NUMBER_OF_POINTS; i++) {
		val = max(val, getPointValue(coord, i));
	}
	
	return val;
}


vec2 getRandomPoint(float seed) {
	float randomIndex = floor(rand(seed) * NUMBER_OF_POINTS);
	
	return getPointCenter(randomIndex);
}




void main() {
	//coordinates in range [0,1]
    vec2 coord = gl_FragCoord.xy/iResolution;
	
	coord.x *= iResolution.x / iResolution.y;
	
	vec3 color = vec3(getPointsValue(coord));
	
	color += vec3(getMusicLinesValue(coord));
	
    gl_FragColor = vec4(color, 1.0);
}
