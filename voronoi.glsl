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



float nX = 10;
float nY = 10;

vec2 getGridPosition(vec2 coord) {
	return coord * vec2(nX, nY);
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
	
	vec2 timeOffset = vec2(sin(iGlobalTime * r1)) * r2 * 0;
	
	return fixedGridPos + fixedOffset * 0.9 + timeOffset;
}

vec3 getVoronoiPointColor(vec2 fixedGridPos) {
	vec2 color2 = rand2(fixedGridPos);
	
	float r = rand(fixedGridPos) * 0.5 + 0.5;
	float b = rand(fixedGridPos.yx) * 0.5 + 0.5;
	
	return vec3(r, 0, b);
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



void main() {
	//coordinates in range [0,1]
    vec2 coord = gl_FragCoord.xy/iResolution;
	
	coord.x *= iResolution.x / iResolution.y;
	
	vec3 color = getVoronoiColor(coord);
	
    gl_FragColor = vec4(color, 1.0);
}
