/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Soba Scene Kit Context
*/
module soba.ssk.ctx;
import soba.ssk.ex;
import soba.ssk.appl;
import soba.ssk.node;
import inmath.linalg;
import numem.all;

@nogc:

/**
    Type enumerator for the type of an SSKContext
*/
enum SSKContextType {

    /**
        OpenGL context
    */
    opengl,

    /**
        Metal context
    */
    metal,

    /**
        RESERVED: OpenGL ES

        Not implemneted!
    */
    gles
}

/**
    A Soba Scene Kit context

    SSKContexts own the memory of all scene composition subtypes.
*/
abstract
class SSKContext {
nothrow @nogc:
private:
    SSKContextType type;

public:
    this(SSKContextType type) {
        this.type = type;
    }

    /**
        Returns the backing handle of a context
    */
    abstract void* getHandle();

    /**
        Sets the rendering viewport of the context
    */
    abstract void setViewport(recti viewport);

    /**
        Gets the rendering viewport of the context
    */
    abstract recti getViewport();

    /**
        Sets the scissor rectangle of the context
    */
    abstract void setScissor(recti scissorRect);

    /**
        Gets the scissor rectangle of the context
    */
    abstract recti getScissor();

    /**
        Sets the clear color of the context
    */
    abstract void setClearColor(vec4 clearColor);

    /**
        Gets the clear color of the context
    */
    abstract recti getClearColor();

    /**
        Enqueue the node for rendering
    */
    abstract void enqueue(SSKNode node);

    /**
        Flushes the context, rendering everything to the logical surface.
    */
    abstract void flush();

    /**
        Awaits the completion of the enqueued tasks, blocking the thread.
    */
    abstract void await();

    /**
        Gets the type of the context
    */
    final
    SSKContextType getType() {
        return type;
    }
}



extern(C) SSKContext sskContextCreateForMetal(void* mtllayer) {
    static if (SSKIsApplePlatform) {

    } else {

        // Not apple
        throw nogc_new!SSKNotAppleException();
    }
}

extern(C) SSKContext sskContextCreateForOpenGL() {
    return null;
}

extern(C) SSKContext sskContextCreateForOpenGLES() {

    // Not implemented
    throw nogc_new!SSKNotImplementedException();
}