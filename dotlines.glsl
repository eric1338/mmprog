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


const vec2 CENTER = vec2(0.5);
const float CIRCLE_MIN = 0.3;
const float CIRCLE_MAX = 0.45;

bool isInCircle(vec2 coord) {
	float dist = distance(CENTER, coord);
	
	return dist >= CIRCLE_MIN && dist <= CIRCLE_MAX;
}




float drawLine(vec2 pointA, vec2 pointB, vec2 coord) {
	float thickness = 0.0003;
	
	float sideA = length(coord - pointB);
	float sideB = length(pointA - coord);
	float sideC = length(pointB - pointA);
	
	if (sideA >= sideC || sideB >= sideC) {
		return mix(1.0, 0.0, smoothstep(0.1 * thickness, 2 * thickness, sideA * 0.5));
	
		//return 0.0;
	}
	
	float s = (sideA + sideB + sideC) / 2.0;
	
	float area = sqrt(s * (s - sideA) * (s - sideB) * (s - sideC));
	
	float height = area / sideC;
	
	return mix(1.0, 0.0, smoothstep(0.1 * thickness, 2 * thickness, height));
	
	//if (height < 0.002) return (0.002 - height) * 500;
	
	//return 0;
}


float numberOfPoints = 10.0;


float getMusicFactor() {
	float x = mod(iGlobalTime, 4);
	
	float p1 = 0.1;
	float p2 = 3.9;
	
	return x < p1 ? x * (1 / p1) : max((p2 - (x - p1)) / p2, 0);
}






float getMusicLineValue(vec2 coord) {
	if (!isInCircle(coord)) return 0;
	
	vec2 twelve = normalize(vec2(0.0, 1.0) - CENTER);
	vec2 curr = normalize(coord - CENTER);
	
	float x = dot(twelve, curr) * 0.5 + 0.5;
	
	float ln = length(coord - CENTER) - CIRCLE_MIN;
	
	return ln / (CIRCLE_MAX - CIRCLE_MIN);
}


vec2 getPointCenter(float index) {
	float randSpeed = 0.3 * (rand(index) - 0.5);
	
	float angle = (TWOPI / numberOfPoints) * index + iGlobalTime * randSpeed;
	
	vec2 center = vec2(cos(angle), sin(angle)) * 0.4;
	
	vec2 randSeed = vec2(cos(index), sin(index));
	vec2 offset = rand2(randSeed) * 0.004;
	
	//vec2 offset = vec2(0);
	
	float f = min(iGlobalTime * 0.5, 1);
	
	float musicF = getMusicFactor() * 0.1 + 0.9;
	
	return vec2(0.5) + center * f * musicF + offset * f;
}


float getPointValue(vec2 coord, float index) {
	vec2 center = getPointCenter(index);
	float dist = distance(coord, center);
	
	float thickness = 0.0005;
	
	//return mix(1.0, 0.0, dist * 2);
	
	return mix(1.0, 0.0, smoothstep(0.1 * thickness, 2 * thickness, dist * 0.5));
}


float getPointsValue(vec2 coord) {
	if (!isInCircle(coord)) return 0;
	
	float step = TWOPI / 20.0;
	
	float val = 0.1;
	
	for (float i = 0; i < numberOfPoints; i++) {
		val = max(val, getPointValue(coord, i));
	}
	
	return val;
}


vec2 getRandomPoint(float seed) {
	float randomIndex = floor(rand(seed) * numberOfPoints);
	
	return getPointCenter(randomIndex);
}

float getRandomLineValue(vec2 coord, float seed) {
	float randSeed = rand(seed);
	
	float lineVal = 0;
	
	bool pointFound = false;
	int tries = 0;
	
	vec2 p1 = getRandomPoint(seed);
	
	while (!pointFound && tries++ < 20) {
		randSeed = rand(randSeed);
		
		vec2 p2 = getRandomPoint(randSeed);
		
		if (distance(p1, p2) < 0.25) {
			pointFound = true;
			lineVal = drawLine(p1, p2, coord);
		}
	}
	
	return lineVal;
}

/*


float getRandomLineValue(vec2 coord, float seed) {
	float randVal = rand(seed);
	
	bool lineThroughCenter = true;
	
	float lineVal = 0;
	
	int tries = 0;
	
	while (lineThroughCenter && tries++ < 10) {
		vec2 p1 = getRandomPoint(seed);
		vec2 p2 = getRandomPoint(seed + 1);
		
		vec2 middle = p1 + 0.5 * (p2 - p1);
		
		if (distance(middle, vec2(0.5)) > 0.2) {
			lineThroughCenter = false;
			lineVal = drawLine(p1, p2, coord);
		} else {
			randVal = rand(randVal);
		} 
	}
	
	return lineVal;
}


*/



float getLinesValue(vec2 coord) {
	if (iGlobalTime < 2) return 0.0;
	
	return 0.0;
	
	float val = 0;
	
	for (int i = 0; i < 4; i++) {
		float randSeed = floor((iGlobalTime + i * 5) * 20);
		
		float lineVal = getRandomLineValue(coord, randSeed);
		
		val = max(val, lineVal);
	}
	
	return val;
	
	/*
	float randVal1 = rand(randSeed);
	float randVal2 = rand(randVal1);
	
	float index1 = floor(randVal1 * (numberOfPoints - 5));
	float index2 = floor(randVal2 * 5);
	
	vec2 pointA = getPointCenter(index1);
	vec2 pointB = getPointCenter(index2);
	
	return drawLine(pointA, pointB, coord);
	*/
}

float getLinesValue2(vec2 coord) {
	float lineVal = 0;
	
	for (int i = 0; i < numberOfPoints; i++) {
		vec2 p1 = getPointCenter(i);
		
		for (int j = i + 1; j < numberOfPoints; j++) {
			if (i == j) continue;
			
			vec2 p2 = getPointCenter(j);
			
			if (distance(p1, p2) < 0.2) {
				lineVal = max(lineVal, drawLine(p1, p2, coord));
			}
		}
	}
	
	return lineVal;
}



void main() {
	//coordinates in range [0,1]
    vec2 coord = gl_FragCoord.xy/iResolution;
	
	coord.x *= iResolution.x / iResolution.y;
	
	vec3 color = vec3(getLinesValue(coord));
	
	//color += vec3(getPointsValue(coord));
	color += vec3(getMusicLineValue(coord));
	
    gl_FragColor = vec4(color, 1.0);
}
