module soba.core.gpu.gl;
import soba.core.gpu;
import soba.core.gpu.surface;
import soba.core.gpu.texture;
import bindbc.opengl;
import bindbc.sdl;
import soba.core.gpu.gl.surface;
import soba.core.gpu.gl.texture;
import imagefmt;

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

    /**
        Creates a new texture
    */
    override
    SbGPUTexture createTexture(int width, int height, SbGPUTextureFormat format) {
        return new SbGLTexture(this, width, height, format);
    }

    /**
        Creates a new texture
    */
    override
    SbGPUTexture createTexture(ref IFImage image) {
        return new SbGLTexture(this, image);
    }

    /**
        Creates a new texture
    */
    override
    SbGPUTexture createTexture(ubyte[] data, int width, int height, SbGPUTextureFormat format) {
        return new SbGLTexture(this, data, width, height, format);
    }
}