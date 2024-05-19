/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.canvas.effect;
import soba.canvas.canvas;
import numem.all;
import inmath;

/**
    A graphical effect applied to a surface
*/
abstract
class SbEffect {
nothrow @nogc:
private:
public:
    abstract void apply(ref SbCanvas canvas, recti clipArea=recti(-1, -1, -1, -1));
}