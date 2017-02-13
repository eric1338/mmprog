#version 330

#include "mylib.glsl"
#include "../libs/camera.glsl"


uniform vec2 iResolution;
uniform float iGlobalTime;

const float EPSILON = 0.001;

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


const float FOG_START = 10;
const float FOG_END = 40;

float getFogFactor(float distance) {
	if (distance < FOG_START) return 1;
	if (distance > FOG_END) return 0;
	
	return (FOG_END - distance) / (FOG_END - FOG_START);
}


const float STREET_WIDTH = 1.0;
const float SIDEWALK_WIDTH = 0.2;
const float CORNER_WIDTH = 4.0;

const float SIDEWALK_DEPTH = 0.01;
const float CORNER_DEPTH = 0.0;
const float STREET_DEPTH = 0.03;

const vec3 CENTER = vec3(0.0);

const float FLOOR_BLOCK_HEIGHT = 0.05;


const float ROWS_PER_TILE = 7;
const float REL_BUILDING_WIDTH = 0.8;
const float MIN_MARGIN_TO_SIDEWALK = 0.05;


const vec3 STREET_COLOR = vec3(0.1);
const vec3 STRIPE_COLOR = vec3(1);
const vec3 SIDEWALK_COLOR = vec3(0.2);
const vec3 CORNER_COLOR = vec3(0.2, 0.4, 0.4);

const vec3 BUILDING_COLOR = vec3(0.2);
const vec3 WINDOW_ON_COLOR = vec3(0.9);
const vec3 WINDOW_OFF_COLOR = vec3(0.25);


const float HALF_STREET_WIDTH = STREET_WIDTH / 2.0;
const float HALF_SIDEWALK_WIDTH = SIDEWALK_WIDTH / 2.0;
const float HALF_CORNER_WIDTH = CORNER_WIDTH / 2.0;
const float HALF_WHOLE_CORNER_WIDTH = (SIDEWALK_WIDTH + CORNER_WIDTH) / 2.0;
const float HALF_FLOOR_BLOCK_HEIGHT = FLOOR_BLOCK_HEIGHT / 2.0;


float getTileWidth() {
	return STREET_WIDTH + 2 * SIDEWALK_WIDTH + 2 * CORNER_WIDTH;
}

float getHalfTileWidth() {
	return getTileWidth() / 2.0;
}



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
	return RayResult(dist, vec3(0), 0.0);
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




RayResult getStreetResult(vec3 rayPoint) {
	vec3 streetCenter = vec3(CENTER.x, CENTER.y - STREET_DEPTH - HALF_FLOOR_BLOCK_HEIGHT, CENTER.z);
	vec3 streetB = vec3(getHalfTileWidth(), HALF_FLOOR_BLOCK_HEIGHT, getHalfTileWidth());
	
	float streetDistance = getBoxDistance(streetCenter, streetB, rayPoint);

	return NoLightRayResult(streetDistance, STREET_COLOR);
}


RayResult getSidewalkResult(vec3 rayPoint) {
	float closeCenterOffset = HALF_STREET_WIDTH + HALF_SIDEWALK_WIDTH;
	float farCenterOffset = HALF_STREET_WIDTH + HALF_WHOLE_CORNER_WIDTH;
	float veryFarCenterOffset = HALF_STREET_WIDTH + SIDEWALK_WIDTH + HALF_CORNER_WIDTH;
	
	float sidewalkCenterY = CENTER.y - SIDEWALK_DEPTH - HALF_FLOOR_BLOCK_HEIGHT;
	
	vec3 sidewalk1Center = vec3(CENTER.x - closeCenterOffset, sidewalkCenterY, CENTER.z - veryFarCenterOffset);
	vec3 sidewalk2Center = vec3(CENTER.x - closeCenterOffset, sidewalkCenterY, CENTER.z + veryFarCenterOffset);
	vec3 sidewalk3Center = vec3(CENTER.x + closeCenterOffset, sidewalkCenterY, CENTER.z - veryFarCenterOffset);
	vec3 sidewalk4Center = vec3(CENTER.x + closeCenterOffset, sidewalkCenterY, CENTER.z + veryFarCenterOffset);
	vec3 sidewalk5Center = vec3(CENTER.x - farCenterOffset, sidewalkCenterY, CENTER.z - closeCenterOffset);
	vec3 sidewalk6Center = vec3(CENTER.x - farCenterOffset, sidewalkCenterY, CENTER.z + closeCenterOffset);
	vec3 sidewalk7Center = vec3(CENTER.x + farCenterOffset, sidewalkCenterY, CENTER.z - closeCenterOffset);
	vec3 sidewalk8Center = vec3(CENTER.x + farCenterOffset, sidewalkCenterY, CENTER.z + closeCenterOffset);
	
	vec3 horizontalSidewalkB = vec3(HALF_SIDEWALK_WIDTH, HALF_FLOOR_BLOCK_HEIGHT, HALF_CORNER_WIDTH);
	vec3 verticalSidewalkB = vec3(HALF_WHOLE_CORNER_WIDTH, HALF_FLOOR_BLOCK_HEIGHT, HALF_SIDEWALK_WIDTH);
	
	float sidewalk1Distance = getBoxDistance(sidewalk1Center, horizontalSidewalkB, rayPoint);
	float sidewalk2Distance = getBoxDistance(sidewalk2Center, horizontalSidewalkB, rayPoint);
	float sidewalk3Distance = getBoxDistance(sidewalk3Center, horizontalSidewalkB, rayPoint);
	float sidewalk4Distance = getBoxDistance(sidewalk4Center, horizontalSidewalkB, rayPoint);
	float sidewalk5Distance = getBoxDistance(sidewalk5Center, verticalSidewalkB, rayPoint);
	float sidewalk6Distance = getBoxDistance(sidewalk6Center, verticalSidewalkB, rayPoint);
	float sidewalk7Distance = getBoxDistance(sidewalk7Center, verticalSidewalkB, rayPoint);
	float sidewalk8Distance = getBoxDistance(sidewalk8Center, verticalSidewalkB, rayPoint);
	
	float sidewalkDistance = addDistances(sidewalk1Distance, sidewalk2Distance);
	sidewalkDistance = addDistances(sidewalkDistance, sidewalk3Distance);
	sidewalkDistance = addDistances(sidewalkDistance, sidewalk4Distance);
	sidewalkDistance = addDistances(sidewalkDistance, sidewalk5Distance);
	sidewalkDistance = addDistances(sidewalkDistance, sidewalk6Distance);
	sidewalkDistance = addDistances(sidewalkDistance, sidewalk7Distance);
	sidewalkDistance = addDistances(sidewalkDistance, sidewalk8Distance);
	
	return NoLightRayResult(sidewalkDistance, SIDEWALK_COLOR);
}


RayResult getCornerResult(vec3 rayPoint) {
	float centerOffset = HALF_STREET_WIDTH + SIDEWALK_WIDTH + HALF_CORNER_WIDTH;
	
	float cornerCenterY = CENTER.y - CORNER_DEPTH - HALF_FLOOR_BLOCK_HEIGHT;
	
	vec3 corner1Center = vec3(CENTER.x - centerOffset, cornerCenterY, CENTER.z - centerOffset);
	vec3 corner2Center = vec3(CENTER.x - centerOffset, cornerCenterY, CENTER.z + centerOffset);
	vec3 corner3Center = vec3(CENTER.x + centerOffset, cornerCenterY, CENTER.z - centerOffset);
	vec3 corner4Center = vec3(CENTER.x + centerOffset, cornerCenterY, CENTER.z + centerOffset);
	
	vec3 cornerB = vec3(HALF_CORNER_WIDTH, HALF_FLOOR_BLOCK_HEIGHT, HALF_CORNER_WIDTH);
	
	float corner1Distance = getBoxDistance(corner1Center, cornerB, rayPoint);
	float corner2Distance = getBoxDistance(corner2Center, cornerB, rayPoint);
	float corner3Distance = getBoxDistance(corner3Center, cornerB, rayPoint);
	float corner4Distance = getBoxDistance(corner4Center, cornerB, rayPoint);
	
	float cornerDistance = addDistances(corner1Distance, corner2Distance);
	cornerDistance = addDistances(cornerDistance, corner3Distance);
	cornerDistance = addDistances(cornerDistance, corner4Distance);
	
	return NoLightRayResult(cornerDistance, CORNER_COLOR);
}


RayResult getFloorResult(vec3 rayPoint) {
	vec3 floorCenter = vec3(CENTER.x, CENTER.y - HALF_FLOOR_BLOCK_HEIGHT, CENTER.z);
	vec3 floorB = vec3(getHalfTileWidth(), HALF_FLOOR_BLOCK_HEIGHT, getHalfTileWidth());

	float floorDistance = getBoxDistance(floorCenter, floorB, rayPoint);
	
	// Performance
	if (floorDistance > 0.1) return NoHitRayResult(floorDistance);
	
	RayResult streetResult = getStreetResult(rayPoint);
	RayResult sidewalkResult = getSidewalkResult(rayPoint);
	RayResult cornerResult = getCornerResult(rayPoint);
	
	RayResult closestResult = getCloserRayResult(streetResult, sidewalkResult);
	closestResult = getCloserRayResult(closestResult, cornerResult);
	
	return closestResult;
}


const float MINIMUM_WINDOW_ROWS = 4;
const float WINDOWS_PER_ROW = 5;

const float WINDOW_WIDTH = 0.06;
const float WINDOW_HEIGHT = 0.25;

const float GROUND_LEVEL_HEIGHT = 0.3;

const float GLOW_LENGTH = 0.04;

const float HALF_WINDOW_WIDTH = WINDOW_WIDTH / 2.0;



float WINDOW_ON_EXPONENT = 4;
float WINDOW_OFF_EXPONENT = 8;

float WINDOW_ON_THRESHOLD = 1.0;

float X_SEED = 3;
float Y_SEED = 7;
float Z_SEED = 4;
float MINUS_SEED_FACTOR = 3;



struct WindowValue {
	float glowFactor;
	float randFactor;
};


WindowValue getWindowValue(float value, float windowSize, float spaceBetweenWindows, float end, float seed) {
	float unitSize = windowSize + spaceBetweenWindows;
	
	float modValue = mod(value, unitSize);
	
	float randFactor = rand(floor((value + GLOW_LENGTH) / unitSize) + seed);
	
	
	float glowingPartSize = windowSize + GLOW_LENGTH;
	
	if (value > (end - GLOW_LENGTH)) {
		return WindowValue(0.0, 0.0);
	}
	
	if (modValue < windowSize) {
		return WindowValue(1.0, randFactor);
	}
	
	if (modValue < glowingPartSize) {
		float glowFactor = myReverseSmoothstep2(modValue, windowSize, GLOW_LENGTH);
		return WindowValue(glowFactor, randFactor);
	}
	
	if (modValue > (unitSize - GLOW_LENGTH)) {
		float glowFactor = mySmoothstep2(modValue, unitSize - GLOW_LENGTH, GLOW_LENGTH);
		return WindowValue(glowFactor, randFactor);
	}
	
	return WindowValue(0.0, 0.0);
}



WindowValue getHorizontalWindowValue(float horizontalValue, float buildingWidth, float spaceBetweenWindows, float seed) {
	float value = abs(horizontalValue) + HALF_WINDOW_WIDTH;
	
	float newSeed = seed;
	
	if (horizontalValue < 0 && abs(horizontalValue) > (HALF_WINDOW_WIDTH + GLOW_LENGTH)) {
		newSeed = seed * MINUS_SEED_FACTOR;
	}
	
	return getWindowValue(value, WINDOW_WIDTH, spaceBetweenWindows, buildingWidth / 2.0, newSeed);
}

WindowValue getVerticalWindowValue(float verticalValue, float buildingHeight, float spaceBetweenWindows, float seed) {
	if (verticalValue < (GROUND_LEVEL_HEIGHT - GLOW_LENGTH)) return WindowValue(0.0, 0.0);
	
	float value = verticalValue - GROUND_LEVEL_HEIGHT;
	
	return getWindowValue(value, WINDOW_HEIGHT, spaceBetweenWindows, buildingHeight - GROUND_LEVEL_HEIGHT, seed);
}

LightedColor getBuildingColor(float buildingWidth, float buildingHeight, vec3 rayPoint, vec3 rowRayPoint, float seed) {
	float totalWindowWidth = WINDOWS_PER_ROW * WINDOW_WIDTH;
	float horizontalSpaceBetweenWindows = (buildingWidth - totalWindowWidth) / (WINDOWS_PER_ROW + 1);
	
	float xSeed = X_SEED * seed;
	float ySeed = Y_SEED * seed;
	float zSeed = Z_SEED * seed;
	
	WindowValue xWindowValue = getHorizontalWindowValue(rowRayPoint.x, buildingWidth, horizontalSpaceBetweenWindows, xSeed);
	WindowValue zWindowValue = getHorizontalWindowValue(rowRayPoint.z, buildingWidth, horizontalSpaceBetweenWindows, zSeed);
	
	WindowValue hWindowValue = xWindowValue.glowFactor < zWindowValue.glowFactor ? zWindowValue : xWindowValue;
	
	float totalWindowHeight = MINIMUM_WINDOW_ROWS * WINDOW_HEIGHT;
	float verticalSpaceBetweenWindows = (buildingHeight - GROUND_LEVEL_HEIGHT - totalWindowHeight) / MINIMUM_WINDOW_ROWS;
	
	WindowValue vWindowValue = getVerticalWindowValue(rayPoint.y, buildingHeight, verticalSpaceBetweenWindows, ySeed);
	
	float glowValue = hWindowValue.glowFactor * vWindowValue.glowFactor;
	
	bool isWindowOn = hWindowValue.randFactor + vWindowValue.randFactor > WINDOW_ON_THRESHOLD;
	
	float glowExponent = isWindowOn ? WINDOW_ON_EXPONENT : WINDOW_OFF_EXPONENT;
	vec3 windowColor = isWindowOn ? WINDOW_ON_COLOR : WINDOW_OFF_COLOR;
	
	glowValue = pow(glowValue, glowExponent);
	
	vec3 color = glowValue * windowColor + (1 - glowValue) * BUILDING_COLOR;
	
	return LightedColor(color, glowValue);
}


RayResult getBuildingsResult(vec3 rayPoint) {
	float rowSize = getTileWidth() / ROWS_PER_TILE;
	
	vec3 rowModVector = vec3(rowSize, 1, rowSize);
	
	vec3 rowModRayPoint = mod(rayPoint, rowModVector) - 0.5 * rowModVector;
	
	vec3 rowRayPoint = vec3(rowModRayPoint.x, rayPoint.y, rowModRayPoint.z);
	
	float buildingSideSpace = (rowSize - rowSize * REL_BUILDING_WIDTH) / 2.0;
	
	float rowBuildingStartX = floor(abs(rayPoint.x) / rowSize) * rowSize + buildingSideSpace;
	float rowBuildingStartZ = floor(abs(rayPoint.z) / rowSize) * rowSize + buildingSideSpace;
	
	float test2 = rand(rowBuildingStartX) + rand(rowBuildingStartZ);
	
	vec3 t1 = mod(rayPoint, rowModVector);
	
	float h = 1.5 - rowBuildingStartX * 0.1 - rowBuildingStartZ * 0.1;
	
	h = 0.9;
	
	
	float buildingBLength = rowSize * REL_BUILDING_WIDTH / 2.0;
	
	vec3 myBoxC = vec3(0, h, 0);
	vec3 myBoxB = vec3(buildingBLength, h, buildingBLength);
	
	
	float myBoxDist = getBoxDistance(myBoxC, myBoxB, rowRayPoint);
	
	float closestBuildingStart = HALF_STREET_WIDTH + SIDEWALK_WIDTH + MIN_MARGIN_TO_SIDEWALK;
	
	float dis1 = (closestBuildingStart + buildingSideSpace) - abs(rayPoint.x);
	float dis2 = (closestBuildingStart + buildingSideSpace) - abs(rayPoint.z);
	
	float dis = min(dis1, dis2);
	
	if (dis1 < 0) dis = dis2;
	if (dis2 < 0) dis = dis1;
	
	//dis = dis1;
	
	//dis -= 0.1;
	
	dis = buildingSideSpace;
	
	if (rowBuildingStartX < closestBuildingStart) {
		// TODO: statt buildingSideSpace was anderes -> optimize
		//return RayHit(myBoxDist, vec3(1, 0, 0.4));
		return NoHitRayResult(dis);
	}
	if (rowBuildingStartZ < closestBuildingStart) {
		//return RayHit(myBoxDist, vec3(0, 0.4, 1));
		return NoHitRayResult(dis);
	}
	
	float buildingWidth = rowSize * REL_BUILDING_WIDTH;
	
	LightedColor lightedColor = LightedColor(vec3(0), 0.0);
	
	if (myBoxDist < 0.01) {
		lightedColor = getBuildingColor(buildingWidth, 1.8, rayPoint, rowRayPoint, test2 / 2.0);
	}
	
	return RayResult(myBoxDist, lightedColor.color, lightedColor.lightFactor);
}





vec3 getModRayPoint(vec3 rayPoint) {
	vec3 modVector = vec3(getTileWidth(), 1, getTileWidth());
	
	vec3 modRayPoint = mod(rayPoint, modVector) - 0.5 * modVector;
	
	return vec3(modRayPoint.x, rayPoint.y, modRayPoint.z);
}



RayResult distFuncWithColor(vec3 rayPoint) {
	vec3 modRayPoint = getModRayPoint(rayPoint);
	
	RayResult floorRayResult = getFloorResult(modRayPoint);
	RayResult buildingsRayResult = getBuildingsResult(modRayPoint);
	
	return getCloserRayResult(floorRayResult, buildingsRayResult);
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
	
	int maxSteps = 500;
	
	vec3 color = vec3(0);
	vec4 color4 = vec4(0);
	
	vec3 point = camP;
	
	int step = 0;
	
	bool hit = false;
	
	float maxDistance = 150;
	
	float ff = 0;
	
	while (step < maxSteps) {
		
		RayResult rayResult = distFuncWithColor(point);
		float hitDistance = rayResult.dist;
		vec3 hitColor = rayResult.color;
		
		float distanceToCam = distance(camP, point);
		
		if (distanceToCam > FOG_END) break;
		
		if (hitDistance < EPSILON) {
			hit = true;
			
			color = hitColor;
			
			vec3 hitNormal = getNormal(point);
			vec3 toLight = normalize(vec3(-100, 100, -100) - point);
			
			float lambert = max(dot(hitNormal, toLight), 0.2);
			
			
			if (rayResult.lightFactor < 0.5) color *= lambert;
			
			// test
			//if (hitColor.b > 0.9) color = hitColor;
			
			//color *= max((maxDistance - distanceToCam) / maxDistance, 0);
			//color = hitNormal;
			
			ff = getFogFactor(distanceToCam);
			
			color4 = vec4(color, 1.0);
			//color4 = vec4(color, getFogFactor(distanceToCam));
			//color4 = vec4(getFogFactor(distanceToCam), color.g, color.b, 1.0);
			
			break;
		}
		
		point = point + camDir * hitDistance;
	
		step++;
	}
	
	vec3 bgColor = getBackgroundColor(camDir.xy);
	
	color4 = ff * color4 + (1 - ff) * vec4(bgColor, 1.0);
	
	if (!hit && false) {
		//color = vec3(0);
		color = getBackgroundColor(camDir.xy);
		color4 = vec4(color, 1.0);
	}
	
	gl_FragColor = color4;
	//gl_FragColor = vec4(color, 1.0);
}


