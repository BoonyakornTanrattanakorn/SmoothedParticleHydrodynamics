#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// A binding to the buffer we create in our script
layout(set = 0, binding = 0, std430) restrict buffer PositionBuffer {
    vec2 position[];
}
position;

layout(set = 0, binding = 1, std430) restrict buffer DensityBuffer {
    float density[];
}
density;

layout(set = 0, binding = 2, std430) restrict buffer ParamBuffer {
    float mass;
    float particle_num;
    float smoothing_length;
}
param;

float pow(float base, int exp){
    float result = 1.0;
    for(int i = 0; i < exp; ++i){
        result *= base;
    }
    return result;
}

#define PI 3.14159265359

// smoothing kernel
float W(float r, float h){
    float alpha = 3.0 / (2.0 * PI * pow(h, 2));
	float q = r / h;
	if (q >= 2){
		return 0.0;
	} else {
		return alpha * ((1.0/6.0) * pow((2.0-q), 3));
    }
}

// The code we want to execute in each invocation
void main() {
    int particle_index = int(gl_GlobalInvocationID.x);
    for(int idx = 0; idx < int(param.particle_num); ++idx){
        float dst = length(position.position[particle_index] - position.position[idx]);
        density.density[particle_index] += param.mass * W(dst, param.smoothing_length);
    }
}