module soba.core.gpu.gl.command;
import soba.core.gpu.gl.target;
import soba.core.gpu.gl.shader;
import soba.core.gpu.gl;
import soba.core.gpu.command;
import soba.core.gpu.target;
import soba.core.gpu.shader;
import bindbc.opengl;

class SbGLCommandBuffer : SbGPUCommandBuffer {
private:
    SbGLContext context;

    // ENCODER
    bool recording = false;

    // RENDER PASS
    bool passRecording = false;
    bool passScissor;
    SbGLRenderTarget passTarget;
    SbGLShaderObject passBoundShader;

public:
    /// Constructor
    this(SbGLContext context) {
        this.context = context;
    }

    override
    void beginFrame() {
        if (recording) return;
        recording = true;
    }

    /**
        Clears the render target

        NOTE: Can only be called outside of a renderpass
    */
    override
    void clear(SbGPURenderTarget target) {
        if (passRecording) return;
        auto rt = (cast(SbGLRenderTarget)target);

        if (rt.getId() == 0) {
            (cast(SbGLRenderTarget)target).bind();
            glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
        } else {
            (cast(SbGLRenderTarget)target).bind();
            glClear(GL_COLOR_BUFFER_BIT);
        }
    }

    /**
        Starts a render pass for the command buffer
    */
    override
    void beginPass(SbGPURenderTarget target, bool clear=true, bool scissor=false) {
        if (passRecording) return;
        passRecording = true;

        passScissor = scissor;
        passTarget = cast(SbGLRenderTarget)target;

        // NOTE: To ensure common behaviour between WGPU and OpenGL
        //       We will not clear if scissor testing is enabled.
        passTarget.bind();
        if (clear && !scissor) {
            if (passTarget.getId() == 0) {
                glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
            } else {
                glClear(GL_COLOR_BUFFER_BIT);
            }
        }

        glViewport(0, 0, target.getWidthPx(), target.getHeightPx());

        // Scissor test
        if (scissor) {
            glEnable(GL_SCISSOR_TEST);
            glScissor(0, 0, target.getWidthPx(), target.getHeightPx());
        } else {
            glDisable(GL_SCISSOR_TEST);
        }
    }
    

    /**
        Sets the viewport of the current pass
    */
    override
    void setViewport(float x, float y, float width, float height) {
        if (!passRecording) return;
        glViewport(cast(int)x, cast(int)y, cast(int)width, cast(int)height);
    }

    /**
        Sets the scissor rect of the current pass
    */
    override
    void setScissorRect(float x, float y, float width, float height) {
        if (!passRecording) return;
        if (passScissor) glScissor(cast(int)x, cast(int)(passTarget.getHeightPx()-y), cast(int)width, cast(int)height);
    }

    /**
        Binds a shader to the current pass
    */
    override
    void bindShader(SbGPUShaderObject shader) {
        if (!passRecording) return;
    }
    
    /**
        Ends a render pass for the command buffer
    */
    override
    void endPass() {
        if (!passRecording) return;
        passRecording = false;
    }

    /**
        Ends the current frame.
    */
    override
    void endFrame() {
        if (!recording) return;
        recording = false;
    }
}