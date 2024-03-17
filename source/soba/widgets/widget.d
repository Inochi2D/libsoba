module soba.widgets.widget;
import soba.drawing;
import numem.all;
import inmath;

abstract class SbWidget {
nothrow @nogc:
private:
    bool shown;
    bool dirty;

protected:
    abstract void onDraw(ref SbDrawingContext context);

public:

    this() { }

    void show() {
        shown = true;
        this.markDirty();
    }

    void hide() {
        shown = false;
        this.markDirty();
    }

    /**
        Draws the widget
    */
    void draw(ref SbDrawingContext context) {
        this.onDraw(context);
    }

    /**
        Updates the widget
    */
    abstract void update();

    /**
        Gets the size of the widget
    */
    abstract rect getBounds();

    /**
        Sets the bounds of the widget
    */
    abstract void setBounds(rect bounds);

    /**
        Marks the widget dirt, setting it up for redrawing
    */
    final
    void markDirty() {
        this.dirty = true;
    }

    /**
        Gets whether the widget is dirty
    */
    final
    bool isDirty() {
        return dirty;
    }
}
