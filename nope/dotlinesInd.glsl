#version 330

#include "mylib.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;



const vec2 CENTER = vec2(0.0);
const float CIRCLE_MIN = 0.3;
const float CIRCLE_MAX = 0.45;


float uDotlinesCircleSize = 1.0;

float getCircleSizeFactor() {
	return uDotlinesCircleSize;
}


float getCircleMin() {
	return CIRCLE_MIN * getCircleSizeFactor();
}

float getCircleMax() {
	return CIRCLE_MAX * getCircleSizeFactor();
}

bool isInCircle(vec2 coord) {
	float dist = distance(CENTER, coord);
	
	return dist > getCircleMin() && dist < getCircleMax();
}



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





float NUMBER_OF_POINTS = 40.0;


uniform float uMusic;


float getMusicFactor() {
	float x = mod(iGlobalTime, 4);
	
	float p1 = 0.1;
	float p2 = 3.9;
	
	return uMusic;
	
	//return x < 2 ? 0 : 1;
	
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
	
	float noiseValue = noise(xOffset + angle * MUSIC_LINE_FREQUENCY) * 0.9 + 0.1;
	
	float coordYValue = length(coord - CENTER);
	
	coordYValue = mySmoothstep2(coordYValue, getCircleMin(), getCircleMax());
	
	//if (abs(angle) < 10.02) return coordYValue;
	
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

const float POINT_SPEED_FACTOR = 0.3;
const float POINT_GENERAL_OFFSET_FACTOR = 0.25;
const float POINT_RANDOM_OFFSET_FACTOR = 0.2;
const float MUSIC_AMPLITUDE = 0.1;


vec2 getPointCenter(float index) {
	float randSpeed = (rand(index) - 0.5) * POINT_SPEED_FACTOR;
	
	float angle = (TWOPI / NUMBER_OF_POINTS) * index + iGlobalTime * randSpeed;
	
	float halfCircleSize = (CIRCLE_MAX - CIRCLE_MIN) / 2.0;
	
	float pointStart = CIRCLE_MIN + halfCircleSize * POINT_GENERAL_OFFSET_FACTOR;
	
	float randOffset = pnRand(index) * halfCircleSize * POINT_RANDOM_OFFSET_FACTOR;
	
	float musicOffset = getMusicFactor() * MUSIC_AMPLITUDE * 0.5;
	
	vec2 pointCenter = vec2(cos(angle), sin(angle)) * (pointStart + randOffset + musicOffset);
	
	return CENTER + pointCenter;
}


const float POINT_THICKNESS = 0.001;

const float POINT_GLOW_SIZE = 0.0005;

float getPointValue(vec2 coord, float index) {
	vec2 center = getPointCenter(index);
	
	float dist = distance(coord, center);
	
	return myReverseSmoothstep2(dist, POINT_THICKNESS, POINT_THICKNESS + POINT_GLOW_SIZE);
}


float getPointsValue(vec2 coord) {
	if (!isInCircle(coord)) return 0;
	
	float pointsValue = 0.0;
	
	for (float i = 0; i < NUMBER_OF_POINTS; i++) {
		pointsValue = max(pointsValue, getPointValue(coord, i));
	}
	
	return pointsValue;
}




void main() {
	//coordinates in range [0,1]
    vec2 coord = gl_FragCoord.xy/iResolution;
	
	coord = getAdjustedCoord(coord, iResolution.x / iResolution.y, 1 + iGlobalTime * 0.02);
	
	//coord.x *= iResolution.x / iResolution.y;
	
	vec3 color = vec3(getPointsValue(coord));
	
	color += vec3(1.0, 0.9, 0.8) * getMusicLinesValue(coord);
	
    gl_FragColor = vec4(color, 1.0);
}
