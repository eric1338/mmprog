#version 330

#include "mylib.glsl"
#include "mylib3d.glsl"
#include "../libs/camera.glsl"
#include "../libs/operators.glsl"


uniform vec2 iResolution;
uniform float iGlobalTime;

uniform float uMusic;

const float EPSILON = 0.001;

const float MAX_STEPS = 200;

const float FOG_START = 30;
const float FOG_END = 200;

float getFogFactor(float distance) {
	if (distance < FOG_START) return 1;
	if (distance > FOG_END) return 0;
	
	return (FOG_END - distance) / (FOG_END - FOG_START);
}



const float ISLAND_VISIBILITY_THRESHOLD = 0.7;

const float ISLAND_RADIUS = 2.5;
const float ISLANDS_DISTANCE = 20;

const float BOX_HALF_WIDTH = 0.3;
const float BOX_MIN_HEIGHT = 0.5;
const float BOX_HEIGHT_RAND_OFFSET_FACTOR = 0.25;
const float BOX_HEIGHT_MUSIC_OFFSET_FACTOR = 0.25;
const float BOXES_MARGIN_FACTOR = 1.1;

const vec3 ISLAND_TOP_COLOR = vec3(0.3, 0.6, 0.3);
const vec3 ISLAND_BOTTOM_COLOR = vec3(0.4, 0.2, 0.1);

//const vec3 BG_COLOR_1 = vec3(0.2, 0.6, 1.0);
//const vec3 BG_COLOR_2 = vec3(0.5, 0.9, 1.0);

const vec3 BG_COLOR_1 = vec3(0.1, 0.4, 1.0);
const vec3 BG_COLOR_2 = vec3(0.2, 0.6, 1.0);


float getMusicFactor() {
	return uMusic;
}


vec3 getModRayPoint(vec3 rayPoint) {
	//vec3 modVector = vec3(ISLANDS_DISTANCE, 1, ISLANDS_DISTANCE);
	vec3 modVector = vec3(ISLANDS_DISTANCE, ISLANDS_DISTANCE, ISLANDS_DISTANCE);
	
	vec3 modRayPoint = mod(rayPoint, modVector) - 0.5 * modVector;
	
	return modRayPoint;
	//return vec3(modRayPoint.x, rayPoint.y, modRayPoint.z);
}

vec3 getFixedRayPoint(vec3 rayPoint) {
	float fx = rayPoint.x - mod(rayPoint.x, ISLANDS_DISTANCE);
	float fy = rayPoint.y - mod(rayPoint.y, ISLANDS_DISTANCE);
	float fz = rayPoint.z - mod(rayPoint.z, ISLANDS_DISTANCE);
	
	return vec3(fx, fy, fz);
}

float getIslandRandVal(vec3 rayPoint) {
	vec3 frp = getFixedRayPoint(rayPoint);
	
	return (rand(frp.xy) + rand(frp.zx) + rand(frp.yz)) / 3.0;
}

const vec3 BOX_COLOR_1 = vec3(1.0, 0.0, 0.4);
const vec3 BOX_COLOR_2 = vec3(1.0, 0.8, 0.4);
const vec3 BOX_COLOR_3 = vec3(0.0, 0.4, 1.0);

vec3 getBoxColor(float randVal) {
	if (randVal < 0.33) return BOX_COLOR_1;
	if (randVal < 0.66) return BOX_COLOR_2;
	
	return BOX_COLOR_3;
}


RayResult getIslandResult(vec3 rayPoint) {
	vec3 halfCircleCenter = vec3(0);
	
	float yDiff = rayPoint.y - halfCircleCenter.y;
	
	float sphereDistance = sSphere(rayPoint, halfCircleCenter, ISLAND_RADIUS);
	
	if (yDiff > 1.1 * EPSILON) return NoHitRayResult(max(sphereDistance, yDiff));
	
	vec3 islandColor = yDiff > -0.05 ? ISLAND_TOP_COLOR : ISLAND_BOTTOM_COLOR;
	
	return NoLightRayResult(sphereDistance, islandColor);
}



RayResult getBoxResult(vec3 rayPoint, vec3 modRayPoint, int i, int j) {
	float randVal = rand(vec2(i, j) + getIslandRandVal(rayPoint));
	
	float boxHeightOffset = randVal * BOX_HEIGHT_RAND_OFFSET_FACTOR + getMusicFactor() * BOX_HEIGHT_MUSIC_OFFSET_FACTOR;
	
	float boxHeight = BOX_MIN_HEIGHT + boxHeightOffset;
	
	vec3 boxCenter = vec3(0, boxHeight, 0) + vec3(i, 0, j) * BOXES_MARGIN_FACTOR;
	vec3 boxB = vec3(BOX_HALF_WIDTH, boxHeight, BOX_HALF_WIDTH);
	
	float boxDistance = getBoxDistance(boxCenter, boxB, modRayPoint);
	
	vec3 boxColor = getBoxColor(randVal);
	
	return NoLightRayResult(boxDistance, boxColor);
}


RayResult getBoxesResult(vec3 rayPoint, vec3 modRayPoint) {
	RayResult closestResult = NoHitRayResult(9999);
	
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			RayResult boxResult = getBoxResult(rayPoint, modRayPoint, i, j);
			
			closestResult = getCloserRayResult(closestResult, boxResult);
		}
	}
	
	return closestResult;
}


RayResult distFuncWithColor(vec3 rayPoint) {
	vec3 modRayPoint = getModRayPoint(rayPoint);
	
	if (getIslandRandVal(rayPoint) < ISLAND_VISIBILITY_THRESHOLD) {
		return NoHitRayResult(ISLANDS_DISTANCE / 4.0);
	}
	
	RayResult islandResult = getIslandResult(modRayPoint);
	RayResult boxesResult = getBoxesResult(rayPoint, modRayPoint);
	
	return getCloserRayResult(islandResult, boxesResult);
}

float distFunc(vec3 rayPoint) {
	RayResult rayResult = distFuncWithColor(rayPoint);

	return rayResult.dist;
}


//by numerical gradient
vec3 getNormal(vec3 point) {
	float d = EPSILON;
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


float noise(vec2 coord) {
	vec2 i = floor(coord); // integer position

	//random value at nearest integer positions
	float v00 = rand(i);
	float v10 = rand(i + vec2(1, 0));
	float v01 = rand(i + vec2(0, 1));
	float v11 = rand(i + vec2(1, 1));
	
	vec2 f = fract(coord);
	vec2 weight = f; // linear interpolation
	weight = smoothstep(0, 1, f); // cubic interpolation

	float x1 = mix(v00, v10, weight.x);
	float x2 = mix(v01, v11, weight.x);
	return mix(x1, x2, weight.y);
}

float fBm(vec2 coord) {
	// Properties
	int octaves = 6;
	float lacunarity = 2.5;
	float gain = 0.5;
	// Initial values
	float amplitude = 0.5;
	float value = 0;
	
	// Loop of octaves
	for (int i = 0; i < octaves; ++i) {
		value += amplitude * noise(coord);
		coord *= lacunarity;
		amplitude *= gain;
	}
	
	return value;
}



vec3 getBackgroundColor(vec2 coord) {
	return getTwoColorBackground(coord, BG_COLOR_1, BG_COLOR_2) + fBm(coord) * 0.5 * vec3(1);
}


void main() {
	vec3 camP = calcCameraPos();
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);
	
	vec4 color4 = vec4(0);
	
	vec3 point = camP;
	
	int step = 0;
	
	bool hit = false;
	
	float fogFactor = 0;
	
	while (step < MAX_STEPS) {
		RayResult rayResult = distFuncWithColor(point);
		float hitDistance = rayResult.dist;
		vec3 hitColor = rayResult.color;
		
		float distanceToCam = distance(camP, point);
		
		if (distanceToCam > FOG_END) break;
		
		if (hitDistance < EPSILON) {
			hit = true;
			
			vec3 color = hitColor;
			
			vec3 hitNormal = getNormal(point);
			vec3 toLight = normalize(vec3(-80, 100, -80) - point);
			
			float lambert = max(dot(hitNormal, toLight), 0.2);
			
			if (rayResult.lightFactor < 0.5) color *= lambert;
			
			fogFactor = getFogFactor(distanceToCam);
			
			color4 = vec4(color, 1.0);
			
			break;
		}
		
		point = point + camDir * hitDistance;
	
		step++;
	}
	
	vec3 backgroundColor = getBackgroundColor(camDir.xy);
	
	color4 = fogFactor * color4 + (1 - fogFactor) * vec4(backgroundColor, 1.0);
	
	gl_FragColor = color4;
}

