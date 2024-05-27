/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Soba Scene Kit Effects
*/
module soba.ssk.effect;


/**
    Effects which can be applied to the rendering of SSKNodes

    SSKNodes do *not* own effects applied to them, remember to free them after use.
*/
abstract
class SSKEffect {
@nogc:

    /**
        Returns the handle of the effect.
    */
    abstract void* getHandle();
}
