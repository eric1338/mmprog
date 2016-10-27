#version 330
#include "../raymarching/libs/camera.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;

const float eps = 0.001;




float getSphereDistance(vec3 sphereCenter, float sphereRadius, vec3 rayPoint) {
	return max(0, distance(rayPoint, sphereCenter) - sphereRadius);
}

float getStarDistance(vec3 rayPoint) {
	vec3 modVector = vec3(5, 5, 5);
	vec3 modPoint = mod(rayPoint, modVector) - 0.5 * modVector;
	
	return getSphereDistance(vec3(0), 0.1, modPoint);
}

float getPlanetDistance(vec3 rayPoint) {
	float p1Dist = getSphereDistance(vec3(0, -1, 2), 1, rayPoint);
	float p2Dist = getSphereDistance(vec3(2, 1, 4), 1, rayPoint);
	float p3Dist = getSphereDistance(vec3(-2, 0, 6), 1, rayPoint);
	
	return min(min(p1Dist, p2Dist), p3Dist);
}

float distFunc(vec3 rayPoint) {
	return min(getStarDistance(rayPoint), getPlanetDistance(rayPoint));
}


float distFuncSphere(vec3 p) {
	//vec3 m = vec3(0, 0, 0);
	
	float r = 0.45;
	
	//float xStep = 5;
	//float yStep = 5;
	//float zStep = 5;
	
	//float rx = floor(p.x / xStep) + 0.5 * xStep;
	//float ry = floor(p.y / yStep) + 0.5 * yStep;
	//float rz = floor(p.z / zStep) + 0.5 * zStep;
	//float randVal = tan(rx * 7) + sin(ry * 0.5) + cos(rz + 400);
	
	//randVal *= 0.2;
	
	//randVal = 0.0;
	
	//vec3 m = vec3(sin(randVal), sin(randVal), sin(randVal));

	
	
	float rx = floor((p.x + 2.5) / 5.0);
	
	rx = (p.x + 2.5) / 5.0;
	
	float ry = floor((p.y + 2.5) / 5.0);
	float rz = floor((p.z + 2.5) / 5.0);
	//float randVal = tan(rx * 7) + sin(ry * 0.5) + cos(rz + 400);
	
	//vec3 rvec = vec3(sin(rx), sin(ry), sin(rz));
	vec3 rvec = vec3(sin(rx), 0, 0);
	rvec *= 0.3;
	
	vec3 m = rvec;
	
	//vec3 m = vec3(sin(randVal), sin(randVal), sin(randVal));
	
	//vec3 modVec = vec3(xStep, yStep, zStep);
	vec3 modVec = vec3(5, 5, 5);
	vec3 modPoint = mod(p, modVec) - 0.5 * modVec;
	
	
	
	m = vec3(0, 0, 0);
	
	//vec3 test = p / modVec - 0.5 * modVec;
	
	//int xtest = int(floor(mod(test.x, 2)));
	
	//if (xtest == 0) return 999;
	
	//float randVal = tan(p.x) * 7;
	//randVal *= -sin(p.y * 3.1);
	//randVal *= cos(p.z * 0.5) + 3;
	
	
	//float tz = p.z;
	//float x = int(floor(tz / zStep));
	
	//if (mod(x, 3) == 1) return 999;
	
	
	//vec3 randVec = p * tan(p.x) * 7;
	//randVec *= -sin(p.y * 3.1);
	//randVec *= cos(p.z * 0.5) + 3;
	
	//if (sin(randVal) < 0.4) return 9;
	
	return max(0, distance(modPoint, m) - r);
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
	float starGlowHitDistance = 0.1;
	float planetGlowHitDistance = 0.1;
	float starGlowValue = 0;
	float planetGlowValue = 0;
	
	while (step < maxSteps) {
	
		float starDistance = getStarDistance(point);
		float planetDistance = getPlanetDistance(point);
		
		float distanceToCam = distance(camP, point);
		
		if (distanceToCam > maxDistance) break;
		
		if (starDistance < starGlowHitDistance) {
			if (distanceToCam <= maxDistance) {
				starGlowValue += pow((starGlowHitDistance - starDistance), 0.1) * max(0, maxDistance - distanceToCam) * 0.002;
			}
		}
		if (planetDistance < planetGlowHitDistance) {
			if (distanceToCam <= maxDistance) {
				planetGlowValue += pow((planetGlowHitDistance - planetDistance), 0.1) * max(0, maxDistance - distanceToCam) * 0.002;
			}
		}
		
		if (starDistance < eps) {
			hit = true;
			
			color = vec3(1);
			
			break;
		}
		
		if (planetDistance < eps) {
			hit = true;
			
			vec3 hitNormal = getNormal(point);
			vec3 toLight = normalize(vec3(-10, 10, -10) - point);
			
			float lambert = max(dot(hitNormal, toLight), 0.2);
		
			color = vec3(0, 0.8, 1);
			color *= lambert;
			//color *= max((maxDistance - distanceToCam) / maxDistance, 0);
			//color = hitNormal;
			
			//color = vec3(lambert);
			
			break;
		}
		
		point = point + camDir * min(starDistance, planetDistance);
	
		step++;
	}
	
	if (!hit) {
		vec2 xyRel = gl_FragCoord.xy / iResolution;
		float g = 1 - (xyRel.x * 0.4 + xyRel.y * 0.4);
		color = vec3(0.0, 0.2 + g, 0.9) * 0.1;
		
		color = vec3(0);
	}
	
	color += vec3(starGlowValue);
	color += vec3(0, 0.8, 1) * planetGlowValue;
	
	gl_FragColor = vec4(color, 1.0);
}


