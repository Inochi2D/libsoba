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

class SbGFXShader {
private:
    WGPUShaderModuleDescriptor desc;
    WGPUShaderModule mod;

    // SbDynamicBuffer uniforms;
    this() { }
    
public:
    /**
        Constructs a SPIR-V Shader
    */
    this(SbGFXContext ctx, ubyte[] code, string name=null) {
        SbGFXShader shader = new SbGFXShader;

        // Lang Descriptor
        WGPUShaderModuleSPIRVDescriptor shaderDesc;
        shaderDesc.code = cast(uint*)code.ptr;
        shaderDesc.codeSize = cast(uint)code.length;
        shaderDesc.chain.sType = WGPUSType.ShaderModuleSPIRVDescriptor;

        // Shader Descriptor
        WGPUShaderModuleDescriptor desc;
        desc.label = name.toStringz;
        desc.nextInChain = cast(const(WGPUChainedStruct)*)&shaderDesc;

        this.mod = wgpuDeviceCreateShaderModule(ctx.getDevice(), &desc);
        this.desc = desc;
    }

    /**
        Constructs a WGSL Shader
    */
    this(SbGFXContext ctx, string source, string name=null) {
        SbGFXShader shader = new SbGFXShader;
        
        // Lang Descriptor
        WGPUShaderModuleWGSLDescriptor shaderDesc;
        shaderDesc.code = source.ptr;
        shaderDesc.chain.sType = WGPUSType.ShaderModuleWGSLDescriptor;

        // Shader Descriptor
        WGPUShaderModuleDescriptor desc;
        desc.label = name.toStringz;
        desc.nextInChain = cast(const(WGPUChainedStruct)*)&shaderDesc;

        this.mod = mod = wgpuDeviceCreateShaderModule(ctx.getDevice(), &desc);
        this.desc = desc;
    }

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