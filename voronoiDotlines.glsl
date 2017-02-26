#version 330

#include "mylib.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;

uniform float uMusic;


// VORONOI

uniform sampler2D texture0;


struct VoronoiPoint {
	vec2 fixedGridPosition;
	float dist;
	float secondDist;
};

const float ROWS = 5;
const float COLS = 5;

const float POINT_OFFSET_FACTOR = 0.6;

const float FONT_SIZE_FACTOR = 0.7;

float uVoronoiTransition1Start = 5;
float uVoronoiTransition2Start = 14.5;

const float SINGLE_TRANSITION_DURATION = 1;

const vec2 TRANSITION_2_UPPER_CORNER = vec2(5, 3);
const float TRANSITION_2_MAX_LENGTH = 10.0;

float getTransition1Start() {
	return uVoronoiTransition1Start;
}

float getTransition2Start() {
	return uVoronoiTransition2Start;
}

float getTransition1Duration() {
	return 9;
}

float getTransition2Duration() {
	return 1.25;
}


vec2 getGridPosition(vec2 coord) {
	return coord * vec2(COLS, ROWS);
}

vec2 fixGridPosition(vec2 pos) {
	return pos - mod(pos, vec2(1)) + vec2(0.5);
}

vec2 getFixedGridPosition(vec2 coord) {
	return fixGridPosition(getGridPosition(coord));
}

vec2 getVoronoiPointPosition(vec2 fixedGridPosition) {
	vec2 fixedOffset = vec2(rand(fixedGridPosition), rand(fixedGridPosition + vec2(1)));
	
	fixedOffset = fixedOffset - vec2(0.5);
	
	float r1 = rand(fixedOffset.x);
	float r2 = rand(fixedOffset.y);
	
	vec2 timeOffset = vec2(sin(iGlobalTime * r1)) * r2 * 0.0;
	
	return fixedGridPosition + fixedOffset * POINT_OFFSET_FACTOR + timeOffset;
}

vec3 getVoronoiPointColor(vec2 fixedGridPosition) {
	float r = rand(fixedGridPosition) * 0.4 + 0.5;
	float b = rand(fixedGridPosition.yx) * 0.2 + 0.8;
	
	//r *= 0.8;
	//b = b + 0.2;
	
	//if (rand(b * 5) > 0.5) return vec3(0.9, r, b);
	
	return vec3(0, r, b);
	
	// (fixedGridPosition.y > 0.5) return vec3(r, 0, b);
	
	//return vec3(b, b * 0.4, b * 0.8);
	
	return vec3(1 + fixedGridPosition.y * 0.5, r, b);
}


VoronoiPoint getVoronoiPoint(vec2 coord) {
	vec2 closestVoronoiPointPosition = vec2(-1);
	
	float closestDistance = 999;
	float secondClosestDistance = 999;
	
	vec2 coordGridPosition = getGridPosition(coord);
	vec2 coordFixedGridPosition = getFixedGridPosition(coord);
	
	vec2 t = fract(coordGridPosition);
	
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			vec2 currentFixedGridPosition = coordFixedGridPosition + vec2(i, j);
			
			vec2 voronoiPointPosition = getVoronoiPointPosition(currentFixedGridPosition);
			
			float dist = distance(coordGridPosition, voronoiPointPosition);
			
			if (dist < closestDistance) {
				secondClosestDistance = closestDistance;
				closestDistance = dist;
				closestVoronoiPointPosition = voronoiPointPosition;
				
			} else if (dist < secondClosestDistance) {
				secondClosestDistance = dist;
			}
		}
	}
	
	return VoronoiPoint(closestVoronoiPointPosition, closestDistance, secondClosestDistance);
}


float getTransition1StartOffset(vec2 fixedGridPosition) {
	return rand(fixedGridPosition);
}

float getTransition2StartOffset(vec2 fixedGridPosition) {
	return distance(fixedGridPosition, TRANSITION_2_UPPER_CORNER) / TRANSITION_2_MAX_LENGTH;
}


float getVisibleDistanceToCenter(vec2 fixedGridPosition) {
	float lastStart1 = getTransition1Duration() - SINGLE_TRANSITION_DURATION;
	float start1 = getTransition1Start() + getTransition1StartOffset(fixedGridPosition) * lastStart1;
	float t1 = mySmoothstep2(iGlobalTime, start1, SINGLE_TRANSITION_DURATION);
	
	float lastStart2 = getTransition2Duration() - SINGLE_TRANSITION_DURATION;
	float start2 = getTransition2Start() + getTransition2StartOffset(fixedGridPosition) * lastStart2;
	float t2 = myReverseSmoothstep2(iGlobalTime, start2, SINGLE_TRANSITION_DURATION);
	
	return iGlobalTime < getTransition2Start() ? t1 : t2;
}


vec4 getAdvancedVoronoiPointColor(VoronoiPoint voronoiPoint) {
	vec3 color = getVoronoiPointColor(voronoiPoint.fixedGridPosition);
	
	float d1 = voronoiPoint.dist;
	float d2 = voronoiPoint.secondDist;
	float distanceToCenter = (d1 / (d1 + d2)) * 2;
	
	float visibleDistanceToCenter = getVisibleDistanceToCenter(voronoiPoint.fixedGridPosition);
	
	if (distanceToCenter < visibleDistanceToCenter) return vec4(color, 1.0);
	
	return vec4(0);
}

vec4 getFontColor(vec2 coord) {
	float u = (coord.x + FONT_SIZE_FACTOR) / (FONT_SIZE_FACTOR * 2);
	float v = (coord.y + FONT_SIZE_FACTOR / 2) / FONT_SIZE_FACTOR;
	
	if (u > 0 && u < 1 && v > 0 && v < 1) {
		return texture(texture0, vec2(u, v));
	}
	
	return vec4(0);
}

vec4 getVoronoiColor(vec2 coord) {
	VoronoiPoint voronoiPoint = getVoronoiPoint(coord);
	
	vec4 voronoiColor = getAdvancedVoronoiPointColor(voronoiPoint);
	
	if (voronoiColor.a > 0.1) {
		vec4 fontColor = getFontColor(coord);
		
		if (fontColor.r > 0.9) return fontColor;
		
		return voronoiColor;
	}
	
	return vec4(0.0);
}


vec4 getVoronoiShaderColor(vec2 coord) {
	return getVoronoiColor(coord);
}



// DOTLINES

const vec2 CENTER = vec2(0.0);
const float CIRCLE_MIN = 0.4;
const float CIRCLE_MAX = 0.55;

float NUMBER_OF_POINTS = 40.0;

const float POINT_GENERAL_OFFSET_FACTOR = 0.25;
const float POINT_RANDOM_OFFSET_FACTOR = 0.2;
const float POINT_MUSIC_AMPLITUDE = 0.1;

const float POINT_SPEED_FACTOR = 0.3;

const float POINT_THICKNESS = 0.001;
const float POINT_GLOW_SIZE = 0.001;

const float MUSIC_LINE_FREQUENCY = 20;
const float MUSIC_LINE_AMPLITUDE = 0.2;
const float MUSIC_LINE_MINIMUM_AMPLITUDE = 0.05;

const float MUSIC_LINE_MINIMUM_SPEED = 0.02;
const float MUSIC_LINE_SPEED_FACTOR = 0.8;

const float MUSIC_LINE_THICKNESS = 0.0015;
const float MUSIC_LINE_GLOW_SIZE = 0.001;

const float MUSIC_LINE_1_X_OFFSET = 15.0;
const float MUSIC_LINE_2_X_OFFSET = 1.0;
const float MUSIC_LINE_3_X_OFFSET = 2.0;
const float MUSIC_LINE_4_X_OFFSET = 4.0;
const float MUSIC_LINE_5_X_OFFSET = 8.0;


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


float getMusicFactor() {
	return uMusic;
}


float noise(float u) {
	float i = floor(u);
	
	float v0 = rand(i);
	float v1 = rand(i + 1);
	
	float f = fract(u);
	float weight = f;
	weight = smoothstep(0, 1, f);
	
	return mix(v0, v1, weight);
}


vec2 getTwelveHand(float seed) {
	float speedFactor = MUSIC_LINE_MINIMUM_SPEED + rand(seed) * MUSIC_LINE_SPEED_FACTOR;
	float x = speedFactor * (iGlobalTime + 0);
	
	return normalize(vec2(sin(x), cos(x)));
}

float getMusicLineValue(vec2 coord, float xOffset) {
	if (!isInCircle(coord)) return 0;
	
	vec2 twelveHand = getTwelveHand(xOffset);
	vec2 coordHand = normalize(coord - CENTER);
	
	float angle = dot(twelveHand, coordHand) * 0.5 + 0.5;
	
	float noiseValue = noise(xOffset + angle * MUSIC_LINE_FREQUENCY) * 0.9 + 0.1;
	
	float coordYValue = length(coord - CENTER);
	coordYValue = mySmoothstep2(coordYValue, getCircleMin(), getCircleMax());
	
	float amplitudeFactor = MUSIC_LINE_MINIMUM_AMPLITUDE + getMusicFactor() * MUSIC_LINE_AMPLITUDE;
	
	float requiredYValue = amplitudeFactor * noiseValue;
	
	float yValueDifference = abs(requiredYValue - coordYValue);
	
	return myReverseSmoothstep2(yValueDifference, MUSIC_LINE_THICKNESS, MUSIC_LINE_THICKNESS + MUSIC_LINE_GLOW_SIZE);
}

float getMusicLinesValue(vec2 coord) {
	float musicLineValue = 0.0;
	
	musicLineValue += getMusicLineValue(coord, MUSIC_LINE_1_X_OFFSET);
	musicLineValue += getMusicLineValue(coord, MUSIC_LINE_2_X_OFFSET) * 0.6;
	musicLineValue += getMusicLineValue(coord, MUSIC_LINE_3_X_OFFSET) * 0.36;
	musicLineValue += getMusicLineValue(coord, MUSIC_LINE_4_X_OFFSET) * 0.216;
	musicLineValue += getMusicLineValue(coord, MUSIC_LINE_5_X_OFFSET) * 0.1296;
	
	return min(musicLineValue, 1.0);
}


vec2 getPointCenter(float index) {
	float randSpeed = (rand(index) - 0.5) * POINT_SPEED_FACTOR;
	
	float angle = (TWOPI / NUMBER_OF_POINTS) * index + iGlobalTime * randSpeed;
	
	float halfCircleSize = (CIRCLE_MAX - CIRCLE_MIN) / 2.0;
	
	float pointStart = CIRCLE_MIN + halfCircleSize * POINT_GENERAL_OFFSET_FACTOR;
	
	float randOffset = pnRand(index) * halfCircleSize * POINT_RANDOM_OFFSET_FACTOR;
	
	float musicOffset = getMusicFactor() * POINT_MUSIC_AMPLITUDE * 0.5;
	
	vec2 pointCenter = vec2(cos(angle), sin(angle)) * (pointStart + randOffset + musicOffset);
	
	return CENTER + pointCenter;
}

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


vec3 getDotlinesShaderColor(vec2 coord) {
	//vec3 color = vec3(0.612, 0.1248, 0.324) * getPointsValue(coord);
	//color += vec3(1.0, 0.99, 0.98) * getMusicLinesValue(coord);
	
	vec3 color = vec3(1.0, 0.99, 0.98) * getPointsValue(coord);
	//color += vec3(0.612, 0.1248, 0.324) * getMusicLinesValue(coord);
	color += vec3(0.8, 0.0, 0.3) * getMusicLinesValue(coord);
	
	float x = distance(CENTER, coord) / 3.0;
	
	vec3 bgColor = x * vec3(0.09, 0.10, 0.11) + (1 - x) * vec3(0.14, 0.15, 0.16);
	
	//vec3 bgColor = vec3(0.07, 0.09, 0.16);
	//vec3 bgColor = getTwoColorBackground(coord, vec3(0.1, 0.11, 0.12), vec3(0.2, 0.22, 0.24) * 1.2);
	
	return color + bgColor;
}



void main() {
    vec2 coord = gl_FragCoord.xy / iResolution;
	
	vec2 newCoords = getAdjustedCoord(coord, iResolution.x / iResolution.y, 1 + iGlobalTime * 0.02);
	
	vec4 color = vec4(0.1, 0.1, 0.1, 1.0);
	
	vec4 voronoiColor = getVoronoiShaderColor(newCoords);
	
	vec3 secondColor = iGlobalTime > getTransition2Start() ? getDotlinesShaderColor(newCoords) : vec3(0.1);
	
	float a = voronoiColor.a;
	
	color = a * voronoiColor + (1 - a) * vec4(secondColor, 1.0);
	
    gl_FragColor = color;
}
