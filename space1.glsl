#version 330

#include "mylib.glsl"


uniform vec2 iResolution;
uniform float iGlobalTime;

const float EPSILON = 0.0001;



const float N_ROWS = 25;

const float VISIBILITY_THRESHOLD = 0.8;

const float OFFSET_FACTOR = 0.1;

const float SHININESS_TIME_FACTOR = 0.2;

const float SHININESS_EXPONENT = 128;

const float SHININESS_FACTOR = 2.0;



const float FARTHEST_STAR_SIZE = 0.2;

const float DISTANCE_BETWEEN_LAYERS = 0.3;

const float INTRA_LAYER_DISTANCE = 0.2;


float getShininess(vec2 fixedGridPos) {
	float randVal = rand(fixedGridPos + vec2(0.33, 0.82));
	
	float pr = randVal * 6.28 + iGlobalTime * SHININESS_TIME_FACTOR;
	
	return pow(max(sin(pr), 0.0), SHININESS_EXPONENT);
}

float getStarValueFromLayer(int layer, vec2 coord) {
	
	coord.y += iGlobalTime * (0.01 + layer * 0.004);
	
	vec2 posInGrid = coord * N_ROWS;
	vec2 fixedGridPos = floor(posInGrid);
	vec2 middle = fixedGridPos + vec2(0.5);
	
	vec2 offset = rand2(fixedGridPos) - vec2(0.5);
	
	vec2 starPos = middle + offset * OFFSET_FACTOR;
	
	// test
	//if (fract(posInGrid.x) < 0.1 || fract(posInGrid.y) < 0.1) return 0.2;
	
	//if (mod(coord.x, 0.3) < 0.005) return 0.2;
	
	float randomValue = rand(fixedGridPos * (layer + 0.7));
	
	if (rand(randomValue) < VISIBILITY_THRESHOLD) return 0;
	
	float lfB = layer * 0.3;
	float rhB = (layer + 1) * 0.3;
	
	//if (coord.x < lfB || coord.x > rhB) return 0.0;
	
	
	float size = 0;
	float distanceFactor = 8 - 5 * randomValue - size;
	
	float dist = distance(posInGrid, starPos);
	
	
	float starSize = FARTHEST_STAR_SIZE + layer * DISTANCE_BETWEEN_LAYERS;
	
	float intraDistanceFactor = rand(randomValue + 1);
	float intraLayerOffset = INTRA_LAYER_DISTANCE * intraDistanceFactor;
	
	starSize += intraLayerOffset;
	
	
	float shininess = getShininess(fixedGridPos) * SHININESS_FACTOR;
	
	float exponent = starSize + shininess;
	
	float starValue = myReverseSmoothstep2(dist, 0, exponent);
	
	starValue = pow(starValue, 40);
	
	return starValue;
}

float getStarValue(vec2 coord) {
	float starValue = 0.0;
	
	for (int i = 0; i < 4; i++) {
		starValue = max(starValue, getStarValueFromLayer(i, coord));
	}
	
	return starValue;
}

float getShootingStarValue(vec2 coord) {

	float period = 4;

	float fixedTime = floor(iGlobalTime / period);
	float partialTime = mod(iGlobalTime, period);
	
	vec2 startingPos = rand2(vec2(cos(fixedTime * 0.92), sin(fixedTime * 1.12)));
	startingPos = startingPos * vec2(1, 0.5) + vec2(1, 0.5);
	
	vec2 randomDirection = rand2(vec2(sin(fixedTime * 1.04), cos(fixedTime * 1.03)));
	vec2 direction = mix(vec2(-1, -0.4), randomDirection, 0.3);
	direction = normalize(direction);
	
	vec2 starPos = startingPos + direction * partialTime * 0.1;
	
	//float val = max(0.05 - distance(coord, starPos), 0);
	
	float orthFactor = 0.001;
	vec2 stp1 = starPos + vec2(-direction.y, direction.x) * orthFactor;
	vec2 stp2 = starPos + vec2(direction.y, -direction.x) * orthFactor;
	
	float distanceVal = pow(max(0.1 - distance(coord, starPos), 0), 2);
	
	float trailVal1 = dot(direction, normalize(starPos - coord));
	float trailVal2 = max(dot(direction, normalize(stp1 - coord)), 0);
	float trailVal3 = max(dot(direction, normalize(stp2 - coord)), 0);
	
	float trailVal = max(trailVal1, max(trailVal2, trailVal3));
	trailVal = pow(trailVal, 256);
	
	//if (trailVal1 < 0.005) trailVal = 0;
	
	//if (distance(coord, starPos) < 0.005) return 1;
	//if (distance(coord, stp1) < 0.005) return 1;
	//if (distance(coord, stp2) < 0.005) return 1;
	
	float val = distanceVal * trailVal;
	
	val = pow(val, 0.3);
	
	//if (trailVal1 < 0) val = 0;
	
	float visibility = sin(partialTime * (3.14 / period));
	visibility = pow(visibility, 16);
	
	//visibility = 1;

	return val * visibility;
}

void main() {
	//coordinates in range [0,1]
    vec2 coord = gl_FragCoord.xy/iResolution;
	
	coord.x *= iResolution.x / iResolution.y;

	float starValue = getStarValue(coord);
	
	float shootingStarValue = getShootingStarValue(coord);
	
	float value = starValue + shootingStarValue;
	
	const vec3 white = vec3(1);
	
	//float f1 = cos(pow(coord.x, coord.x * 0.5)) * cos(coord.x);
	//float f2 = sin(coord.y + 0.2);
	
	float f1 = cos(coord.x + 0.2);
	float f2 = cos(coord.y + 0.1);
	
	float greenFactor = f1 * 0.5 + f2 * 0.5;
	
	float blueFactor = 1 - greenFactor;
	
	greenFactor *= 0.5;
	blueFactor *= 0.5;
	
	vec3 bgColor = vec3(0.0, 0.2 + greenFactor, 0.5 + blueFactor) * 0.4;
	
	vec3 color = value * white + (1 - value) * bgColor;
		
    gl_FragColor = vec4(color, 1.0);
}
