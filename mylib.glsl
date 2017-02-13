
float mySmoothstep(float value, float zeroStart, float oneEnd) {
	if (value < zeroStart) return 0.0;
	if (value > oneEnd) return 1.0;
	
	return (value - zeroStart) / (oneEnd - zeroStart);
}

float mySmoothstep2(float value, float zeroStart, float stepSize) {
	return mySmoothstep(value, zeroStart, zeroStart + stepSize);
}

float myReverseSmoothstep(float value, float oneStart, float zeroEnd) {
	return 1 - mySmoothstep(value, oneStart, zeroEnd);
}

float myReverseSmoothstep2(float value, float oneStart, float stepSize) {
	return myReverseSmoothstep(value, oneStart, oneStart + stepSize);
}
