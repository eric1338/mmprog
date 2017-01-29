#version 330

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform vec3 iMouse;

uniform sampler2D tex;

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
	
	return vec3(0, r, b);
	
	//float r = rand(fixedGridPos) * 0.8 + 0.1;
	//float b = rand(fixedGridPos.yx) * 0.8 + 0.1;
	
	//return texture(tex, vec2(r, b)).rgb;
}


vec3 getVoronoiColor(vec2 coord) {
	vec3 color = vec3(0);
	
	float closestDistance = 999;
	
	vec2 coordGridPosition = getGridPosition(coord);
	vec2 coordFixedGridPosition = getFixedGridPosition(coord);
	
	vec2 t = fract(coordGridPosition);
	
	//if (t.x < 0.03 || t.y < 0.03) return vec3(1);
	
	float totalDistance = 0.0;
	
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			
			vec2 currentFixedGridPosition = coordFixedGridPosition + vec2(i, j);
			
			vec2 voronoiPointPosition = getVoronoiPointPosition(currentFixedGridPosition);
			
			float dist = distance(coordGridPosition, voronoiPointPosition);
			
			totalDistance += dist;
		}
	}
	
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			
			vec2 currentFixedGridPosition = coordFixedGridPosition + vec2(i, j);
			
			vec2 voronoiPointPosition = getVoronoiPointPosition(currentFixedGridPosition);
			
			float dist = distance(coordGridPosition, voronoiPointPosition);
			
			//if (dist < 0.03) return vec3(1);
			
			vec3 tempColor = getVoronoiPointColor(currentFixedGridPosition);
			
			float f = (totalDistance - dist) / totalDistance;
			
			f *= 0.05;
			
			color += f * tempColor;
		}
	}
	
	return color;
}


vec3 rgbTest(vec2 coord) {
	vec2 p1 = vec2(0.5, 0.5);
	vec2 p2 = vec2(0.2, 0.2);
	vec2 p3 = vec2(0.2, 0.8);
	vec2 p4 = vec2(0.8, 0.2);
	vec2 p5 = vec2(0.8, 0.8);
	
	float p1Dist = distance(p1, coord);
	float p2Dist = distance(p2, coord);
	float p3Dist = distance(p3, coord);
	float p4Dist = distance(p4, coord);
	float p5Dist = distance(p5, coord);
	
	float minVal = 0.0;
	
	//if (rDist < minVal) rDist = 0;
	//if (gDist < minVal) gDist = 0;
	//if (bDist < minVal) bDist = 0;
	
	float totalDistance = p1Dist + p2Dist + p3Dist + p4Dist + p5Dist;
	
	float p1F = (totalDistance - p1Dist) / totalDistance;
	float p2F = (totalDistance - p2Dist) / totalDistance;
	float p3F = (totalDistance - p3Dist) / totalDistance;
	float p4F = (totalDistance - p4Dist) / totalDistance;
	float p5F = (totalDistance - p5Dist) / totalDistance;
	
	vec3 cl = vec3(0);
	
	//cl += rF * vec3(1, 0, 1);
	//cl += gF * vec3(0, 1, 1);
	//cl += bF * vec3(0, 0, 1);
	
	cl += p1F * texture(tex, p1).rgb;
	cl += p2F * texture(tex, p2).rgb;
	cl += p3F * texture(tex, p3).rgb;
	cl += p4F * texture(tex, p4).rgb;
	cl += p5F * texture(tex, p5).rgb;
	
	//coord = floor(coord * vec2(10)) / vec2(10);
	
	coord = coord + rand2(coord) * 0.009;
	
	cl = texture(tex, coord).rgb;
	
	return cl;
}



void main() {
	//coordinates in range [0,1]
    vec2 coord = gl_FragCoord.xy/iResolution;
	
	coord.x *= iResolution.x / iResolution.y;
	
	//vec3 color = texture(tex, coord).rgb;
	//vec3 color = getVoronoiColor(coord);
	vec3 color = rgbTest(coord);
	
    gl_FragColor = vec4(color, 1.0);
}
