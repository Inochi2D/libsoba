/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    GPU Context
*/
module soba.core.gpu;
public import soba.core.gpu.buffer;
public import soba.core.gpu.shader;

import bindbc.wgpu;
import std.exception;
import std.conv;
import soba.core.gpu.surface;

private {
    extern(C)
    void sbGPUCtxAdapterCallback(WGPURequestAdapterStatus status, WGPUAdapter adapter, const(char)* message, void* userdata) {
        enforce(status == WGPURequestAdapterStatus.Success, message.text);
        *cast(WGPUAdapter*)userdata = adapter;
    }

    extern(C)
    void sbGPUCtxDeviceCallback(WGPURequestDeviceStatus status, WGPUDevice device, const(char)* message, void* userdata) {
        enforce(status == WGPURequestDeviceStatus.Success, message.text);
        *cast(WGPUDevice*)userdata = device;
    }
}

class SbGPUContext {
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
        WGPURequiredLimits limits;
        WGPUDeviceDescriptor deviceDesc;

        // 4096x4096 Texture atlasses needs to be supported AT LEAST
        limits.limits.maxTextureDimension2D = 4096;
        deviceDesc.requiredLimits = &limits;

        // Send request
        wgpuAdapterRequestDevice(adptr, &deviceDesc, &sbGPUCtxDeviceCallback, cast(void*)&dvc);
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

    /**
        Creates a SPIR-V Shader
    */
    SbShader createShaderSPIRV(ubyte[] code, string name=null) {
        return SbShader.createSPIRV(this, code, name);
    }

    /**
        Creates a WSGL Shader
    */
    SbShader createShaderWSGL(string source, string name=null) {
        return SbShader.createWGSL(this, source, name);
    }

    /**
        Creates a vertex buffer
    */
    SbBuffer createVertexBuffer(const(void)* data, size_t size, string name=null) {
        auto buffer = SbBuffer.createVertex(this, size, name);
        buffer.bufferData(data, size, 0);
        return buffer;
    }

    /**
        Creates a vertex buffer
    */
    SbBuffer createVertexBuffer(size_t size, string name=null) {
        return SbBuffer.createVertex(this, size, name);
    }

    /**
        Creates a index buffer
    */
    SbBuffer createIndexBuffer(const(void)* data, size_t size, string name=null) {
        auto buffer = SbBuffer.createIndex(this, size, name);
        buffer.bufferData(data, size, 0);
        return buffer;
    }

    /**
        Creates a index buffer
    */
    SbBuffer createIndexBuffer(size_t size, string name=null) {
        return SbBuffer.createIndex(this, size, name);
    }
}




// class SbCommandEncoder {
// private:
//     SbGPUContext ctx;
//     WGPUCommandEncoder encoder;

//     static SbCommandEncoder create(SbGPUContext ctx) {
//         this.ctx = ctx;

//         WGPUCommandEncoderDescriptor desc;
//         desc.label = "Command Encoder";
//         encoder = wgpuDeviceCreateCommandEncoder(ctx.device, &desc);
//     }

// public:

//     SbRenderPass beginRenderPass() {
//         wgpuCommandEncoderBeginRenderPass(encoder, null);
//         // wgpuCommandEncoderBeginRenderPass(encoder, );
//     }

// }

// class SbRenderPass {
// private:
//     SbGPUContext ctx;
//     WGPURenderPassEncoder pass;

// public:


// }