/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    GPU Context
*/
module soba.core.gpu;
public import soba.core.gpu.buffer;
public import soba.core.gpu.shader;
public import soba.core.gpu.surface;
public import soba.core.gpu.encoder;

import bindbc.wgpu;
import std.exception;
import std.conv;
import soba.core.gpu.surface;

private {
    extern(C)
    void sbGPUCtxAdapterCallback(WGPURequestAdapterStatus status, WGPUAdapter adapter, const(char)* message, void* userdata) {
        *cast(WGPUAdapter*)userdata = adapter;
    }

    extern(C)
    void sbGPUCtxDeviceCallback(WGPURequestDeviceStatus status, WGPUDevice device, const(char)* message, void* userdata) {
        *cast(WGPUDevice*)userdata = device;
    }
}

class SbGFXContext {
private:
    WGPUInstance instance;
    WGPUAdapter adapter;
    WGPUDevice device;

    WGPUQueue queue;


    WGPUAdapter createAdapter(WGPUInstance instance) {
        WGPUAdapter adptr;
        
        // Request options
        WGPURequestAdapterOptions options;
        options.powerPreference = WGPUPowerPreference.LowPower;

        // Send request
        wgpuInstanceRequestAdapter(instance, &options, &sbGPUCtxAdapterCallback, &adptr);
        return adptr;
    }
    
    WGPUDevice createDeviceForAdapter(WGPUAdapter adptr) {
        WGPUDevice dvc;
        WGPUDeviceDescriptor deviceDesc;

        // WGPU limits list is pretty long...
        WGPURequiredLimits limits;
        limits.limits.maxTextureDimension1D = 2048;
        limits.limits.maxTextureDimension2D = 2048;
        limits.limits.maxTextureDimension3D = 256;
        limits.limits.maxTextureArrayLayers = 256;
        limits.limits.maxBindGroups = 4;
        limits.limits.maxBindingsPerBindGroup = 640;
        limits.limits.maxDynamicUniformBuffersPerPipelineLayout = 8;
        limits.limits.maxDynamicStorageBuffersPerPipelineLayout = 4;
        limits.limits.maxSampledTexturesPerShaderStage = 16;
        limits.limits.maxSamplersPerShaderStage = 16;
        limits.limits.maxStorageBuffersPerShaderStage = 4;
        limits.limits.maxStorageTexturesPerShaderStage = 4;
        limits.limits.maxUniformBuffersPerShaderStage = 12;
        limits.limits.maxUniformBufferBindingSize = 16 << 10;
        limits.limits.maxStorageBufferBindingSize = 128 << 20;
        limits.limits.maxVertexBuffers = 8;
        limits.limits.maxVertexAttributes = 16;
        limits.limits.maxVertexBufferArrayStride = 2048;
        limits.limits.minUniformBufferOffsetAlignment = 256;
        limits.limits.minStorageBufferOffsetAlignment = 256;
        limits.limits.maxInterStageShaderComponents = 60;
        limits.limits.maxComputeWorkgroupStorageSize = 16352;
        limits.limits.maxComputeInvocationsPerWorkgroup = 256;
        limits.limits.maxComputeWorkgroupSizeX = 256;
        limits.limits.maxComputeWorkgroupSizeY = 256;
        limits.limits.maxComputeWorkgroupSizeZ = 64;
        limits.limits.maxComputeWorkgroupsPerDimension = 65535;
        limits.limits.maxBufferSize = 1 << 28;
        deviceDesc.requiredLimits = &limits;

        // Send request
        wgpuAdapterRequestDevice(adptr, &deviceDesc, &sbGPUCtxDeviceCallback, &dvc);
        return dvc;
    }

package(soba.core.gpu):
    WGPUInstance getInstance() { return instance; }
    WGPUAdapter getAdapter() { return adapter; }
    WGPUDevice getDevice() { return device; }
    WGPUQueue getQueue() { return queue; }

public:

    /// Destructor
    ~this() {

        // Drop WGPU resources
        wgpuDeviceDrop(device);
        wgpuAdapterDrop(adapter);
        wgpuInstanceDrop(instance);
    }

    /// Constructor
    this() {
        WGPUInstanceDescriptor desc;
        instance = wgpuCreateInstance(&desc);
        adapter = createAdapter(instance);
        device = createDeviceForAdapter(adapter);
        queue = wgpuDeviceGetQueue(device);
    }
}

/**
    A usable rendering source
*/
abstract class SbGFXRenderSource {

    /**
        Gets a view in to the rendering source
    */
    abstract WGPUTextureView currentTexture();

    /**
        Drops the render source backing texture if needed
    */
    abstract void dropIfNeeded();
}