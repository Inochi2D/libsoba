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

protected:
    bool dirty;
    recti bounds;

    SskScene getScene() {
        return scene;
    }

public:
    this(SskScene scene) {
        this.scene = scene;
        this.dirty = true;
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
            return;
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
        Sets the bounds of the surface relative to parent surface.
    */
    void setBounds(recti bounds) {
        this.bounds = bounds;
    }

    /**
        Draws the surface and any child surfaces (if dirty)
    */
    final
    void renderAll() {
        if (dirty) {
            render(this.getScene().getRenderer());
            dirty = false;
        }

        this.getScene().getRenderer().setScissor(this.getBounds());

        foreach(child; children) {
            child.renderAll();
        }
    }

    /**
        Marks this surface dirty, setting it and its children up for a redraw
    */
    final
    void markDirty() {
        dirty = true;
    }

    /**
        The rendering function of this surface
    */
    void render(SskRenderer renderer) { }
}