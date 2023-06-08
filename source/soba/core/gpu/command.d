module soba.core.gpu.command;
import soba.core.gpu.target;
import inmath;
import soba.core.gpu.shader;

/**
    A command buffer
*/
abstract class SbGPUCommandBuffer {
protected:
    vec4 clearColor;

public:
    /**
        Sets the clear color for the command buffer
    */
    void setClearColor(float r, float g, float b, float a) {
        clearColor = vec4(r, g, b, a);
    }

    /**
        Clears the render target

        NOTE: Can only be called outside of a renderpass
    */
    abstract void clear(SbGPURenderTarget target);

    /**
        Starts a frame for the command buffer
    */
    abstract void beginFrame();

    /**
        Starts a render pass for the command buffer
    */
    abstract void beginPass(SbGPURenderTarget target, bool clear=true, bool scissor=false);

    /**
        Sets the viewport of the current pass
    */
    abstract void setViewport(float x, float y, float width, float height);

    /**
        Sets the scissor rect of the current pass
    */
    abstract void setScissorRect(float x, float y, float width, float height);

    /**
        Binds a shader in the current pass
    */
    abstract void bindShader(SbGPUShaderObject shader);
    
    /**
        Ends a render pass for the command buffer
    */
    abstract void endPass();

    /**
        Ends a frame for the command buffer
    */
    abstract void endFrame();
}