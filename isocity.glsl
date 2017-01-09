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

float getBuildingFacadeDistance(vec3 rayPoint) {
	vec3 buildingCenter = vec3(0, 2, 2);
	vec3 buildingB = vec3(2, 3, 1);
	
	float blockDistance = getBoxDistance(buildingCenter, buildingB, rayPoint);

	float windowBlockDistance = getSubtractBoxDistance(vec3(0, 0, 1), vec3(0.6, 0.9, 1), rayPoint);
	
	float facadeDistance = subtractDistances(blockDistance, windowBlockDistance);
	
	//return blockDistance;
	return facadeDistance;
}

float getWindowDistance(vec3 rayPoint) {
	return getBoxDistance(vec3(0, 0, 1.2), vec3(0.6, 0.9, 0.1), rayPoint);
}




RayHit getBuildingFacadeDistance2(vec3 rayPoint) {
	vec3 buildingCenter = vec3(0, 2, 2);
	vec3 buildingB = vec3(2, 3, 1);
	
	float blockDistance = getBoxDistance(buildingCenter, buildingB, rayPoint);

	float windowBlockDistance = getSubtractBoxDistance(vec3(0, 2, 1), vec3(0.6, 0.9, 1), rayPoint);
	
	float facadeDistance = subtractDistances(blockDistance, windowBlockDistance);
	
	return RayHit(facadeDistance, vec3(0, 0.5, 1));
}


RayHit getWindowDistance2(vec3 rayPoint) {
	float windowDistance = getBoxDistance(vec3(0, 2, 1.2), vec3(0.6, 0.9, 0.1), rayPoint);
	
	return RayHit(windowDistance, vec3(1, 0.9, 0));
}

RayHit getBuildingDistance2(vec3 rayPoint) {
	RayHit facadeHit = getBuildingFacadeDistance2(rayPoint);
	RayHit windowHit = getWindowDistance2(rayPoint);
	
	return getCloserHit(facadeHit, windowHit);
}




RayHit getBuildingHit(vec3 rayPoint, vec3 buildingCenter) {
	float rand1 = rand(buildingCenter.xy * buildingCenter.z);
	float rand2 = rand(buildingCenter.zx * buildingCenter.y);
	
	int nWindowsY = 3 + int(rand1 * 4);
	
	vec3 buildingB = vec3(2, nWindowsY, 2);
	
	float blockDistance = getBoxDistance(buildingCenter, buildingB, rayPoint);
	
	// Performance
	if (blockDistance > 0.1) return RayHit(blockDistance, vec3(0));
	
	float facadeDistance = blockDistance;
	
	float windowDistance = getBoxDistance(vec3(-100), vec3(1), vec3(1));
	float windowWidth = 0.25;
	float windowHeight = 0.35;
	
	vec3 windowB = vec3(buildingB.x * 0.98, windowHeight, windowWidth);
	vec3 cutoutB = vec3(buildingB.x * 6, windowHeight, windowWidth);
	
	float startY = buildingCenter.y - buildingB.y;
	float stepY = (2 * buildingB.y) / (nWindowsY + 1);
	
	for (int i = 1; i <= nWindowsY; i++) {
		for (int j = -1; j <= 1; j++) {
			//float windowCenterY = buildingCenter.y + (buildingB.y / 1.7) * i;
			float windowCenterY = startY + stepY * i;
			float windowCenterZ = buildingCenter.z + (buildingB.z / 1.7) * j;
			
			vec3 windowCenter = vec3(buildingCenter.x, windowCenterY, windowCenterZ);
			
			float windowCutout = getSubtractBoxDistance(windowCenter, cutoutB, rayPoint);
			facadeDistance = subtractDistances(facadeDistance, windowCutout);
			
			float windowBox = getBoxDistance(windowCenter, windowB, rayPoint);
			windowDistance = addDistances(windowDistance, windowBox);
		}
	}
	
	vec3 facadeColor = vec3(0.3, 0.3, 0.4);
	vec3 windowColor = vec3(0.8, 0.9, 1);
	
	RayHit facadeHit = RayHit(facadeDistance, facadeColor);
	RayHit windowHit = RayHit(windowDistance, windowColor);
	
	return getCloserHit(facadeHit, windowHit);
}


RayHit getBuildingsHit(vec3 rayPoint) {
	float buildingCenterX = 5.5;
	float buildingCenterY = 7;

	RayHit closestHit = getBuildingHit(rayPoint, vec3(buildingCenterX, buildingCenterY, -32));
	
	for (int i = -3; i <= 4; i++) {
		RayHit nextBuildingHit = getBuildingHit(rayPoint, vec3(buildingCenterX, buildingCenterY, i * 8));
		closestHit = getCloserHit(closestHit, nextBuildingHit);
	}

	return closestHit;
}



RayHit getFloorDistance(vec3 rayPoint) {
	vec3 floorCenter = vec3(0, -1, 0);
	vec3 floorB = vec3(40, 1, 40);
	
	float floorDistance = getBoxDistance(floorCenter, floorB, rayPoint);
	
	// Performance
	if (floorDistance > 0.1) return RayHit(floorDistance, vec3(0));
	
	vec3 streetB = vec3(40, 0.5, 40);
	
	float streetDistance = getBoxDistance(floorCenter, streetB, rayPoint);
	
	vec3 sidewalkCenter = vec3(0.5, -0.25, 0);
	vec3 sidewalkB = vec3(1, 0.25, 40);
	float sidewalkDistance = getBoxDistance(sidewalkCenter, sidewalkB, rayPoint);
	
	vec3 grassCenter = vec3(10, -0.25, 0);
	vec3 grassB = vec3(8.5, 0.25, 40);
	float grassDistance = getBoxDistance(grassCenter, grassB, rayPoint);
	
	
	float stripeLength = 0.4;
	float stripeWidth = 0.06;
	
	float stripeDistance = getBoxDistance(vec3(-100), vec3(1), vec3(1));
	vec3 stripeB = vec3(stripeWidth, 0.01, stripeLength);
	
	for (int i = -10; i <= 10; i++) {
		vec3 stripeCenter = vec3(-5, -0.49, i * 3);
		float singleStripeDistance = getBoxDistance(stripeCenter, stripeB, rayPoint);
		
		stripeDistance = addDistances(stripeDistance, singleStripeDistance);
	}
	
	
	vec3 streetColor = vec3(0.1);
	vec3 stripeColor = vec3(1);
	vec3 sidewalkColor = vec3(0.2);
	vec3 grassColor = vec3(0.2, 0.5, 0.2);
	
	RayHit streetHit = RayHit(streetDistance, streetColor);
	RayHit stripeHit = RayHit(stripeDistance, stripeColor);
	RayHit sidewalkHit = RayHit(sidewalkDistance, sidewalkColor);
	RayHit grassHit = RayHit(grassDistance, grassColor);
	
	return getClosestHit(streetHit, stripeHit, sidewalkHit, grassHit);
}



RayHit distFuncWithColor(vec3 rayPoint) {
	RayHit floorHit = getFloorDistance(rayPoint);
	
	RayHit buildingHit = getBuildingsHit(rayPoint);
	
	//return getCloserHit(floorHit, buildingHit);
	return getCloserHit(floorHit, buildingHit);
}


float distFunc(vec3 rayPoint) {
	RayHit rayHit = distFuncWithColor(rayPoint);

	return rayHit.dist;
	
	//return min(getBuildingFacadeDistance(rayPoint), getWindowDistance(rayPoint));
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



void main()
{
	//camera setup
	vec3 camP = calcCameraPos();
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);
	
	int maxSteps = 100;
	
	vec3 color = vec3(0);
	
	vec3 point = camP;
	
	int step = 0;
	
	bool hit = false;
	
	float maxDistance = 100;
	float windowGlowHitDistance = 0.15;
	float windowGlowValue = 0;
	
	while (step < maxSteps) {
	
		//float buildingFacadeDistance = getBuildingFacadeDistance(point);
		float windowDistance = getWindowDistance(point);
		
		RayHit rayHit = distFuncWithColor(point);
		float hitDistance = rayHit.dist;
		vec3 hitColor = rayHit.color;
		
		float distanceToCam = distance(camP, point);
		
		if (distanceToCam > maxDistance) break;
		
		/*
		if (windowDistance < windowGlowHitDistance) {
			if (distanceToCam <= maxDistance) {
				windowGlowValue += pow((windowGlowHitDistance - windowDistance), 0.1) * max(0, maxDistance - distanceToCam) * 0.002;
			}
		}
		
		if (windowDistance < eps) {
			hit = true;
			
			color = vec3(1, 0.9, 0);
			
			break;
		}
		*/
		
		
		
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
			
			//color = vec3(lambert);
			
			break;
		}
		
		//point = point + camDir * min(windowDistance, buildingFacadeDistance);
		point = point + camDir * hitDistance;
	
		step++;
	}
	
	if (!hit) {
		//vec2 xyRel = gl_FragCoord.xy / iResolution;
		//float g = 1 - (xyRel.x * 0.4 + xyRel.y * 0.4);
		//color = vec3(0.0, 0.2 + g, 0.9) * 0.1;
		
		color = vec3(0);
		//color = vec3(0.4, 0.5, 1);
	}
	
	//color += vec3(1, 0.9, 0) * windowGlowValue;
	
	gl_FragColor = vec4(color, 1.0);
}


