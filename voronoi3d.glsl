#version 330

#include "mylib.glsl"
#include "mylib3d.glsl"
#include "../libs/camera.glsl"


uniform vec2 iResolution;
uniform float iGlobalTime;
uniform vec3 iMouse;


const float EPSILON = 0.001;
const float MAX_STEPS = 500;

const float FOG_START = 10;
const float FOG_END = 50;

float getFogFactor(float distance) {
	if (distance < FOG_START) return 1;
	if (distance > FOG_END) return 0;
	
	return (FOG_END - distance) / (FOG_END - FOG_START);
}




const float ROWS = 10;
const float COLS = 10;

const float POINT_OFFSET_FACTOR = 0.4;

vec2 getGridPosition(vec2 coord) {
	return coord * vec2(COLS, ROWS);
}

vec2 fixGridPosition(vec2 pos) {
	return pos - mod(pos, vec2(1)) + vec2(0.5);
}

vec2 getFixedGridPosition(vec2 coord) {
	return fixGridPosition(getGridPosition(coord));
}

// TODO: offset auch negativ
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
	
	return vec3(r, 0, b);
}

const float BASIC_HEIGHT = 0.5;
const float HEIGHT_OFFSET_FACTOR = 0.4;

float getVoronoiHeight(vec2 fixedGridPos) {
	float offset = rand(fixedGridPos);
	
	return BASIC_HEIGHT + offset * HEIGHT_OFFSET_FACTOR;
}


vec2 getVoronoiPoint(vec2 coord) {
	vec2 closestVoronoiPoint = vec2(-1);
	
	float closestDistance = 999;
	
	vec2 coordGridPosition = getGridPosition(coord);
	vec2 coordFixedGridPosition = getFixedGridPosition(coord);
	
	vec2 t = fract(coordGridPosition);
	
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			
			vec2 currentFixedGridPosition = coordFixedGridPosition + vec2(i, j);
			
			vec2 voronoiPointPosition = getVoronoiPointPosition(currentFixedGridPosition);
			
			float dist = distance(coordGridPosition, voronoiPointPosition);
			
			if (dist < closestDistance) {
				closestDistance = dist;
				closestVoronoiPoint = voronoiPointPosition;
			}
		}
	}
	
	return closestVoronoiPoint;
}

bool areInSameVoronoiPart(vec2 point1, vec2 point2) {
	return getVoronoiPoint(point1) == getVoronoiPoint(point2);
}

vec3 getVoronoiColor(vec2 coord) {
	vec3 color = vec3(1);
	
	float closestDistance = 999;
	
	vec2 coordGridPosition = getGridPosition(coord);
	vec2 coordFixedGridPosition = getFixedGridPosition(coord);
	
	vec2 t = fract(coordGridPosition);
	
	//if (t.x < 0.03 || t.y < 0.03) return vec3(1);
	
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			
			vec2 currentFixedGridPosition = coordFixedGridPosition + vec2(i, j);
			
			vec2 voronoiPointPosition = getVoronoiPointPosition(currentFixedGridPosition);
			
			float dist = distance(coordGridPosition, voronoiPointPosition);
			
			//if (dist < 0.03) return vec3(1);
			
			if (dist < closestDistance) {
				closestDistance = dist;
				color = getVoronoiPointColor(currentFixedGridPosition);
			}
		}
	}
	
	return color;
}



const float STEP_FACTOR = 2;
const int BORDER_POINT_ACCURACY = 15;

const float STEP_FACTOR_ADDITION = 0.005;

vec2 getBorderPoint(vec2 point, vec2 direction) {
	
	float stepFactor = 0;
	
	float additionalStepFactor = 1.01 * STEP_FACTOR;
	
	for (int i = 0; i < BORDER_POINT_ACCURACY; i++) {
		vec2 farPoint = point + direction * (stepFactor + additionalStepFactor);
		
		if (areInSameVoronoiPart(point, farPoint)) {
			stepFactor += additionalStepFactor;
		}
		
		additionalStepFactor *= 0.5;
	}
	
	return point + direction * (stepFactor + STEP_FACTOR_ADDITION);
}



float getVoronoiFieldDistance(vec3 point, vec3 rayDirection) {
	
	vec2 point2D = point.xz;
	vec2 rayDirection2D = normalize(rayDirection.xz);
	
	float currentPointHeight = getVoronoiHeight(point2D);
	float horizontalDistance = point.y - currentPointHeight; // TODO: STIMMT EVTL NICHT
	
	if (horizontalDistance >= EPSILON) return horizontalDistance;
	
	
	// PF
	
	vec2 np = point2D + horizontalDistance * rayDirection2D;
	
	//if (areInSameVoronoiPart(point2D, np)) return horizontalDistance;
	
	
	// TODO: PERFORMANCE: additionalStepFactor startet bei horizontalDistance
	
	vec2 borderPoint = getBorderPoint(point2D, rayDirection2D);
	
	float borderPointHeight = getVoronoiHeight(borderPoint);
	
	float borderPointHorizontalDistance = point.y - borderPointHeight;
	
	
	return 0.0;
	
	// float dist = h(A);
	
	// if (dist <= EPSILON) return dist;
	
	// vec2 nextP = getNextPoint(jumpDistance);
	
	// if (nextP == sameAsCurrent) return dist;
	
	// if (h(A) > h(nextP)) return dist;
	
	// find G
	
	// return min(dist, length(G - A));
}


RayResult distFuncWithColor(vec3 point) {
	
	vec3 boxC = vec3(0, 3, 0);
	vec3 boxB = vec3(10, 0.1, 10);
	
	float boxDist = getBoxDistance(boxC, boxB, point);
	
	if (boxDist > 0.05) return NoHitRayResult(boxDist);
	
	vec3 cl = getVoronoiColor(point.xz * 0.2);
	
	float vDist = abs(point.y - (cl.r * 2 + cl.b));
	
	float dist = min(vDist, 0.02);
	
	return NoLightRayResult(dist, cl);
	
}


float distFunc(vec3 rayPoint) {
	RayResult rayResult = distFuncWithColor(rayPoint);

	return rayResult.dist;
}

vec3 getNormal(vec3 point)
{
	float d = 0.0001;
	//get points a little bit to each side of the point
	vec3 right = point + vec3(d, 0.0, 0.0);
	vec3 left = point + vec3(-d, 0.0, 0.0);
	vec3 up = point + vec3(0.0, d, 0.0);
	vec3 down = point + vec3(0.0, -d, 0.0);
	vec3 behind = point + vec3(0.0, 0.0, d);
	vec3 before = point + vec3(0.0, 0.0, -d);
	//calc difference of distance function values == numerical gradient
	vec3 gradient = vec3(distFunc(right) - distFunc(left),
		distFunc(up) - distFunc(down),
		distFunc(behind) - distFunc(before));
	return normalize(gradient);
}


float test(vec2 coord) {
	vec2 pn = vec2(0.1, 0.3) + vec2(0.2, 0.1) * iGlobalTime * 0.05;
	
	vec2 dir = normalize(vec2(0.1, 0.3));
	
	float pn1 = myReverseSmoothstep2(distance(pn, coord), 0, 0.005) * 2;
	
	vec2 borderPoint = getBorderPoint(pn, dir);
	
	float bp1 = myReverseSmoothstep2(distance(borderPoint, coord), 0, 0.005);
	
	return pn1 + bp1;
}


void main() {
	//coordinates in range [0,1]
    vec2 coord = gl_FragCoord.xy/iResolution;
	
	coord.x *= iResolution.x / iResolution.y;
	
	vec3 color = getVoronoiColor(coord);
	
	
	float t = test(coord);
	
	if (t > 1.1) color = vec3(1);
	else if (t > 0) color = vec3(1.0, 0.5, 0.0);
	
    gl_FragColor = vec4(color, 1.0);
	
	//camera setup
	vec3 camP = calcCameraPos();
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);
	
	//vec3 color = vec3(0.1);
	
	vec3 point = camP;
	
	int step = 0;
	
	bool hit = false;
	
	while (step < MAX_STEPS) {
		
		RayResult rayResult = distFuncWithColor(point);
		float hitDistance = rayResult.dist;
		vec3 hitColor = rayResult.color;
		
		float distanceToCam = distance(camP, point);
		
		if (distanceToCam > FOG_END) break;
		
		if (hitDistance < EPSILON) {
			hit = true;
			
			color = hitColor;
			
			break;
		}
		
		point = point + camDir * hitDistance;
	
		step++;
	}
	
	
    //gl_FragColor = vec4(color, 1.0);
}
