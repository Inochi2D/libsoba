/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Soba GPU is a abstraction layer to allow libsoba to work with various graphics APIs
    Current target support is OpenGL and WGPU, more graphics APIs may be added down the line.
*/
module soba.core.gpu;
import bindbc.sdl;
import soba.core.gpu.surface;
import soba.core.gpu.texture;
import soba.core.gpu.wgpu;
import soba.core.gpu.gl;
import imagefmt;

private {
    __gshared SbGPUContextType sbGlobalContextType;
}

/**
    Soba GPU context type
*/
enum SbGPUContextType : uint {

    /**
        Automatically determine the best context
    */
    Auto = 0,

    /**
        An OpenGL 3.1 context
    */
    OpenGL = 1,
    
    /**
        A WGPU-Native context
    */
    WebGPU = 2,

    /**
        The amount of supported contexts.
    */
    COUNT
}

SbGPUContextType sbGPUResolveContextType(SbGPUContextType type) {
    switch(type) {
        
        // TODO: Once more native backends are added, default to those based
        // on platform.
        case SbGPUContextType.Auto:
            return SbGPUContextType.WebGPU;
        
        // Explicit types will just return itself
        case SbGPUContextType.OpenGL:
        case SbGPUContextType.WebGPU:
            return type;
        
        default: throw new Exception("Invalid context type!");
    }
}

/**
    Interface implemented by targets that can be used to create a soba context
*/
interface SbGPUCreationTargetI {
public:

    /**
        Whether the creation target already has a valid context
    */
    bool hasContext();
    
    /**
        The GPU context of the target
    */
    ref SbGPUContext gpuContext();

    /**
        Gets handle of the creation target
    */
    SDL_Window* getHandle();
}

/**
    A generic Soba GPU context

    Use getContextType() together with casting to get access to lower level functionality of the context.

    setupForApp is called for graphics APIs which has a top level context independent of a surface
    setupForTarget is called for graphics APIs which has a top level context dependent on a surface (OpenGL)
*/
abstract class SbGPUContext {
public:
    this() { }

    /**
        The type of GPU context
    */
    abstract SbGPUContextType getContextType();
    
    /**
        Setup function called for initial window creation
    */
    abstract void setupForTarget(SbGPUCreationTargetI target);

    /**
        Make context current. (OpenGL only)
    */
    abstract void makeCurrent();

    /**
        Gets the target of the context
    */
    abstract ref SbGPUCreationTargetI getTarget();

    /**
        Gets the surface associated with the GPU context
    */
    abstract ref SbGPUSurface getSurface();

    /**
        Creates a new texture
    */
    abstract SbGPUTexture createTexture(int width, int height, SbGPUTextureFormat format);

    /**
        Creates a new texture
    */
    abstract SbGPUTexture createTexture(ref IFImage image);

    /**
        Creates a new texture
    */
    abstract SbGPUTexture createTexture(ubyte[] data, int width, int height, SbGPUTextureFormat format);
}

/**
    Creates a new Soba GPU Context
*/
SbGPUContext sbGPUNewContext(SbGPUCreationTargetI target, SbGPUContextType contextType) {
    SbGPUContext ctx;
    switch(contextType) {
        case SbGPUContextType.WebGPU:
            ctx = new SbWGPUContext();
            break;
        
        case SbGPUContextType.OpenGL:
            ctx = new SbGLContext();
            break;

        // NOTE: OpenGL has no app-level init
        default: throw new Exception("Graphics API not supported!");
    }
    ctx.setupForTarget(target);
    return ctx;
}

/**
    Initialize connection to graphics apis
*/
void sbGPUInit(SbGPUContextType contextType) {
    sbGlobalContextType = contextType;

    switch(contextType) {
        case SbGPUContextType.WebGPU:
            sbWGPUInit();
            return;
        
        // NOTE: OpenGL has no app-level init
        default: return;
    }
}

SbGPUContextType sbGPUGetGlobalContextType() {
    return sbGlobalContextType;
}

SDL_Window* sbGPUCreateCompatibleSDLWindow(const(char)* title, int width, int height, uint windowFlags, SbGPUContextType contextType) {
    switch(contextType) {
        case SbGPUContextType.OpenGL:

            // OpenGL Core 3.1
            SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );
            SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, 3);
            SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, 1);
            windowFlags |= SDL_WINDOW_OPENGL;
            break;

        case SbGPUContextType.WebGPU:
            break;
        
        default: throw new Exception("Context type not supported by window!");
    }
    
    return SDL_CreateWindow(
        title, 
        SDL_WINDOWPOS_UNDEFINED, 
        SDL_WINDOWPOS_UNDEFINED,
        width,
        height,
        windowFlags
    );
}