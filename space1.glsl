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


float nBoxes = 60;
float rnThreshold = 0.25;

float getRN(vec2 coord) {
	return rand(floor(coord * nBoxes));
}

float getShininess(vec2 coord) {
	float rn = getRN(coord);
	
	float pr = rn * 6.28 + iGlobalTime;
	
	return pow(max(sin(pr), 0.0), 8);
}

float gV2(vec2 coord) {
	
	vec2 grid = coord * nBoxes;
	vec2 flgrid = floor(grid);
	vec2 middle = flgrid + vec2(0.5);
	
	float rn = getRN(coord);
	
	if (rand(rn) < rnThreshold) return 0;
	
	vec2 offset = rand2(flgrid) - vec2(0.5);
	
	vec2 starPos = middle + offset * 0.4;
	
	float shininess = getShininess(coord + vec2(1));
	
	float dist = 1 - distance(grid, starPos) * (9 - 5 * rn - shininess * 3);
	
	return pow(max(dist, 0.0), 12 - 2 * shininess);
}

void main() {
	//coordinates in range [0,1]
    vec2 coord = gl_FragCoord.xy/iResolution;
	
	coord.x *= iResolution.x / iResolution.y;

	float value = gV2(coord);
	
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
