///idea from http://thebookofshaders.com/edit.php#09/marching_dots.frag
#version 330

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform vec3 iMouse;

const float PI = 3.1415926535897932384626433832795;
const float TWOPI = 2 * PI;
const float EPSILON = 10e-4;

float rand(float seed)
{
	return fract(sin(seed) * 1231534.9);
}

float rand(vec2 seed) { 
    return rand(dot(seed, vec2(12.9898, 783.233)));
}

//random vector with length 1
vec2 rand2(vec2 seed)
{
	float r = rand(seed) * TWOPI;
	return vec2(cos(r), sin(r));
}


float nRows = 25;
float visibilityThreshold = 0.85;

float getShininess(vec2 coord) {
	float rn = rand(coord);
	
	float pr = rn * 6.28 + iGlobalTime * 0.2;
	
	return pow(max(sin(pr), 0.0), 128);
}

float getStarValue(vec2 coord) {
	
	vec2 posInGrid = coord * nRows;
	vec2 fixedGridPos = floor(posInGrid);
	vec2 middle = fixedGridPos + vec2(0.5);
	
	float randomValue = rand(fixedGridPos);
	
	if (rand(randomValue) < visibilityThreshold) return 0;
	
	vec2 offset = rand2(fixedGridPos) - vec2(0.5);
	
	vec2 starPos = middle + offset * 0.1;
	
	float shininess = getShininess(fixedGridPos + vec2(1.337));
	float size = shininess * 3;
	
	float distanceFactor = (9 - 5 * randomValue - size);
	
	float dist = 1 - distance(posInGrid, starPos) * distanceFactor;
	
	return pow(max(dist, 0.0), 12 - 2 * shininess);
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
