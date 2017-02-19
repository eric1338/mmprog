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



float nX = 10;
float nY = 10;


const float ROWS = 10;
const float COLS = 10;

vec2 getGridPosition(vec2 coord) {
	return coord * vec2(COLS, ROWS);
}

vec2 getCoord(vec2 gridPosition) {
	return gridPosition / vec2(COLS, ROWS);
}

vec2 fixGridPosition(vec2 pos) {
	return pos - mod(pos, vec2(1)) + vec2(0.5);
}

vec2 getFixedGridPosition(vec2 coord) {
	return fixGridPosition(getGridPosition(coord));
}


vec3 getSquareColor(vec2 coord) {
	vec2 fixedGridPos = getFixedGridPosition(coord);
	
	vec2 color2 = rand2(fixedGridPos);
	
	float r = rand(fixedGridPos) * 0.5 + 0.5;
	float b = rand(fixedGridPos.yx) * 0.5 + 0.5;
	
	return vec3(r, 0, b);
}

vec3 getSquareColor2(vec2 fixedGridPos) {
	vec2 color2 = rand2(fixedGridPos);
	
	float r = rand(fixedGridPos) * 0.5 + 0.5;
	float b = rand(fixedGridPos.yx) * 0.5 + 0.5;
	
	return vec3(r, 0, b);
}

const float BASIC_HEIGHT = 0.5;
const float HEIGHT_OFFSET_FACTOR = 0.2;

float getSquareHeight(vec2 fixedGridPos) {
	float offset = rand(fixedGridPos);
	
	return BASIC_HEIGHT + offset * HEIGHT_OFFSET_FACTOR;
}



const float FACTOR_ADDITION = 0.02;

vec2 getNextBorderPoint(vec2 point, vec2 rayDirection) {
	vec2 gridPoint = getGridPosition(point);
	
	float xFactor = (1 - fract(gridPoint.x)) / rayDirection.x;
	
	float yFactor = (1 - fract(gridPoint.y)) / rayDirection.y;
	
	float factor = min(xFactor, yFactor) + FACTOR_ADDITION;
	
	return getCoord(gridPoint + (factor * rayDirection));
}



RayResult getSquareFieldDistance(vec3 point, vec3 rayDirection) {
	vec2 point2D = point.xz;
	vec2 rayDirection2D = normalize(rayDirection.xz);
	vec2 fixedGridPoint2D = getFixedGridPosition(point2D);
	
	float currentPointHeight = getSquareHeight(fixedGridPoint2D);
	vec3 currentPointColor = getSquareColor(fixedGridPoint2D);
	
	float verticalDistance = point.y - currentPointHeight; // TODO: STIMMT EVTL NICHT
	
	if (verticalDistance <= EPSILON) return NoLightRayResult(verticalDistance, currentPointColor);
	
	vec2 nextBorderPoint = getNextBorderPoint(point2D, rayDirection2D);
	
	float nextPointHeight = getSquareHeight(nextBorderPoint);
	vec3 nextPointColor = getSquareColor(nextBorderPoint);
	
	float horizontalDistance = distance(point2D, nextBorderPoint);
	
	if (horizontalDistance <= EPSILON) return NoLightRayResult(horizontalDistance, nextPointColor);
	
	
	if (currentPointHeight > nextPointHeight) {
		vec2 nextNextBorderPoint = getNextBorderPoint(nextBorderPoint, rayDirection2D);
		
		float farHorizontalDistance = distance(point2D, nextNextBorderPoint);
		
		return NoHitRayResult(min(verticalDistance, farHorizontalDistance));
	}
	
	return NoHitRayResult(min(verticalDistance, horizontalDistance));
	
	
	// PF
	
	//vec2 np = point2D + horizontalDistance * rayDirection2D;
	
	//if (areInSameVoronoiPart(point2D, np)) return horizontalDistance;
	
	
	// TODO: PERFORMANCE: additionalStepFactor startet bei horizontalDistance
	
	//vec2 borderPoint = getBorderPoint(point2D, rayDirection2D);
	
	//float borderPointHeight = getVoronoiHeight(borderPoint);
	
	//float borderPointHorizontalDistance = point.y - borderPointHeight;
	
	
	
	// float dist = h(A);
	
	// if (dist <= EPSILON) return dist;
	
	// vec2 nextP = getNextPoint(jumpDistance);
	
	// if (nextP == sameAsCurrent) return dist;
	
	// if (h(A) > h(nextP)) return dist;
	
	// find G
	
	// return min(dist, length(G - A));
}






RayResult distFuncWithColor2(vec3 point) {
	
	vec3 boxC = vec3(0, 3, 0);
	vec3 boxB = vec3(10, 0.1, 10);
	
	float boxDist = getBoxDistance(boxC, boxB, point);
	
	if (boxDist > 0.05) return NoHitRayResult(boxDist);
	
	//vec3 cl = getVoronoiColor(point.xz * 0.2);
	vec3 cl = vec3(0);
	
	float vDist = abs(point.y - (cl.r * 2 + cl.b));
	
	float dist = min(vDist, 0.02);
	
	return NoLightRayResult(dist, cl);
	
}

RayResult distFuncWithColor(vec3 rayPoint, vec3 rayDirection) {
	return getSquareFieldDistance(rayPoint, rayDirection);
}



float distFunc(vec3 rayPoint, vec3 rayDirection) {
	RayResult rayResult = distFuncWithColor(rayPoint, rayDirection);

	return rayResult.dist;
}

vec3 getNormal(vec3 rayPoint, vec3 rayDirection)
{
	float d = 0.0001;
	//get points a little bit to each side of the point
	vec3 right = rayPoint + vec3(d, 0.0, 0.0);
	vec3 left = rayPoint + vec3(-d, 0.0, 0.0);
	vec3 up = rayPoint + vec3(0.0, d, 0.0);
	vec3 down = rayPoint + vec3(0.0, -d, 0.0);
	vec3 behind = rayPoint + vec3(0.0, 0.0, d);
	vec3 before = rayPoint + vec3(0.0, 0.0, -d);
	//calc difference of distance function values == numerical gradient
	
	float gradientX = distFunc(right, rayDirection) - distFunc(left, rayDirection);
	float gradientY = distFunc(up, rayDirection) - distFunc(down, rayDirection);
	float gradientZ = distFunc(behind, rayDirection) - distFunc(before, rayDirection);
	
	return normalize(vec3(gradientX, gradientY, gradientZ));
}


float test(vec2 coord) {
	vec2 pn = vec2(0.1, 0.32) + vec2(0.2, 0.1) * iGlobalTime * 0.2;
	
	vec2 dir = normalize(vec2(0.2, 0.1));
	
	float pn1 = myReverseSmoothstep2(distance(pn, coord), 0, 0.005) * 2;
	
	vec2 borderPoint = getNextBorderPoint(pn, dir);
	
	float bp1 = myReverseSmoothstep2(distance(borderPoint, coord), 0, 0.005);
	
	return pn1 + bp1;
}


void main() {
	//coordinates in range [0,1]
    vec2 coord = gl_FragCoord.xy/iResolution;
	
	coord.x *= iResolution.x / iResolution.y;
	
	//vec3 color = getSquareColor(coord);
	
	//float t = test(coord);
	
	//if (t > 1.1) color = vec3(1);
	//else if (t > 0) color = vec3(1.0, 0.8, 0.0);
	
    //gl_FragColor = vec4(color, 1.0);
	
	//camera setup
	vec3 camP = calcCameraPos();
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);
	
	vec3 color = vec3(0.1);
	
	vec3 point = camP;
	
	int step = 0;
	
	bool hit = false;
	
	while (step < MAX_STEPS) {
		
		RayResult rayResult = distFuncWithColor(point, camDir);
		float hitDistance = rayResult.dist;
		vec3 hitColor = rayResult.color;
		
		float distanceToCam = distance(camP, point);
		
		if (distanceToCam > FOG_END) break;
		
		if (hitDistance < EPSILON) {
			hit = true;
			
			color = hitColor;
			
			vec3 hitNormal = getNormal(point, camDir);
			vec3 toLight = normalize(vec3(-100, 100, -100) - point);
			
			float lambert = max(dot(hitNormal, toLight), 0.2);
			
			//color *= lambert;
			
			break;
		}
		
		point = point + camDir * hitDistance;
	
		step++;
	}
	
	
    gl_FragColor = vec4(color, 1.0);
}
