module soba.widgets.containers;
import soba.widgets.widget;
import soba.drawing.contexts;
import soba.core.math;
import numem.all;

public import soba.widgets.containers.box;

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
protected:

    override
    void onReflow() {
        super.onReflow();

        foreach(child; this.getChildren()) {
            child.setBounds(this.getBounds());
        }
    }
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
        Removes a child widget from the container
    */
    void removeChild(SbWidget widget) {
        super.removeChild(widget);
    }

    /**
        Draws the container and all of its children
    */
    override
    int draw() {
        int acc = 0;

        if (this.isDirty()) {
            this.getDrawingContext().save();
                acc = super.draw();
            this.getDrawingContext().restore();
        }

        return acc;
    }
}
