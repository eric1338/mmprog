#version 330
//#include "../libs/camera.glsl"


// include funktioniert nicht mehr Oo

uniform float iCamPosX;
uniform float iCamPosY;
uniform float iCamPosZ;
uniform float iCamRotX;
uniform float iCamRotY;
uniform float iCamRotZ;

vec3 calcCameraPos()
{
	return vec3(iCamPosX, iCamPosY, iCamPosZ);
}

// Rotate around a coordinate axis (i.e. in a plane perpendicular to that axis) by angle <a>.
// Read like this: R(p.xz, a) rotates "x towards z".
// This is fast if <a> is a compile-time constant and slower (but still practical) if not.
void rotateAxis(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

vec3 calcCameraRayDir(float fov, vec2 fragCoord, vec2 resolution) 
{
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / resolution.x;
	vec2 p = tanFov * (fragCoord * 2.0 - resolution.xy);
	vec3 rayDir = normalize(vec3(p.x, p.y, 1.0));
	rotateAxis(rayDir.yz, iCamRotX);
	rotateAxis(rayDir.xz, iCamRotY);
	rotateAxis(rayDir.xy, iCamRotZ);
	return rayDir;
}








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



const float STREET_WIDTH = 1;
const float SIDEWALK_WIDTH = 0.2;
const float CORNER_WIDTH = 4.4;

const float SIDEWALK_DEPTH = 0.01;
const float CORNER_DEPTH = 0.0;
const float STREET_DEPTH = 0.03;

const vec3 CENTER = vec3(0.0);

const float FLOOR_BLOCK_HEIGHT = 0.05;

const float BUILDING_ROWS_PER_CORNER = 3;


const vec3 STREET_COLOR = vec3(0.1);
const vec3 STRIPE_COLOR = vec3(1);
const vec3 SIDEWALK_COLOR = vec3(0.2);
const vec3 CORNER_COLOR = vec3(0.2, 0.4, 0.4);


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



struct RayHit {
	float dist;
	vec3 color;
};

const RayHit FAR_HIT = RayHit(9999, vec3(0));


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




RayHit getStreetHit(vec3 rayPoint) {
	vec3 streetCenter = vec3(CENTER.x, CENTER.y - STREET_DEPTH - HALF_FLOOR_BLOCK_HEIGHT, CENTER.z);
	vec3 streetB = vec3(getHalfTileWidth(), HALF_FLOOR_BLOCK_HEIGHT, getHalfTileWidth());
	
	float streetDistance = getBoxDistance(streetCenter, streetB, rayPoint);

	return RayHit(streetDistance, STREET_COLOR);
}


RayHit getSidewalkHit(vec3 rayPoint) {
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
	
	return RayHit(sidewalkDistance, SIDEWALK_COLOR);
}


RayHit getCornerHit(vec3 rayPoint) {
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
	
	return RayHit(cornerDistance, CORNER_COLOR);
}


RayHit getFloorHit(vec3 rayPoint) {
	vec3 floorCenter = vec3(CENTER.x, CENTER.y - HALF_FLOOR_BLOCK_HEIGHT, CENTER.z);
	vec3 floorB = vec3(getHalfTileWidth(), HALF_FLOOR_BLOCK_HEIGHT, getHalfTileWidth());

	float floorDistance = getBoxDistance(floorCenter, floorB, rayPoint);
	
	// Performance
	if (floorDistance > 0.1) return RayHit(floorDistance, vec3(0));
	
	RayHit streetHit = getStreetHit(rayPoint);
	RayHit sidewalkHit = getSidewalkHit(rayPoint);
	RayHit cornerHit = getCornerHit(rayPoint);
	
	RayHit closestHit = getCloserHit(streetHit, sidewalkHit);
	closestHit = getCloserHit(closestHit, cornerHit);
	
	return closestHit;
}




const float BUILDING_WIDTH = 0.8;
const float HALF_BUILDING_WIDTH = BUILDING_WIDTH / 2.0;

const float MIN_BUILDING_SPACE = 0.2;

const int MIN_WINDOW_ROWS = 6;
const int MAX_ADDITIONAL_WINDOW_ROWS = 4;
const int WINDOW_COLS = 4;


const vec3 WINDOW_ON_COLOR = vec3(0.9);
const vec3 WINDOW_OFF_COLOR = vec3(0.5);


RayHit getBuildingHit2(vec3 rayPoint, vec2 buildingCenterXZ) {
	vec3 buildingCenter = vec3(buildingCenterXZ.x, 0.5, buildingCenterXZ.y);
	vec3 buildingB = vec3(HALF_BUILDING_WIDTH, 0.5, HALF_BUILDING_WIDTH);
	
	float ds = getBoxDistance(buildingCenter, buildingB, rayPoint);
	
	return RayHit(ds, vec3(1));
}


RayHit getBuildingHit21(vec3 rayPoint, vec2 buildingCenterXZ) {
	float rand1 = rand(buildingCenterXZ);
	
	int nWindowsY = MIN_WINDOW_ROWS + int(rand1 * MAX_ADDITIONAL_WINDOW_ROWS);
	int nWindowsZ = WINDOW_COLS;
	
	vec3 buildingCenter = vec3(buildingCenterXZ.x, nWindowsY / 10.0, buildingCenterXZ.y);
	vec3 buildingB = vec3(HALF_BUILDING_WIDTH, nWindowsY / 10.0, HALF_BUILDING_WIDTH);
	
	float blockDistance = getBoxDistance(buildingCenter, buildingB, rayPoint);
	
	// Performance
	if (blockDistance > 0.01) return RayHit(blockDistance, vec3(0));
	
	float facadeDistance = blockDistance;
	
	RayHit closestWindowHit = RayHit(9999.9, vec3(0));
	
	float windowWidth = 0.025;
	float windowHeight = 0.035;
	
	vec3 windowB = vec3(buildingB.x * 1.0, windowHeight, windowWidth);
	vec3 cutoutB = vec3(buildingB.x * 6, windowHeight, windowWidth);
	
	float startY = buildingCenter.y - buildingB.y;
	float stepY = (2 * buildingB.y) / (nWindowsY + 1);
	
	// for (int i = 1; i <= nWindowsY; i++) {
		// for (int j = -1; j <= 1; j++) {
			// float windowCenterY = startY + stepY * i;
			// float windowCenterZ = buildingCenter.z + (buildingB.z / 1.7) * j;
			
			// vec3 windowCenter = vec3(buildingCenter.x, windowCenterY, windowCenterZ);
			
			// float windowCutout = getSubtractBoxDistance(windowCenter, cutoutB, rayPoint);
			// facadeDistance = subtractDistances(facadeDistance, windowCutout);
			
			// float windowBox = getBoxDistance(windowCenter, windowB, rayPoint);
			
			// float rand2 = rand(windowCenter.yz);
			// vec3 windowColor = rand2 > 0.5 ? WINDOW_ON_COLOR : WINDOW_OFF_COLOR;
			
			// RayHit currentWindowHit = RayHit(windowBox, windowColor);
			
			// closestWindowHit = getCloserHit(closestWindowHit, currentWindowHit);
			
			// windowDistance = addDistances(windowDistance, windowBox);
		// }
	// }
	
	vec3 facadeColor = vec3(0.3, 0.3, 0.4);
	vec3 windowColor = vec3(0.8, 0.9, 1);
	
	RayHit facadeHit = RayHit(facadeDistance, facadeColor);
	//RayHit windowHit = RayHit(windowDistance, windowColor);
	
	return getCloserHit(facadeHit, closestWindowHit);
}


RayHit getBuildingsHit2(vec3 rayPoint) {
	vec3 myBoxC = vec3(CENTER.x, 1, CENTER.y);
	vec3 myBoxB = vec3(1);
	
	float myBoxDist = getBoxDistance(myBoxC, myBoxB, rayPoint);
	
	return RayHit(myBoxDist, vec3(1));
	
	float buildingRows = floor(CORNER_WIDTH / (MIN_BUILDING_SPACE + BUILDING_WIDTH));
	
	float buildingSpace = (CORNER_WIDTH - buildingRows * BUILDING_WIDTH) / buildingRows;
	
	float buildingCenterDistance = BUILDING_WIDTH + buildingSpace;
	
	
	RayHit closestHit = FAR_HIT;
	
	return FAR_HIT;
	
	for (int i = 0; i < 4; i++) {
		vec2 upperLeftCorner;
		
		float negativeOffset = getHalfTileWidth();
		float positiveOffset = HALF_STREET_WIDTH + SIDEWALK_WIDTH;
		
		if (i == 0) upperLeftCorner = vec2(CENTER.x - negativeOffset, CENTER.z - negativeOffset);
		else if (i == 1) upperLeftCorner = vec2(CENTER.x - negativeOffset, CENTER.z + positiveOffset);
		else if (i == 2) upperLeftCorner = vec2(CENTER.x + positiveOffset, CENTER.z - negativeOffset);
		else upperLeftCorner = vec2(CENTER.x + positiveOffset, CENTER.z + positiveOffset);
		
		vec3 testBoxCenter = vec3(upperLeftCorner.x + HALF_CORNER_WIDTH, 2, upperLeftCorner.y + HALF_CORNER_WIDTH);
		vec3 textBoxB = vec3(HALF_CORNER_WIDTH, 2, HALF_CORNER_WIDTH);
		
		float testDist = getBoxDistance(testBoxCenter, textBoxB, rayPoint);
		
		// 2do: Modulo
		
		//return RayHit(testDist, vec3(0.4, 0.9, 1.0));
		
		if (testDist > 0.05) {
			closestHit = RayHit(testDist, vec3(0));
			continue;
		}
		
		for (int j = 0; j < buildingRows; j++) {
			for (int k = 0; k < buildingRows; k++) {
			
				//if (j > 0 && k > 0 && j < (buildingRows - 1) && k < (buildingRows - 1)) continue;
				
				float xOffset = (j + 0.5) * buildingCenterDistance;
				float zOffset = (k + 0.5) * buildingCenterDistance;
				
				vec2 buildingXZ = vec2(upperLeftCorner.x + xOffset, upperLeftCorner.y + zOffset);
				
				RayHit buildingHit = getBuildingHit2(rayPoint, buildingXZ);
				
				//if (buildingHit.dist < 0.01) return buildingHit;
				
				closestHit = getCloserHit(closestHit, buildingHit);
			}
		}
	}
	
	return closestHit;
}



	
/*
void bla() {
	float stripeLength = 0.04;
	float stripeWidth = 0.006;
	
	float stripeDistance = getBoxDistance(vec3(-100), vec3(1), vec3(1));
	vec3 stripeB = vec3(stripeWidth, 0.001, stripeLength);
	
	for (int i = -10; i <= 10; i++) {
		vec3 stripeCenter = vec3(-0.5, -0.049, i * 0.3);
		float singleStripeDistance = getBoxDistance(stripeCenter, stripeB, rayPoint);
		
		stripeDistance = addDistances(stripeDistance, singleStripeDistance);
	}
}
*/


vec3 getModRayPoint(vec3 rayPoint) {
	vec3 modVector = vec3(getTileWidth(), 0, getTileWidth());
	
	vec3 modRayPoint = mod(rayPoint, modVector) - 0.5 * modVector;
	
	return vec3(modRayPoint.x, rayPoint.y, modRayPoint.z);
}



RayHit distFuncWithColor(vec3 rayPoint) {
	vec3 modRayPoint = getModRayPoint(rayPoint);
	
	RayHit floorHit = getFloorHit(modRayPoint);
	RayHit buildingHit = getBuildingsHit2(modRayPoint);
	
	return getCloserHit(floorHit, buildingHit);
}


float distFunc(vec3 rayPoint) {
	RayHit rayHit = distFuncWithColor(rayPoint);

	return rayHit.dist;
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
	
	int maxSteps = 200;
	
	vec3 color = vec3(0);
	
	vec3 point = camP;
	
	int step = 0;
	
	bool hit = false;
	
	float maxDistance = 150;
	
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
		//color = vec3(0);
		color = getBackgroundColor(camDir.xy);
	}
	
	gl_FragColor = vec4(color, 1.0);
}


