module soba.core.gpu.fbo;
import soba.core.gpu.target;
import soba.core.gpu.texture;
import std.exception;

class SbGPUFramebuffer {
private:
    SbGPUTexture[] targets;

public:

    /**
        Adds a target to the framebuffer
    */
    void addTarget(SbGPUTexture target) {
        if (targets.length == 0) {
            targets ~= target;
            return;
        }

        enforce(
            target.getWidthPx() == targets[0].getWidthPx() && 
            target.getHeightPx() == targets[0].getHeightPx(),
            "Target size mismatch!"    
        );
    }

    /**
        Gets the targets of the framebuffer
    */
    SbGPUTexture[] getTargets() {
        return targets;
    }

    /**
        Gets the framebuffer width in pixels
    */
    uint getWidthPx() {
        return targets.length > 0 ? targets[0].getWidthPx() : 0;
    }
    
    /**
        Gets the framebuffer height in pixels
    */
    uint getHeightPx() {
        return targets.length > 0 ? targets[0].getHeightPx() : 0;
    }
}