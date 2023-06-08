module soba.core.gpu.wgpu.shader;
import soba.core.gpu.wgpu;
import soba.core.gpu.shader;
import bindbc.wgpu;
import std.exception;
import std.string;

class SbWGPUShaderObject : SbGPUShaderObject {
private:
    SbWGPUContext context;

    WGPUShaderModuleDescriptor shaderDescriptor;
    WGPUShaderModule shader;

    WGPURenderPipeline pipeline;
    WGPUBindGroup[] bindGroups;

    SbGPUShaderCodeVariant findWGPUShader(SbGPUShaderCodeVariant[] variants) {
        SbGPUShaderCodeVariant* tmpshader;

        foreach(ref variant; variants) {
            if (variant.backend == context.getContextType()) {
                enforce(variant.stage == SbGPUShaderStageFlags.MultiStage, "Only multi-stage supported for WGPU");
                tmpshader = &variant;
            }
        }

        enforce(tmpshader, "No WGPU-compatible shaders found!");
        return *tmpshader;
    }

    void createSPIRVShader(SbGPUShaderCodeVariant variant) {
        
        // Lang Descriptor
        WGPUShaderModuleSPIRVDescriptor shaderDesc;
        shaderDesc.code = cast(uint*)variant.bytecode.ptr;
        shaderDesc.codeSize = cast(uint)variant.bytecode.length;
        shaderDesc.chain.sType = WGPUSType.ShaderModuleSPIRVDescriptor;

        // Shader Descriptor
        WGPUShaderModuleDescriptor desc;
        desc.label = "SPIR-V Shader";
        desc.nextInChain = cast(const(WGPUChainedStruct)*)&shaderDesc;

        this.shader = wgpuDeviceCreateShaderModule(context.getDevice(), &desc);
        this.shaderDescriptor = desc;
    }

    void createWSGLShader(SbGPUShaderCodeVariant variant) {

        // Lang Descriptor
        WGPUShaderModuleWGSLDescriptor shaderDesc;
        shaderDesc.code = variant.code.toStringz;
        shaderDesc.chain.sType = WGPUSType.ShaderModuleWGSLDescriptor;

        // Shader Descriptor
        WGPUShaderModuleDescriptor desc;
        desc.label = "WSGL Shader";
        desc.nextInChain = cast(const(WGPUChainedStruct)*)&shaderDesc;

        this.shader = wgpuDeviceCreateShaderModule(context.getDevice(), &desc);
        this.shaderDescriptor = desc;
    }

public:
    this(SbWGPUContext context, SbGPUShaderCodeVariant[] variants) {
        this.context = context;

        // Create shader from WSGL or SPIR-V
        SbGPUShaderCodeVariant variant = findWGPUShader(variants);
        if (variant.isBytecode) createSPIRVShader(variant);
        else createWSGLShader(variant);
    }

    /**
        Gets the underlying WGPU Shader Module
    */
    WGPUShaderModule getProgram() {
        return shader;
    }
    
    /**
        Gets whether the shader program is complete
    */
    override
    bool isComplete() {
        return shader !is null;
    }
}