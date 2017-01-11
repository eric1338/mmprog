#version 330
#include "../libs/camera.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;

const float eps = 0.001;


const float PI = 3.1415926535897932384626433832795;
const float TWOPI = 2 * PI;

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


struct RayHit {
	float dist;
	vec3 color;
};

RayHit getCloserHit(RayHit hit1, RayHit hit2) {
	if (hit1.dist < hit2.dist) return hit1;
	
	return hit2;
}

RayHit getClosestHit(RayHit hit1, RayHit hit2, RayHit hit3, RayHit hit4) {
	RayHit closerHit1 = getCloserHit(hit1, hit2);
	RayHit closerHit2 = getCloserHit(closerHit1, hit3);
	
	return getCloserHit(closerHit2, hit4);
}


float addDistances(float distance1, float distance2) {
	return min(distance1, distance2);
}

float subtractDistances(float distance1, float distance2) {
	return max(distance1, -distance2);
}

float getBoxDistance(vec3 boxCenter, vec3 boxB, vec3 rayPoint) {
	//return length(abs(rayPoint - boxCenter) - boxB);
	return length(max(abs(rayPoint - boxCenter) - boxB, vec3(0)));
}

float vmax(vec3 v) {
	return max(max(v.x, v.y), v.z);
}

float getSubtractBoxDistance(vec3 boxCenter, vec3 boxB, vec3 rayPoint) {
	vec3 d = abs(rayPoint - boxCenter) - boxB;
	return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}



RayHit getBuildingHit(vec3 rayPoint, vec2 buildingCenterXZ) {
	float rand1 = rand(buildingCenterXZ);
	
	int nWindowsY = 6 + int(rand1 * 4);
	int nWindowsZ = 4;
	
	vec3 buildingCenter = vec3(buildingCenterXZ.x, nWindowsY / 10.0, buildingCenterXZ.y);
	vec3 buildingB = vec3(0.2, nWindowsY / 10.0, 0.2);
	
	float blockDistance = getBoxDistance(buildingCenter, buildingB, rayPoint);
	
	// Performance
	if (blockDistance > 0.01) return RayHit(blockDistance, vec3(0));
	
	float facadeDistance = blockDistance;
	
	RayHit closestWindowHit = RayHit(9999.9, vec3(0));
	
	float windowWidth = 0.025;
	float windowHeight = 0.035;
	
	vec3 windowB = vec3(buildingB.x * 0.98, windowHeight, windowWidth);
	vec3 cutoutB = vec3(buildingB.x * 6, windowHeight, windowWidth);
	
	float startY = buildingCenter.y - buildingB.y;
	float stepY = (2 * buildingB.y) / (nWindowsY + 1);
	
	for (int i = 1; i <= nWindowsY; i++) {
		for (int j = -1; j <= 1; j++) {
			float windowCenterY = startY + stepY * i;
			float windowCenterZ = buildingCenter.z + (buildingB.z / 1.7) * j;
			
			vec3 windowCenter = vec3(buildingCenter.x, windowCenterY, windowCenterZ);
			
			float windowCutout = getSubtractBoxDistance(windowCenter, cutoutB, rayPoint);
			facadeDistance = subtractDistances(facadeDistance, windowCutout);
			
			float windowBox = getBoxDistance(windowCenter, windowB, rayPoint);
			
			float rand2 = rand(windowCenter.yz);
			vec3 windowColor = rand2 > 0.5 ? vec3(0.9) : vec3(0.5);
			
			RayHit currentWindowHit = RayHit(windowBox, windowColor);
			
			closestWindowHit = getCloserHit(closestWindowHit, currentWindowHit);
			
			//windowDistance = addDistances(windowDistance, windowBox);
		}
	}
	
	vec3 facadeColor = vec3(0.3, 0.3, 0.4);
	vec3 windowColor = vec3(0.8, 0.9, 1);
	
	RayHit facadeHit = RayHit(facadeDistance, facadeColor);
	//RayHit windowHit = RayHit(windowDistance, windowColor);
	
	return getCloserHit(facadeHit, closestWindowHit);
}


RayHit getBuildingsHit(vec3 rayPoint) {
	float buildingCenterX = 0.55;

	RayHit closestHit = getBuildingHit(rayPoint, vec2(buildingCenterX, -3.2));
	
	for (int i = -3; i <= 4; i++) {
		RayHit nextBuildingHit = getBuildingHit(rayPoint, vec2(buildingCenterX, i * 0.8));
		closestHit = getCloserHit(closestHit, nextBuildingHit);
	}

	return closestHit;
}



RayHit getFloorDistance(vec3 rayPoint) {
	vec3 floorCenter = vec3(0, -0.1, 0);
	vec3 floorB = vec3(4, 0.1, 4);
	
	float floorDistance = getBoxDistance(floorCenter, floorB, rayPoint);
	
	// Performance
	if (floorDistance > 0.01) return RayHit(floorDistance, vec3(0));
	
	vec3 streetB = vec3(4, 0.05, 4);
	
	float streetDistance = getBoxDistance(floorCenter, streetB, rayPoint);
	
	vec3 sidewalkCenter = vec3(0.05, -0.025, 0);
	vec3 sidewalkB = vec3(0.1, 0.025, 4);
	float sidewalkDistance = getBoxDistance(sidewalkCenter, sidewalkB, rayPoint);
	
	vec3 grassCenter = vec3(1, -0.025, 0);
	vec3 grassB = vec3(0.85, 0.025, 4);
	float grassDistance = getBoxDistance(grassCenter, grassB, rayPoint);
	
	
	float stripeLength = 0.04;
	float stripeWidth = 0.006;
	
	float stripeDistance = getBoxDistance(vec3(-100), vec3(1), vec3(1));
	vec3 stripeB = vec3(stripeWidth, 0.001, stripeLength);
	
	for (int i = -10; i <= 10; i++) {
		vec3 stripeCenter = vec3(-0.5, -0.049, i * 0.3);
		float singleStripeDistance = getBoxDistance(stripeCenter, stripeB, rayPoint);
		
		stripeDistance = addDistances(stripeDistance, singleStripeDistance);
	}
	
	
	vec3 streetColor = vec3(0.1);
	vec3 stripeColor = vec3(1);
	vec3 sidewalkColor = vec3(0.2);
	vec3 grassColor = vec3(0.2, 0.4, 0.4);
	
	RayHit streetHit = RayHit(streetDistance, streetColor);
	RayHit stripeHit = RayHit(stripeDistance, stripeColor);
	RayHit sidewalkHit = RayHit(sidewalkDistance, sidewalkColor);
	RayHit grassHit = RayHit(grassDistance, grassColor);
	
	return getClosestHit(streetHit, stripeHit, sidewalkHit, grassHit);
}



RayHit distFuncWithColor(vec3 rayPoint) {
	RayHit floorHit = getFloorDistance(rayPoint);
	
	RayHit buildingHit = getBuildingsHit(rayPoint);
	
	return getCloserHit(floorHit, buildingHit);
}


float distFunc(vec3 rayPoint) {
	RayHit rayHit = distFuncWithColor(rayPoint);

	return rayHit.dist;
}

vec3 getNormal(vec3 point)
{
	float d = 0.00001;
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



vec3 getBackgroundColor(vec2 coord) {
	float value = 0;
	
	const vec3 white = vec3(1);
	
	float f1 = cos(coord.x + 0.2);
	float f2 = cos(coord.y + 0.1);
	
	float greenFactor = f1 * 0.5 + f2 * 0.5;
	
	float blueFactor = 1 - greenFactor;
	
	greenFactor *= 0.5;
	blueFactor *= 0.5;
	
	vec3 bgColor = vec3(0.0, 0.2 + greenFactor, 0.5 + blueFactor) * 0.4;
	
	vec3 color = value * white + (1 - value) * bgColor;

	return color;
}



void main()
{
	//camera setup
	vec3 camP = calcCameraPos();
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);
	
	int maxSteps = 400;
	
	vec3 color = vec3(0);
	
	vec3 point = camP;
	
	int step = 0;
	
	bool hit = false;
	
	float maxDistance = 100;
	float windowGlowHitDistance = 0.15;
	float windowGlowValue = 0;
	
	while (step < maxSteps) {
		
		RayHit rayHit = distFuncWithColor(point);
		float hitDistance = rayHit.dist;
		vec3 hitColor = rayHit.color;
		
		float distanceToCam = distance(camP, point);
		
		if (distanceToCam > maxDistance) break;
		
		if (hitDistance < eps) {
			hit = true;
			
			color = hitColor;
			
			vec3 hitNormal = getNormal(point);
			vec3 toLight = normalize(vec3(-100, 100, -100) - point);
			
			float lambert = max(dot(hitNormal, toLight), 0.2);
			
			
			color *= lambert;
			
			// test
			//if (hitColor.b > 0.9) color = hitColor;
			
			//color *= max((maxDistance - distanceToCam) / maxDistance, 0);
			//color = hitNormal;
			
			break;
		}
		
		point = point + camDir * hitDistance;
	
		step++;
	}
	
	if (!hit) {
		color = getBackgroundColor(camDir.xy);
	}
	
	gl_FragColor = vec4(color, 1.0);
}


