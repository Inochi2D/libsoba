/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Soba Scene Kit Effects
*/
module soba.ssk.effect;

import soba.ssk.ctx;


/**
    Effects which can be applied to the rendering of SSKNodes

    SSKNodes do *not* own effects applied to them, remember to free them after use.
*/
abstract
class SSKEffect {
protected:
    SSKContext ctx;

@nogc:
    this(SSKContext ctx) {
        this.ctx = ctx;
    }

    /**
        Returns the handle of the effect.
    */
    abstract void* getHandle();
}
