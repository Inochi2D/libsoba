module soba.ssk.surfaces;
import soba.ssk.renderers;
import soba.ssk.scene;
import numem.all;
import inmath;

public import soba.ssk.surfaces.image;
public import soba.ssk.surfaces.canvas;
public import soba.ssk.surfaces.gpu;

/**
    A rendering surface
*/
class SskSurface {
@nogc:
private:
    SskScene scene;
    SskSurface parent;
    weak_vector!SskSurface children;


    void propagateSceneChange(SskScene scene) {
        this.onSceneChanged(scene);
        this.scene = scene;

        foreach(child; children) {
            child.propagateSceneChange(scene);
        }    
    }

protected:
    /**
        Surface dirty flag
    */
    bool dirty;

    /**
        The raw surface bounds
    */
    recti bounds;

    /**
        Gets the scene this surface is attached to
    */
    SskScene getScene() {
        return scene;
    }

    /**
        Called when reparenting to a new scene

        The scene change is first applied *after* this function is called
        So you may refer to the old scene via getScene()
    */
    void onSceneChanged(SskScene newScene) { }

public:
    this(SskScene scene) {
        this.scene = scene;
        this.dirty = true;

        children = weak_vector!SskSurface(0);
    }

    ~this() {

        // Clear children
        foreach(ref child; children)
            nogc_delete(child);
        nogc_delete(children);
    }

    /**
        Gets the children of this surface
    */
    final
    SskSurface[] getChildren() {
        return children[0..$];
    }
    
    /**
        Gets the parent of this surface
    */
    final
    SskSurface getParent() {
        return parent;
    }

    /**
        Adds a child to this surface
    */
    final
    void addChild(SskSurface child) {

        // If the surface is already a child of this node
        // we don't need to do anything.
        if (child.parent is this) {
            return;
        }

        // Resources might not transfer between scenes,
        // as such, we block this.
        if (child.scene !is scene) {
            child.propagateSceneChange(scene);
        }

        // Remove child from their prior parent
        if (child.parent) {
            child.parent.removeChild(child);
        }

        // Add child and set their parent to us.
        children ~= child;
        child.parent = this;
    }

    /**
        Removes a child from this surface
    */
    final
    void removeChild(SskSurface child) {
        foreach(i; 0..children.size) {
            if (children[i] is child) {
                children.remove(i);
                child.parent = null;
                return;
            }
        }
    }

    /**
        Gets the bounds of the surface.

        Child surfaces will be clipped to the bounds of this surface.
    */
    final
    recti getBounds() {
        if (parent) {
            return bounds.clipped(parent.getBounds());
        }
        return bounds;
    }

    /**
        Gets the raw bounds of the surface.
    */
    final
    recti getBoundsRaw() {
        return bounds;
    }

    /**
        Gets the bounds of the surface in rendering space.
    */
    recti getRenderBounds() {
        if (parent) {
            return parent.getRenderBounds();
        }
        return bounds;
    }

    /**
        Sets the bounds of the surface relative to parent surface.
    */
    void setBounds(recti bounds) {
        this.bounds = bounds;
    }

    /**
        Draws the surface and any child surfaces (if dirty)
    */
    final
    void renderAll(SskRenderer renderer) {
        renderer.setScissor(this.getBounds());

        preRender();
            if (dirty) {
                render(renderer);
                dirty = false;
            }

            foreach(child; children) {
                child.renderAll(renderer);
            }
        postRender();
    }

    /**
        Marks this surface dirty, setting it and its children up for a redraw
    */
    final
    void markDirty() {
        dirty = true;
    }

    /**
        Called before rendering begins for this and child elements
    */
    void preRender() { }

    /**
        The rendering function of this surface
    */
    void render(SskRenderer renderer) { }
    
    /**
        Called after rendering ends for this and child elements
    */
    void postRender() { }
}