module soba.widgets.container;
import soba.widgets.widget;
import soba.drawing.contexts;
import soba.core.math;
import numem.all;

enum SbChildPosition {
    Front,
    Back
}

/**
    A widget that contains other widgets.
    The container takes ownership over the widgets added to it
*/
abstract
class SbContainer : SbWidget {
nothrow @nogc:
public:
    this() {
        super();
    }

    /**
        Adds a child widget to the container
    */
    void addChild(SbWidget child, SbChildPosition position) {
        final switch(position) {
            case SbChildPosition.Front:
                super.addChild!true(child);
                break;
            case SbChildPosition.Back:
                super.addChild!false(child);
                break;
        }
    }

    /**
        Draws the container and all of its children
    */
    override
    int draw() {
        int acc = 0;

        recti bounds = this.getBounds();

        if (this.isDirty()) {
            this.getDrawingContext().save();
                this.getDrawingContext().clipRectangle(bounds.x, bounds.y, bounds.width, bounds.height);
                acc = super.draw();
            this.getDrawingContext().restore();
        }

        return acc;
    }

    override
    recti getBounds() { 
        if (SbWidget parent = this.getParent()) {
            return parent.getBounds();
        }
        return recti.init; 
    }
}
