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

layout(set = 0, binding = 2, std430) restrict buffer PressureForceBuffer {
    vec2 pressure_force[];
}
pressure_force;

layout(set = 0, binding = 3, std430) restrict buffer ParamBuffer {
    float mass;
    float particle_num;
    float smoothing_length;
    float gas_constant;
    float rest_density;
}
param;

#define PI 3.14159265359

// return [-1, 1]
float random(uint seed) {
    seed = seed * 747796405u + 2891336453u;
    seed = ((seed >> 28u) ^ seed) * 277803737u;
    return float(seed) * 4.6566128730774e-10 -   1.0; // map to [-1, 1]
}

// smoothing kernel
float Wgrad(float r, float h){
    float alpha = 15.0 / (7.0 * PI * h * h);
	float q = r / h;
	if (q >= 2.0){
		return 0.0;
	} else {
		return alpha * (- (1.0/2.0) * (2.0-q) * (2.0-q));
    }
}

float convert_density_to_pressure(float density){
    return param.gas_constant * (density - param.rest_density);
}

// The code we want to execute in each invocation
void main() {
    int p_i = int(gl_GlobalInvocationID.x);
    
    // Initialize pressure force to zero
    pressure_force.pressure_force[p_i] = vec2(0.0, 0.0);
    
    float self_pressure = convert_density_to_pressure(density.density[p_i]);
    int particle_count = int(param.particle_num);
    for(int p_j = 0; p_j < particle_count; ++p_j){
        if(p_i == p_j) continue;
        float dst = length(position.position[p_j] - position.position[p_i]);
        float other_pressure = convert_density_to_pressure(density.density[p_j]);

        vec2 dir;
        if(dst == 0.0){
            // Random direction when particles overlap
            float rand1 = random(uint(p_i * 1000 + p_j));
            float rand2 = random(uint(p_j * 1000 + p_i));
            dir = normalize(vec2(rand1, rand2));
        } else {
            dir = (position.position[p_j] - position.position[p_i]) / dst;
        }
        
        float grad = Wgrad(dst, param.smoothing_length);
        float shared_pressure = (self_pressure + other_pressure) / 2.0;
        
        pressure_force.pressure_force[p_i] += shared_pressure * dir * grad * param.mass / density.density[p_j];
    }
}