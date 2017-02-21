#version 330

#include "mylib.glsl"


uniform vec2 iResolution;
uniform float iGlobalTime;

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

float uVoronoiTransition1Start = 0;
float uVoronoiTransition2Start = 7;

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
	return 5;
}

float getTransition2Duration() {
	return 2;
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
	float r = rand(fixedGridPosition) * 0.5 + 0.5;
	float b = rand(fixedGridPosition.yx) * 0.5 + 0.5;
	
	return vec3(0, r, b);
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

vec3 getVoronoiColor(vec2 coord) {
	VoronoiPoint voronoiPoint = getVoronoiPoint(coord);
	
	vec4 voronoiColor = getAdvancedVoronoiPointColor(voronoiPoint);
	
	if (voronoiColor.a > 0.1) {
		vec4 fontColor = getFontColor(coord);
		
		if (fontColor.r > 0.9) return fontColor.rgb;
		
		return voronoiColor.rgb;
	}
	
	return vec3(0.1);
}


void main() {
	//coordinates in range [0,1]
    vec2 coord = gl_FragCoord.xy/iResolution;
	
	coord = getAdjustedCoord(coord, iResolution.x / iResolution.y, 1 + iGlobalTime * 0.02);
	
	vec3 color = getVoronoiColor(coord);
	
    gl_FragColor = vec4(color, 1.0);
}
