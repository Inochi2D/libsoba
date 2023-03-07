/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Shaders
*/
module soba.core.gpu.shader;
import soba.core.gpu;
import bindbc.wgpu;
import std.string;

class SbShader {
private:
    WGPUShaderModuleDescriptor desc;
    WGPUShaderModule mod;
    this() { }

package(soba.core.gpu):
    static SbShader createSPIRV(SbGPUContext ctx, ubyte[] code, string name=null) {
        SbShader shader = new SbShader;

        // Lang Descriptor
        WGPUShaderModuleSPIRVDescriptor shaderDesc;
        shaderDesc.code = cast(uint*)code.ptr;
        shaderDesc.codeSize = cast(uint)code.length;
        shaderDesc.chain.sType = WGPUSType.ShaderModuleSPIRVDescriptor;

        // Shader Descriptor
        WGPUShaderModuleDescriptor desc;
        desc.label = name.toStringz;
        desc.nextInChain = cast(const(WGPUChainedStruct)*)&shaderDesc;

        shader.mod = wgpuDeviceCreateShaderModule(ctx.getDevice(), &desc);
        shader.desc = desc;
        return shader;
    }

    static SbShader createWGSL(SbGPUContext ctx, string source, string name=null) {
        SbShader shader = new SbShader;
        
        // Lang Descriptor
        WGPUShaderModuleWGSLDescriptor shaderDesc;
        shaderDesc.code = source.ptr;
        shaderDesc.chain.sType = WGPUSType.ShaderModuleWGSLDescriptor;

        // Shader Descriptor
        WGPUShaderModuleDescriptor desc;
        desc.label = name.toStringz;
        desc.nextInChain = cast(const(WGPUChainedStruct)*)&shaderDesc;

        shader.mod = wgpuDeviceCreateShaderModule(ctx.getDevice(), &desc);
        shader.desc = desc;
        return shader;
    }

public:

    /// Destructor
    ~this() {
        wgpuShaderModuleDrop(mod);
    }

    /**
        Gets the underlying WGPU Shader Module
    */
    WGPUShaderModule getNative() {
        return mod;
    }
}