module soba.core.gpu.command;
import soba.core.gpu.target;

/**
    A command buffer
*/
abstract class SbGPUCommandBuffer {
public:
    /**
        Starts a frame for the command buffer
    */
    abstract void beginFrame();

    /**
        Starts a render pass for the command buffer
    */
    abstract void beginPass(SbGPURenderTarget target);
    
    /**
        Ends a render pass for the command buffer
    */
    abstract void endPass();

    /**
        Ends a frame for the command buffer
    */
    abstract void endFrame();
}