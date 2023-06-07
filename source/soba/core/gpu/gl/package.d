module soba.core.gpu.gl;
import soba.core.gpu;
import soba.core.gpu.surface;
import bindbc.opengl;
import bindbc.sdl;
import soba.core.gpu.gl.surface;

class SbGLContext : SbGPUContext {
protected:
    SDL_GLContext ctx;

    SbGPUCreationTargetI target;
    SbGPUSurface surface;

public:
    this() { }

    /**
        The type of GPU context
    */
    override
    SbGPUContextType getContextType() {
        return SbGPUContextType.OpenGL;
    }
    
    /**
        Setup function called for initial window creation
    
        Dummy function in WGPU
    */
    override
    void setupForTarget(SbGPUCreationTargetI target) {
        this.target = target;
        ctx = SDL_GL_CreateContext(target.getHandle());
        surface = new SbGLSurface(this, target);
    }
    
    /**
        Makes the context current. (OpenGL only)
    */
    override
    void makeCurrent() {
        SDL_GL_MakeCurrent(target.getHandle(), ctx);
    }

    /**
        Gets the target of the context
    */
    override
    ref SbGPUCreationTargetI getTarget() { return target; }

    /**
        Gets the target of the context
    */
    override
    ref SbGPUSurface getSurface() { return surface; }
}