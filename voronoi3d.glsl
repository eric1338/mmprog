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



void main() {
	//coordinates in range [0,1]
    vec2 coord = gl_FragCoord.xy/iResolution;
	
	coord.x *= iResolution.x / iResolution.y;
	
	//vec3 color = getVoronoiColor(coord);
	
	
	
	//camera setup
	vec3 camP = calcCameraPos();
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);
	
	vec3 color = vec3(0.1);
	
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
	
	
    gl_FragColor = vec4(color, 1.0);
}
