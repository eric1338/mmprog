
struct LightedColor {
	vec3 color;
	float lightFactor;
};

struct RayResult {
	float dist;
	vec3 color;
	float lightFactor;
};

RayResult NoLightRayResult(float dist, vec3 color) {
	return RayResult(dist, color, 0.0);
}

RayResult NoHitRayResult(float dist) {
	return RayResult(dist, vec3(0, 0, 1), 0.0);
}


RayResult getCloserRayResult(RayResult result1, RayResult result2) {
	if (result1.dist < result2.dist) return result1;
	
	return result2;
}

RayResult getClosestRayResult(RayResult rayResult1, RayResult rayResult2, RayResult rayResult3, RayResult rayResult4) {
	RayResult closerResult1 = getCloserRayResult(rayResult1, rayResult2);
	RayResult closerResult2 = getCloserRayResult(rayResult3, rayResult4);
	
	return getCloserRayResult(closerResult1, closerResult2);
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

