module soba.core.gpu.gl;
import soba.core.gpu;
import soba.core.gpu.surface;
import soba.core.gpu.texture;
import soba.core.gpu.buffer;
import soba.core.gpu.shader;
import bindbc.opengl;
import bindbc.sdl;
import soba.core.gpu.gl.surface;
import soba.core.gpu.gl.texture;
import soba.core.gpu.gl.buffer;
import imagefmt;
import soba.core.gpu.gl.shader;

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
    
    
    /**
        Creates a new index buffer
    */
    override
    SbGPUBuffer createIndexBuffer(size_t size) {
        return new SbGLBuffer(this, SbGPUBufferType.Index, size);
    }

    /**
        Creates a new index buffer
    */
    override
    SbGPUBuffer createIndexBuffer(void* initialData, size_t length) {
        return new SbGLBuffer(this, SbGPUBufferType.Index, initialData, length);
    }

    /**
        Creates a new vertex buffer
    */
    override
    SbGPUBuffer createVertexBuffer(size_t size) {
        return new SbGLBuffer(this, SbGPUBufferType.Vertex, size);
    }

    /**
        Creates a new vertex buffer
    */
    override
    SbGPUBuffer createVertexBuffer(void* initialData, size_t length) {
        return new SbGLBuffer(this, SbGPUBufferType.Vertex, initialData, length);
    }

    /**
        Creates a new uniform buffer
    */
    override
    SbGPUBuffer createUniformBuffer(size_t size) {
        return new SbGLBuffer(this, SbGPUBufferType.Uniform, size);
    }

    /**
        Creates a new uniform buffer
    */
    override
    SbGPUBuffer createUniformBuffer(void* initialData, size_t length) {
        return new SbGLBuffer(this, SbGPUBufferType.Uniform, initialData, length);
    }
    
    /**
        Creates a new shader object with the specified variants.
    */
    override
    SbGPUShaderObject createShader(SbGPUShaderCodeVariant[] variants) {
        return new SbGLShaderObject(this, variants);
    }
}