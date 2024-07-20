/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module soba.ssk.scene;
import soba.sio;
import soba.ssk.renderers;
import soba.ssk.surfaces;
import numem.all;

/**
    The "scene" being drawn to
*/
final
class SskScene {
@nogc:
private:
    SioWindow window;
    SskSurface root;
    SskRenderer renderer;

    weak_vector!SskSurface enqueued;

package(soba.ssk):

    /**
        INTERNAL API

        Enqueues a surface for rendering
        This function assumes the surface belongs to this scene

        If you're an end user you're looking for SskSurface.redraw()
    */
    void enqueue(SskSurface surface) {

        // First check if we have a parent of this surface already enqueued
        SskSurface p = surface;
        while(p) {

            foreach(qsurface; enqueued) {
                if (surface is qsurface) return;
            }

            p = p.getParent();
        }

        enqueued ~= surface;
    }

public:

    ~this() {
        nogc_delete(root);
    }

    /**
        Creates a new scene for a window
    */
    this(SioWindow window) {
        this.window = window;
        this.renderer = sskCreateRendererFor(window);
    }

    /**
        Gets the root surface
    */
    SskSurface getRoot() {
        return root;
    }

    /**
        Gets the renderer for this scene
    */
    SskRenderer getRenderer() {
        return renderer;
    }

    /**
        Redraws dirty parts of the scene
    */
    void redraw() {
        root.renderAll();
    }
}