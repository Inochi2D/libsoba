module soba.core.gpu.gl.fbo;
import soba.core.gpu.gl.target;
import soba.core.gpu.gl.texture;
import soba.core.gpu.target;
import soba.core.gpu.texture;
import soba.core.gpu.fbo;
import soba.core.gpu.gl;
import bindbc.opengl;

/**
    A OpenGL framebuffer
*/
class SbGLFramebuffer : SbGPUFramebuffer {
private:
    SbGLContext context;
    GLuint framebufferId;

public:
    /// Constructor
    this(SbGLContext context) {
        this.context = context;

        // Create framebuffer
        glGenFramebuffers(1, &framebufferId);
    }

    /**
        Adds a target to the framebuffer
    */
    override
    void addTarget(SbGPUTexture target) {
        super.addTarget(target);

        if (SbGLTexture glTarget = cast(SbGLTexture)target) {
            
            // Determine the attachment point
            GLuint attachmentType = GL_COLOR_ATTACHMENT0;
            if (glTarget.getFormat() == SbGPUTextureFormat.DepthStencil) {
                attachmentType = GL_DEPTH_STENCIL_ATTACHMENT;
            }

            glBindFramebuffer(GL_FRAMEBUFFER, framebufferId);
            glBindTexture(GL_TEXTURE_2D, glTarget.getId());
            glFramebufferTexture2D(GL_FRAMEBUFFER, attachmentType, GL_TEXTURE_2D, glTarget.getId(), 0);

            // Unbind to ensure state is not messed up
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
    }

    /**
        Gets the framebuffer ID
    */
    GLuint getId() {
        return framebufferId;
    }
}