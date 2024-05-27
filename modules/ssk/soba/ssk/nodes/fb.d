module soba.ssk.nodes.fb;

import soba.ssk.node;
import soba.ssk.ctx;
import numem.all;
import inmath.linalg;
import soba.ssk;

enum SSKFramebufferType {

    /**
        A OpenGL framebuffer
    */
    opengl,

    /**
        A Metal framebuffer

        This will cause an exception on non-apple platforms.
    */
    metal,

    /**
        RESERVED
    */
    gles
}

/**
    A framebuffer that the specified backing rendering context can draw to.
*/
class SSKFramebuffer : SSKNode {
@nogc:
private:
    SSKFramebufferType type;
    void* gpuctx;

public:

    this(SSKContext ctx, SSKFramebufferType type) {
        super(ctx);
        
        final switch(type) {
            case SSKFramebufferType.opengl:
                this.type = type;
                break;
            
            case SSKFramebufferType.metal:
                static if (SSKIsApplePlatform) {
                    this.type = type;
                    break;
                } else {

                    // Not apple
                    throw nogc_new!SSKNotAppleException();
                }
            
            case SSKFramebufferType.gles:
                throw nogc_new!SSKNotImplementedException();
        }
    }

    /**
        Returns a handle to the context
    */
    void* getHandle() {
        return gpuctx;
    }
}



