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
import soba.ssk.effect;
import inmath.linalg;
import numem.all;
import soba.ssk.metal.ctx;

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
        Creates a context for a metal layer
    */
    static unique_ptr!SSKContext createForMetal(void* metallayer) {
        static if (SSKIsApplePlatform) {
            import metal : CAMetalLayer;
            return unique_ptr!SSKContext.fromPtr(nogc_new!SSKMetalContext(cast(CAMetalLayer)metallayer));
        } else {
            throw nogc_new!SSKNotAppleException();
        }
    }

    /**
        Creates a context for an active OpenGL context
    */
    static unique_ptr!SSKContext createForGL() {
        throw nogc_new!SSKNotImplementedException();
    }

    /**
        Creates a context for an active OpenGL ES context
    */
    static unique_ptr!SSKContext createForGLES() {
        throw nogc_new!SSKNotImplementedException();
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
        Sets the clear color of the context
    */
    abstract void setClearColor(vec4 clearColor);

    /**
        Gets the clear color of the context
    */
    abstract vec4 getClearColor();

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
        Sets the rendering source
    */
    abstract void setSource(SSKTexture texture);

    /**
        Gets the rendering source
    */
    abstract SSKTexture setSource();

    /**
        Sets the rendering target.

        Set to null to use the framebuffer as a target.
    */
    abstract void setTarget(SSKTexture texture);

    /**
        Gets the rendering target
    */
    abstract SSKTexture getTarget();

    /**
        Gets the type of the context
    */
    final
    SSKContextType getType() {
        return type;
    }
}