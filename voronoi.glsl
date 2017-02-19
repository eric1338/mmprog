#version 330

#include "mylib.glsl"


uniform vec2 iResolution;
uniform float iGlobalTime;


const float EPSILON = 0.001;


const float ROWS = 5;
const float COLS = 5;

const float POINT_OFFSET_FACTOR = 0.6;


vec2 getGridPosition(vec2 coord) {
	return coord * vec2(COLS, ROWS);
}

vec2 fixGridPosition(vec2 pos) {
	return pos - mod(pos, vec2(1)) + vec2(0.5);
}

vec2 getFixedGridPosition(vec2 coord) {
	return fixGridPosition(getGridPosition(coord));
}

vec2 getVoronoiPointPosition(vec2 fixedGridPos) {
	vec2 fixedOffset = vec2(rand(fixedGridPos), rand(fixedGridPos + vec2(1)));
	
	fixedOffset = fixedOffset - vec2(0.5);
	
	float r1 = rand(fixedOffset.x);
	float r2 = rand(fixedOffset.y);
	
	vec2 timeOffset = vec2(sin(iGlobalTime * r1)) * r2 * 0.0;
	
	return fixedGridPos + fixedOffset * POINT_OFFSET_FACTOR + timeOffset;
}

vec3 getVoronoiPointColor(vec2 fixedGridPos) {
	vec2 color2 = rand2(fixedGridPos);
	
	float r = rand(fixedGridPos) * 0.5 + 0.5;
	float b = rand(fixedGridPos.yx) * 0.5 + 0.5;
	
	return vec3(0, r, b);
}



float getVoronoiRnd(vec2 fixedGridPos) {
	float rnd = rand(fixedGridPos);
	
	return rnd;
}


struct VoronoiPoint {
	vec2 fixedPosition;
	float dist;
	float secondDist;
};


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


float getThres1() {
	return iGlobalTime * 0.1;
}

float getThres2() {
	return getThres1() - 0.2;
}


float getVoronoiRnd2(vec2 fixedPos) {
	return distance(vec2(0), fixedPos) * 0.1;
}


vec3 getAdvancedVoronoiPointColor(VoronoiPoint voronoiPoint) {
	vec3 color = getVoronoiPointColor(voronoiPoint.fixedPosition);
	
	// [0.5, 1] -> 0
	float dif = voronoiPoint.secondDist - voronoiPoint.dist;
	
	float d1 = voronoiPoint.dist;
	float d2 = voronoiPoint.secondDist;
	
	// 0 -> 1
	float dif2 = (d1 / (d1 + d2)) * 2;
	//dif2 = 1 - dif2;
	
	//return vec3(dif2);
	
	float start = getVoronoiRnd2(voronoiPoint.fixedPosition);
	float test = myReverseSmoothstep2(start, getThres2() * 10, 1);
	
	//return vec3(test);
	
	if (dif2 < test) return color;
	
	return vec3(0.1);
	
	float factor = 1;
	
	if (dif < 0.4) factor = 0.6 + dif;
	
	return color * factor;
}

vec3 getVoronoiColor(vec2 coord) {
	VoronoiPoint voronoiPoint = getVoronoiPoint(coord);
	
	float rnd = getVoronoiRnd2(voronoiPoint.fixedPosition);
	
	//if (rnd > getThres1()) return vec3(0.1);
	
	vec3 color = getAdvancedVoronoiPointColor(voronoiPoint);
	
	return color;
}



void main() {
	//coordinates in range [0,1]
    vec2 coord = gl_FragCoord.xy/iResolution;
	
	coord.x *= iResolution.x / iResolution.y;
	
	coord *= (1 + iGlobalTime * 0.02);
	
	vec3 color = getVoronoiColor(coord);
	
    gl_FragColor = vec4(color, 1.0);
}
