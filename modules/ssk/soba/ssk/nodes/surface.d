module soba.ssk.nodes.surface;

import soba.ssk.node;
import soba.ssk.ctx;
import numem.all;
import inmath.linalg;

/**
    Root node of the SSK render graph
*/
class SSKSurface : SSKNode {
@nogc:
public:
    this(SSKContext ctx) {
        super(ctx);
    }
}

