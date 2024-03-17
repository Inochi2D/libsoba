module soba.widgets.container;
import soba.widgets.widget;
import soba.drawing.contexts;
import numem.all;
import inmath;

/**
    A widget that contains other widgets.
    The container takes ownership over the widgets added to it
*/
abstract
class SbContainer : SbWidget {
nothrow @nogc:
private:
    weak_vector!(SbWidget) children;

protected:
    final
    size_t addChild(SbWidget widget) {
        children ~= widget;
        return children.size();
    }

    /**
        Removes a child by its offset
    */
    final
    bool removeChild(size_t offset) {
        
        // Impossibility.
        if (offset >= children.size()) return false;

        // Remove :)
        children.remove(offset);
        return true;
    }

    override
    void onDraw(ref SbDrawingContext context) {
        foreach (child; children) {
            if (child) {
                child.draw(context);
            }
        }
    }

public:
    this() {
        super();
    }

    override
    void draw(ref SbDrawingContext context) {
        context.save();
            this.onDraw(context);
        context.restore();
    }

    override
    rect getBounds() { return rect.init; }

    override
    void setBounds(rect size) { }
}
