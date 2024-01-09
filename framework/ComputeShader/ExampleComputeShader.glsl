#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 2, local_size_y = 1, local_size_z = 1) in;

// A binding to the buffer we create in our script
layout(set = 0, binding = 0, std430) restrict buffer DataBuffer { float data[]; } data_buffer;

layout(set = 0, binding = 1) uniform sampler2D tex;

// The code we want to execute in each invocation
void main() {
    // gl_GlobalInvocationID.x uniquely identifies this invocation across all work groups
    data_buffer.data[gl_GlobalInvocationID.x] *= 2.0;
}