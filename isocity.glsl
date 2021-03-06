#version 330

#include "mylib.glsl"
#include "mylib3d.glsl"
#include "../libs/camera.glsl"


uniform vec2 iResolution;
uniform float iGlobalTime;

uniform float uMusic;
uniform float uIsocityWindowThresholdOffset;
uniform float uIsocityVisibilityFactor;

const float EPSILON = 0.001;

const float MAX_STEPS = 500;

const float FOG_START = 10;
const float FOG_END = 50;

float getFogFactor(float distance) {
	if (distance < FOG_START) return 1;
	if (distance > FOG_END) return 0;
	
	return (FOG_END - distance) / (FOG_END - FOG_START);
}


const float STREET_WIDTH = 1.6;
const float SIDEWALK_WIDTH = 0.2;
const float CORNER_WIDTH = 3.9;

const float SIDEWALK_DEPTH = 0.01;
const float CORNER_DEPTH = 0.0;
const float STREET_DEPTH = 0.03;

const vec3 CENTER = vec3(0.0);

const float FLOOR_BLOCK_HEIGHT = 0.05;


const float ROWS_PER_TILE = 6;
const float REL_BUILDING_WIDTH = 0.8;
const float MIN_MARGIN_TO_SIDEWALK = 0.05;


const float MINIMUM_WINDOW_ROWS = 8;
const float MAXIMUM_ADDITIONAL_WINDOW_ROWS = 5;
const float WINDOWS_PER_ROW = 5;

const float WINDOW_WIDTH = 0.12;
const float WINDOW_HEIGHT = 0.25;

const float VERTICAL_WINDOW_SPACE = 0.2;

const float GROUND_LEVEL_HEIGHT = 0.3;

const float WINDOW_ON_LOWER_THRESHOLD = 0.1;
const float WINDOW_ON_UPPER_THRESHOLD = 0.7;

const float X_SEED = 6.97;
const float Y_SEED = 4.42;
const float Z_SEED = 7.43;
const float MINUS_SEED_FACTOR = 4.15;


const vec3 STREET_COLOR = vec3(0.1);
const vec3 STRIPE_COLOR = vec3(1);
const vec3 SIDEWALK_COLOR = vec3(0.2);
//const vec3 CORNER_COLOR = vec3(0.2, 0.4, 0.4);
const vec3 CORNER_COLOR = vec3(0.2, 0.4, 0.6);

const vec3 BUILDING_COLOR = vec3(0.229, 0.218, 0.26);
const vec3 WINDOW_ON_COLOR = vec3(0.9);
//const vec3 WINDOW_ON_COLOR = vec3(0.963, 0.89, 0.741);
const vec3 WINDOW_OFF_COLOR = vec3(0.25);

const float GLOW_LENGTH = 0.04;
const float WINDOW_ON_EXPONENT = 4;
const float WINDOW_OFF_EXPONENT = 8;

const float HALF_STREET_WIDTH = STREET_WIDTH / 2.0;
const float HALF_SIDEWALK_WIDTH = SIDEWALK_WIDTH / 2.0;
const float HALF_CORNER_WIDTH = CORNER_WIDTH / 2.0;
const float HALF_WHOLE_CORNER_WIDTH = (SIDEWALK_WIDTH + CORNER_WIDTH) / 2.0;
const float HALF_FLOOR_BLOCK_HEIGHT = FLOOR_BLOCK_HEIGHT / 2.0;
const float HALF_WINDOW_WIDTH = WINDOW_WIDTH / 2.0;


float getTileWidth() {
	return STREET_WIDTH + 2 * SIDEWALK_WIDTH + 2 * CORNER_WIDTH;
}

float getHalfTileWidth() {
	return getTileWidth() / 2.0;
}

float getWindowOnExponent() {
	return WINDOW_ON_EXPONENT;
	//return WINDOW_ON_EXPONENT * (1 - uMusic * 0.7);
}

float getWindowOnLowerThreshold() {
	return WINDOW_ON_LOWER_THRESHOLD + uIsocityWindowThresholdOffset;
}

float getWindowOnUpperThreshold() {
	return WINDOW_ON_UPPER_THRESHOLD + uIsocityWindowThresholdOffset;
}

float getVisibilityFactor() {
	return uIsocityVisibilityFactor;
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

WindowValue getVerticalWindowValue(float verticalValue, float buildingHeight, float seed) {
	if (verticalValue < (GROUND_LEVEL_HEIGHT - GLOW_LENGTH)) return WindowValue(0.0, 0.0);
	
	float value = verticalValue - GROUND_LEVEL_HEIGHT;
	
	return getWindowValue(value, WINDOW_HEIGHT, VERTICAL_WINDOW_SPACE, buildingHeight - GROUND_LEVEL_HEIGHT, seed);
}

LightedColor getBuildingColor(float buildingWidth, float buildingHeight, float windowRows, vec3 rayPoint, vec3 rowRayPoint, float seed) {
	float totalWindowWidth = WINDOWS_PER_ROW * WINDOW_WIDTH;
	float horizontalSpaceBetweenWindows = (buildingWidth - totalWindowWidth) / (WINDOWS_PER_ROW + 1);
	
	float xSeed = X_SEED * seed;
	float ySeed = Y_SEED * seed;
	float zSeed = Z_SEED * seed;
	
	WindowValue xWindowValue = getHorizontalWindowValue(rowRayPoint.x, buildingWidth, horizontalSpaceBetweenWindows, xSeed);
	WindowValue zWindowValue = getHorizontalWindowValue(rowRayPoint.z, buildingWidth, horizontalSpaceBetweenWindows, zSeed);
	
	WindowValue hWindowValue = xWindowValue.glowFactor < zWindowValue.glowFactor ? zWindowValue : xWindowValue;
	
	WindowValue vWindowValue = getVerticalWindowValue(rayPoint.y, buildingHeight, ySeed);
	
	float glowValue = hWindowValue.glowFactor * vWindowValue.glowFactor;
	
	float windowOnFactor = hWindowValue.randFactor + vWindowValue.randFactor;
	
	bool isWindowOn = windowOnFactor > getWindowOnLowerThreshold() && windowOnFactor < getWindowOnUpperThreshold();
	
	float glowExponent = isWindowOn ? getWindowOnExponent() : WINDOW_OFF_EXPONENT;
	vec3 windowColor = isWindowOn ? WINDOW_ON_COLOR : WINDOW_OFF_COLOR;
	
	glowValue = pow(glowValue, glowExponent);
	
	vec3 color = glowValue * windowColor + (1 - glowValue) * BUILDING_COLOR;
	
	return LightedColor(color, glowValue);
}


RayResult getBuildingsResult(vec3 rayPoint, vec3 modRayPoint) {
	float rowSize = getTileWidth() / ROWS_PER_TILE;
	
	vec3 rowModVector = vec3(rowSize, 1, rowSize);
	
	vec3 rowModRayPoint = mod(modRayPoint, rowModVector) - 0.5 * rowModVector;
	
	vec3 rowRayPoint = vec3(rowModRayPoint.x, modRayPoint.y, rowModRayPoint.z);
	
	float buildingSideSpace = (rowSize - rowSize * REL_BUILDING_WIDTH) / 2.0;
	
	float fixedBuildingX = floor(modRayPoint.x / rowSize);
	float fixedBuildingZ = floor(modRayPoint.z / rowSize);
	
	float fixedTileX = floor(rayPoint.x / getTileWidth());
	float fixedTileZ = floor(rayPoint.z / getTileWidth());
	
	float seed = rand(fixedBuildingX * 10) + rand(fixedBuildingZ * 10);
	seed = rand(seed + rand(fixedTileX) + rand(fixedTileZ));
	
	float floorSize = WINDOW_HEIGHT + VERTICAL_WINDOW_SPACE;
	
	float additionalFloors = round(rand(seed) * MAXIMUM_ADDITIONAL_WINDOW_ROWS);
	float numberOfFloors = MINIMUM_WINDOW_ROWS + additionalFloors;
	
	float buildingHeight = numberOfFloors * floorSize + GROUND_LEVEL_HEIGHT;
	
	float buildingBLength = rowSize * REL_BUILDING_WIDTH / 2.0;
	
	vec3 buildingCenter = vec3(0, buildingHeight / 2.0, 0);
	vec3 buildingB = vec3(buildingBLength, buildingHeight / 2.0, buildingBLength);
	
	float buildingDistance = getBoxDistance(buildingCenter, buildingB, rowRayPoint);
	
	float rowBuildingStartX = floor(abs(modRayPoint.x) / rowSize) * rowSize + buildingSideSpace;
	float rowBuildingStartZ = floor(abs(modRayPoint.z) / rowSize) * rowSize + buildingSideSpace;
	
	float closestBuildingStart = HALF_STREET_WIDTH + SIDEWALK_WIDTH + MIN_MARGIN_TO_SIDEWALK;
	
	if (rowBuildingStartX < closestBuildingStart) {
		// TODO: statt buildingSideSpace was anderes -> optimize
		return NoHitRayResult(buildingSideSpace);
	}
	if (rowBuildingStartZ < closestBuildingStart) {
		return NoHitRayResult(buildingSideSpace);
	}
	
	if (rayPoint.y > buildingHeight && buildingDistance > buildingSideSpace) {
		return NoHitRayResult(buildingSideSpace);
	}
	
	float buildingWidth = rowSize * REL_BUILDING_WIDTH;
	
	LightedColor lightedColor = LightedColor(vec3(0, 0, 1), 0.0);
	
	if (buildingDistance < 0.01) {
		lightedColor = getBuildingColor(buildingWidth, buildingHeight, numberOfFloors, rayPoint, rowRayPoint, seed);
	}
	
	return RayResult(buildingDistance, lightedColor.color, lightedColor.lightFactor);
}



vec3 getModRayPoint(vec3 rayPoint) {
	vec3 modVector = vec3(getTileWidth(), 1, getTileWidth());
	
	vec3 modRayPoint = mod(rayPoint, modVector) - 0.5 * modVector;
	
	return vec3(modRayPoint.x, rayPoint.y, modRayPoint.z);
}


RayResult distFuncWithColor(vec3 rayPoint) {
	vec3 modRayPoint = getModRayPoint(rayPoint);
	
	RayResult floorRayResult = getFloorResult(modRayPoint);
	RayResult buildingsRayResult = getBuildingsResult(rayPoint, modRayPoint);
	
	return getCloserRayResult(floorRayResult, buildingsRayResult);
}


float distFunc(vec3 rayPoint) {
	RayResult rayResult = distFuncWithColor(rayPoint);

	return rayResult.dist;
}

vec3 getNormal(vec3 point) {
	float d = EPSILON;
	
	vec3 right = point + vec3(d, 0.0, 0.0);
	vec3 left = point + vec3(-d, 0.0, 0.0);
	vec3 up = point + vec3(0.0, d, 0.0);
	vec3 down = point + vec3(0.0, -d, 0.0);
	vec3 behind = point + vec3(0.0, 0.0, d);
	vec3 before = point + vec3(0.0, 0.0, -d);
	
	vec3 gradient = vec3(distFunc(right) - distFunc(left),
		distFunc(up) - distFunc(down),
		distFunc(behind) - distFunc(before));
	return normalize(gradient);
}

vec3 BG_COLOR_1 = vec3(0.7, 0.5, 0.515);
vec3 BG_COLOR_2 = vec3(0.45, 0.383, 0.43);

//vec3 BG_COLOR_1 = vec3(0.0, 0.3, 0.5);
//vec3 BG_COLOR_2 = vec3(0.98, 0.77, 0.4);


vec3 getBackgroundColor(vec2 coord) {
	//return BG_COLOR_1;
	
	//return getTwoColorFogBackground(coord, BG_COLOR_1, BG_COLOR_2, vec3(0.4), 0.2);
	
	float f1 = cos(coord.x + 0.2);
	float f2 = cos(coord.y + 0.1);
	
	float greenFactor = f1 * 0.5 + f2 * 0.5;
	
	float blueFactor = 1 - greenFactor;
	
	//vec3 bgColor = greenFactor * BG_COLOR_1 + blueFactor * BG_COLOR_2;
	
	greenFactor = greenFactor * 0.5 + 0.5;
	blueFactor = blueFactor * 0.5 + 0.6;
	
	//vec3 bgColor = vec3(0.0, 0.2 + greenFactor, 0.5 + blueFactor) * 0.4;
	vec3 bgColor = vec3(0.0, greenFactor * 0.8, blueFactor) * 0.35;
	
	// + getBackgroundFogColor(coord.yx, vec3(0, 0.3, 1.0), 0.1)
	
	//color += getBackgroundFogColor(coord.yx, vec3(1, 0, 0.0), 0.6);
	
	vec3 fogColor = vec3(0, 0.3, 1);
	float fogFactor = 0.3;
	
	bgColor += getBackgroundFogColor(coord, fogColor, fogFactor);
	bgColor += getBackgroundFogColor(coord + vec2(10, 20), fogColor, fogFactor);
	
	return bgColor;
}


void main() {
	vec3 camP = calcCameraPos();
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);
	
	vec4 color4 = vec4(0);
	
	vec3 point = camP;
	
	int step = 0;
	
	bool hit = false;
	
	float fogFactor = 0;
	
	while (step < MAX_STEPS) {
		RayResult rayResult = distFuncWithColor(point);
		float hitDistance = rayResult.dist;
		vec3 hitColor = rayResult.color;
		
		float distanceToCam = distance(camP, point);
		
		if (distanceToCam > FOG_END) break;
		
		if (hitDistance < EPSILON) {
			hit = true;
			
			vec3 color = hitColor;
			
			vec3 hitNormal = getNormal(point);
			vec3 toLight = normalize(vec3(-100, 100, -100) - point);
			
			float lambert = max(dot(hitNormal, toLight), 0.2);
			
			if (rayResult.lightFactor < 0.5) color *= lambert;
			
			fogFactor = getFogFactor(distanceToCam);
			
			color4 = vec4(color, 1.0);
			
			break;
		}
		
		point = point + camDir * hitDistance;
	
		step++;
	}
	
	vec3 backgroundColor = getBackgroundColor(camDir.xy);
	
	color4 = fogFactor * color4 + (1 - fogFactor) * vec4(backgroundColor, 1.0);
	
	gl_FragColor = color4 * getVisibilityFactor();
}


