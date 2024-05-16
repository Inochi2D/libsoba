module soba.widgets.window;
import soba.widgets.containers;
import soba.widgets.widget;
import soba.core.window;
import soba.core.math;
import soba.core.events;

import numem.all;

/**
    The window style of a window, defining how the backend handles the window.
*/
enum SbWindowStyle {
    /**
        Window is a main window.
    */
    MainWindow = 0x01,

    /**
        Window is a sub-window, which will block interaction in parent windows
    */
    SubWindow  = 0x02,

    /**
        Window is a tool window, which is a main window with a smaller window frame
    */
    ToolWindow = 0x03
}

/**
    Window flags
*/
enum SbWindowFlags {

    /**
        The window can be resized.
    */
    Resizable = 0x10,

    /**
        Window should be constantly redrawn and updated.
    */
    Immediate = 0x20,

    /**
        Window can be docked in to other containers.
    */
    Dockable = 0x40,

    /**
        Use the system window borders
    */
    SystemBorders = 0x80,
}

/**

*/
abstract
class SbWindow : SbContainer {
nothrow @nogc:
private:
    SbBackingWindow backing;

protected:
    SbWindowStyle style;
    SbWindowFlags flags;

    /**
        Creates a backing window if none exists already.
    */
    final
    void createBackingWindow(nstring title, int x, int y, int width, int height, uint flags) {
        if (!backing) {
            backing = nogc_new!SbBackingWindow(title, x, y, width, height, flags);
            sbSubscribeWindow(backing, this);
        }
    }

    /**
        Destroys a backing window if one exists.
    */
    final
    void destroyBackingWindow() {
        if (backing) {
            sbUnsubscribeWindow(backing);
            nogc_delete(backing);
            this.backing = null;
        }
    }

    /**
        Gets the SbWindow's backing window.
    */
    final
    SbBackingWindow getBackingWindow() {
        return backing;
    }

    /**
        Set whether the window is resizable
    */
    final
    void setResizable(bool resizable) {
        if (backing) {
            backing.setResizeAllowed(resizable);
        }
    }

public:
    ~this() {
        this.destroyBackingWindow();
    }

    /**
        Creates a window
    */
    this(SbWindowStyle windowStyle, SbWindowFlags flags) {
        super();
        this.style = windowStyle;
        this.flags = flags;
    }

    /**
        Returns whether the window is floating independently
    */
    final
    bool isFloating() {
        return backing !is null;
    }

    /**
        Called when the window is resized
    */
    override
    void onResize(float width, float height) {
        if (backing) {
            backing.setFramebufferSize(width, height);
        }
    }

    /**
        Called when the mouse moves within the window
    */
    override
    bool onMouseMove(float x, float y) {
        return super.onMouseMove(x, y);
    }

    /**
        Called when the mouse clicks within the window
    */
    override
    bool onMouseClicked(float x, float y, SbMouseButton button) {
        return super.onMouseClicked(x, y, button);
    }

    /**
        Called when the mouse double clicks within the window
    */
    override
    bool onMouseDoubleClicked(float x, float y, SbMouseButton button) {
        return super.onMouseDoubleClicked(x, y, button);
    }

    /**
        Called when the mouse is released within the window
    */
    override
    bool onMouseReleased(float x, float y, SbMouseButton button) {
        return super.onMouseReleased(x, y, button);
    }

    override
    recti getBounds() {
        if (backing) {
            vec2 fbSize = backing.getFramebufferSize();
            return recti(0, 0, cast(int)fbSize.x, cast(int)fbSize.y);
        }

        if (SbWidget parent = this.getParent()) {
            return parent.getBounds();
        }

        return recti.init;
    }

    override
    void onUserCopy() {
        if (isFocused()) {
            SbEventLoop.instance.getFocus().onUserCopy();
        }
    }

    override
    void onUserPaste() {
        if (isFocused()) {
            SbEventLoop.instance.getFocus().onUserPaste();
        }
    }

    /**
        Sets the widget which is focused by the window
    */
    final
    void setFocus(SbWidget widget) {
        SbEventLoop.instance.setFocus(widget);
    }
}