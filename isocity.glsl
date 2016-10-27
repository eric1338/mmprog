#version 330
#include "../raymarching/libs/camera.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;

const float eps = 0.001;





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
	vec3 buildingCenter = vec3(0, 0, 2);
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

float distFunc(vec3 rayPoint) {
	return min(getBuildingFacadeDistance(rayPoint), getWindowDistance(rayPoint));
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
	
	float maxDistance = 40;
	float windowGlowHitDistance = 0.15;
	float windowGlowValue = 0;
	
	while (step < maxSteps) {
	
		float buildingFacadeDistance = getBuildingFacadeDistance(point);
		float windowDistance = getWindowDistance(point);
		
		float distanceToCam = distance(camP, point);
		
		if (distanceToCam > maxDistance) break;
		
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
		
		if (buildingFacadeDistance < eps) {
			hit = true;
			
			vec3 hitNormal = getNormal(point);
			vec3 toLight = normalize(vec3(-10, 10, -10) - point);
			
			float lambert = max(dot(hitNormal, toLight), 0.2);
		
			color = vec3(0.2);
			color *= lambert;
			//color *= max((maxDistance - distanceToCam) / maxDistance, 0);
			//color = hitNormal;
			
			//color = vec3(lambert);
			
			break;
		}
		
		point = point + camDir * min(windowDistance, buildingFacadeDistance);
	
		step++;
	}
	
	if (!hit) {
		vec2 xyRel = gl_FragCoord.xy / iResolution;
		float g = 1 - (xyRel.x * 0.4 + xyRel.y * 0.4);
		color = vec3(0.0, 0.2 + g, 0.9) * 0.1;
		
		color = vec3(0);
	}
	
	color += vec3(1, 0.9, 0) * windowGlowValue;
	
	gl_FragColor = vec4(color, 1.0);
}


