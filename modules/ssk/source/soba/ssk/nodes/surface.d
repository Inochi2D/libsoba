module soba.ssk.nodes.surface;

import soba.ssk.node;
import soba.ssk.ctx;
import soba.ssk.texture;
import numem.all;
import inmath.linalg;

/**
    A drawable surface in the SSK render graph
*/
class SSKSurface : SSKNode {
@nogc:
private:
    SSKTexture backingTexture;

public:
    /**
        Constructor
    */
    this(SSKContext ctx, SSKTexture backingTexture) {
        super(ctx);
        this.backingTexture = backingTexture;
    }

    /**
        Gets the backing texture of the surface
    */
    final
    SSKTexture getBacking() {
        return backingTexture;
    }

    /**
        Resizes the surface

        This will destroy the contents of the surface.
    */
    void resize(uint width, uint height) {
        this.backingTexture.resize(width, height);
        this.getContext().enqueue(this);

        recti bounds = getBounds();
        bounds.width = width;
        bounds.height = height;
        this.setBounds(bounds);
    }
}

