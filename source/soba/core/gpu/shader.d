/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    A Shader
*/
module soba.core.gpu.shader;
import soba.core.gpu;
import soba.core.gpu.texture;
import soba.core.gpu.buffer;

/**
    Flags determining which shader stages
    A bind group applies for
*/
enum SbGPUShaderStageFlags {

    /**
        Vertex shader
    */
    Vertex,
    
    /**
        Fragment shader
    */
    Fragment,

    /**
        Both vertex and fragment shader
    */
    MultiStage,
}

/**
    The type of an entry
*/
enum SbGPUBindGroupEntryType {
    /**
        A texture

        NOTE: A texture will automatically take up 2 binding slots,
              one for the sampler, one for the view
    */
    Texture,

    /**
        A buffer
    */
    Buffer
}

struct SbGPUBindGroupLayoutEntry {
    /**
        The binding point of the entry
    */
    uint binding;
    
    /**
        The type of the entry
    */
    SbGPUBindGroupEntryType type;

    /**
        If the entry is a buffer, determines the type of the buffer
    */
    SbGPUBufferType bufferType;
}

/**
    A shader code variant
*/
struct SbGPUShaderCodeVariant {

    /**
        Backend that the shader is meant for
    */
    SbGPUContextType backend;

    /**
        Stage the shader applies to
    */
    SbGPUShaderStageFlags stage;

    /**
        Whether the shader is bytecode, generally for now this
        value should be left as false.
    */
    bool isBytecode;

    union {
    
        /**
            Source code of shader in GLSL or WSGL format

            NOTE: For MultiStage shader variants there should be 2 entry points
                  Vertex shader entry point should be called `vs_main`
                  Fragment shader entry point should be called `fs_main`

            NOTE: For WSGL a @fragment and @vertex attribute needs to be
                  applied to the entry points.
        */
        string code;
    
        /**
            Bytecode of shader in DXIL, SPIR-V or MSL format

            NOTE: For MultiStage shader variants there should be 2 entry points
                  Vertex shader entry point should be called `vs_main`
                  Fragment shader entry point should be called `fs_main`
            
            NOTE: Currently unused.
        */
        ubyte[] bytecode;
    }
}

abstract class SbGPUShaderObject {
public:

    /**
        Gets whether the shader object is complete
    */
    abstract bool isComplete();
}