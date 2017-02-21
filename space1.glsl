#version 330

#include "mylib.glsl"
#include "../libs/camera.glsl"
#include "../libs/noise3D.glsl"


uniform vec2 iResolution;
uniform float iGlobalTime;

const float EPSILON = 0.0001;



const float N_ROWS = 25;

const float VISIBILITY_THRESHOLD = 0.8;

const float OFFSET_FACTOR = 0.1;

const float LAYER_OFFSET = 0.05;

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
	
	vec2 newCoord = coord + vec2(layer * LAYER_OFFSET);
	
	newCoord.y += iGlobalTime * (0.01 + layer * 0.004);
	
	vec2 posInGrid = newCoord * N_ROWS;
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

const float SHOOTING_STAR_THICKNESS = 0.0012;

float getLineValue(vec2 pointA, vec2 pointB, vec2 coord) {
	float thickness = 0.002;
	
	float sideA = length(coord - pointB);
	float sideB = length(pointA - coord);
	float sideC = length(pointB - pointA);
	
	if (sideA >= sideC || sideB >= sideC) {
		return mix(1.0, 0.0, smoothstep(0.1 * SHOOTING_STAR_THICKNESS, 2 * SHOOTING_STAR_THICKNESS, sideA * 0.5));
	
		//return 0.0;
	}
	
	float s = (sideA + sideB + sideC) / 2.0;
	
	float area = sqrt(s * (s - sideA) * (s - sideB) * (s - sideC));
	
	float height = area / sideC;
	
	float wholeLine = mix(1.0, 0.0, smoothstep(0.1 * SHOOTING_STAR_THICKNESS, 2 * SHOOTING_STAR_THICKNESS, height));
	
	return wholeLine * (distance(coord, pointA) / distance(pointA, pointB));
}


const float SHOOTING_STAR_PERIOD = 4.0;

const float SHOOTING_STAR_EXPONENT = 16.0;

float getShootingStarValue(vec2 coord) {
	float fixedTime = floor(iGlobalTime / SHOOTING_STAR_PERIOD);
	float partialTime = mod(iGlobalTime, SHOOTING_STAR_PERIOD);
	
	vec2 startingPos = rand2(vec2(cos(fixedTime * 0.92), sin(fixedTime * 1.12)));
	startingPos = startingPos * vec2(1, 0.5) + vec2(1, 0.5);
	
	vec2 randomDirection = rand2(vec2(sin(fixedTime * 1.04), cos(fixedTime * 1.03)));
	vec2 direction = mix(vec2(-1, -0.4), randomDirection, 0.3);
	direction = normalize(direction);
	
	vec2 starPos = startingPos + direction * partialTime * 0.1;
	
	vec2 p2 = starPos + direction * 0.1;
	
	float visibility = sin(partialTime * (3.14 / SHOOTING_STAR_PERIOD));
	visibility = pow(visibility, SHOOTING_STAR_EXPONENT);
	
	return visibility * getLineValue(starPos, p2, coord);
}



vec3 sphereNormal(vec3 M, vec3 P) {
	return normalize(P - M);
}

float sSphere(vec3 point, vec3 center, float radius) {
	return length(point - center) - radius;
}



vec3 PLANET_CENTER = vec3(0, 0.4, 5) + iGlobalTime * vec3(0, -0.1, 0);

const float PLANET_RADIUS = 1.2;

const float ATMOSPHERE_SIZE = 0.5;
const float ATMOSPHERE_EXPONENT = 3;

const vec3 ATMOSPHERE_COLOR = vec3(0.3, 0.5, 0.9);

const vec3 LIGHT_POSITION = vec3(2);

const vec3 LIGHT_DIRECTION = vec3(-1, 1, -1);




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

uniform sampler2D tex;

vec3 getOnPlanetColor(vec3 position) {
	
	position = position + vec3(iGlobalTime) * vec3(0.025, 0.017, 0.025);
	
	vec3 relPos = normalize(position - PLANET_CENTER);
	
	float t = fBm(position.xy * 2);
	
	vec2 texC = vec2(abs(position.x), abs(position.y));
	
	vec3 color = vec3(0);
	
	if (t > 0.4) {
		color = vec3(0.1, 0.4, 0.8);
		
	} else if (t > 0.35) {
		color = vec3(1, 0.9, 0.6);
	} else {
		color = vec3(0.6, 0.0, 0.3);
	}
	
	return color * 0.9 + texture(tex, texC).rgb * 0.1;
}


vec4 getPlanetColor(vec2 coord) {
	
	vec3 camP = calcCameraPos();
	vec3 camDir = calcCameraRayDir(80.0, coord, iResolution);

	vec3 point = camP;
	
	int step = 0;
	
	vec3 color = vec3(0);
	
	float closestPlanetHit = 9999;
	
	bool hit = false;
	
	while (step < 100) {
		
		float hitDistance = sSphere(point, PLANET_CENTER, PLANET_RADIUS);
		
		if (hitDistance > 50) break;
		
		closestPlanetHit = min(closestPlanetHit, hitDistance);
		
		if (hitDistance < EPSILON) {
			hit = true;
			
			color = getOnPlanetColor(point);
			
			vec3 hitNormal = sphereNormal(PLANET_CENTER, point);
			
			float lambert = max(dot(hitNormal, LIGHT_DIRECTION), 0.2);
			
			color *= lambert;
			
			break;
		}
		
		point = point + camDir * hitDistance;
		
		step++;
	}
	
	if (hit) return vec4(color, 1.0);
	
	float atmosphereFactor = myReverseSmoothstep2(closestPlanetHit, 0.0, ATMOSPHERE_SIZE);
	
	atmosphereFactor = pow(atmosphereFactor, ATMOSPHERE_EXPONENT);
	
	return vec4(ATMOSPHERE_COLOR, atmosphereFactor);
}


vec3 getTwoColorBackground(vec2 coord, vec3 color1, vec3 color2) {
	float f1 = cos(coord.x + 0.2);
	float f2 = cos(coord.y + 0.1);
	
	//return coord.x < 0.8 ? color1 : color2;
	
	float color1Factor = f1 * 0.5 + f2 * 0.5;
	float color2Factor = 1 - color1Factor;
	
	//return vec3(1);
	
	color1Factor *= 0.55;
	color2Factor *= 0.55;
	
	return color1 * 0.25 + color1 * color1Factor + color2 * 0.25 + color2 * color2Factor;
	//return vec3(0.0, 0.1 + greenFactor, 0.4 + blueFactor) * 0.4;
}


const vec3 BG_COLOR_1 = vec3(0.0, 0.6, 0.4) * 1.0;
const vec3 BG_COLOR_2 = vec3(0.0, 0.2, 0.8) * 1.0;

//const vec3 BG_COLOR_1 = vec3(0.0, 0.6, 0.4);
//const vec3 BG_COLOR_2 = vec3(0.0, 0.2, 0.8);

//const vec3 BG_COLOR_1 = vec3(0.5, 0.15, 0.33);
//const vec3 BG_COLOR_2 = vec3(0.16, 0.38, 0.56);


vec3 getBackgroundColor(vec2 coord) {
	
	float f1 = cos(coord.x + 0.2);
	float f2 = cos(coord.y + 0.1);
	
	float greenFactor = f1 * 0.5 + f2 * 0.5;
	
	float blueFactor = 1 - greenFactor;
	
	greenFactor *= 0.5;
	blueFactor *= 0.5;
	
	//vec3 bgColor = vec3(0.0, 0.1 + greenFactor, 0.4 + blueFactor) * 0.4;
	
	vec3 bgColor = getTwoColorBackground(coord, BG_COLOR_1, BG_COLOR_2) * 0.7;
	
	float myFbm = fBm(coord);
	//myFbm = 0;
	
	return bgColor + vec3(0.8, 0.9, 1) * myFbm * 0.4;
}


// TODO: Sterne (getStarValue) teilweise hinter fBm (dafuer fBm auslagern)

void main() {
	//coordinates in range [0,1]
    vec2 coord = gl_FragCoord.xy/iResolution;
	
	coord.x *= iResolution.x / iResolution.y;
	
	
	
	
	vec3 bgColor = getBackgroundColor(coord);
	
	
	
	float starValue = getStarValue(coord);
	
	float shootingStarValue = getShootingStarValue(coord);
	
	float value = starValue + shootingStarValue;
	
	const vec3 starColor = vec3(0.8, 0.9, 1.0);
	
	//float f1 = cos(pow(coord.x, coord.x * 0.5)) * cos(coord.x);
	//float f2 = sin(coord.y + 0.2);
	
	vec3 color = value * starColor + (1 - value) * bgColor;
	
	vec4 planetColor = getPlanetColor(gl_FragCoord.xy);
	
	float a = planetColor.a;
	
	color = a * planetColor.rgb + (1 - a) * color;
	
    gl_FragColor = vec4(color, 1.0);
}
