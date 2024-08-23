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
import inmath;

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

    size_t dirtyElements;

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

    /// Tells the scene that another dirty element has been added.
    /// This is used for skipping redraws when no elements have changed.
    void addDirty() {
        dirtyElements++;
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

        this.root = nogc_new!SskSurface(this);
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
        Gets the horizontal and vertical scaling for this scene
    */
    vec2 getScaling() {
        if (!window) return vec2(1, 1);
        
        vec2 pointSize = window.getWindowSize();
        vec2 fbSize = window.getFramebufferSize();
        return vec2(cast(float)fbSize.x/cast(float)pointSize.x, cast(float)fbSize.y/cast(float)pointSize.y);
    }

    /**
        Redraws dirty parts of the scene
    */
    void redraw() {
        if (dirtyElements > 0) {
            vec2i fbSize = window.getFramebufferSize();
            root.setBounds(recti(
                0, 
                0,
                fbSize.x,
                fbSize.y
            ));

            renderer.begin();
                root.renderAll(renderer);
            renderer.end();

            window.swap();
        }

        dirtyElements = 0;
    }
}