module soba.widgets.window;
import soba.widgets.container;
import numem.all;
import soba.core.window;

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
protected:
    SbBackingWindow backing;
    SbWindowStyle style;
    SbWindowFlags flags;

    /**
        Creates a backing window if none exists already.
    */
    final
    void createBackingWindow(nstring title, int x, int y, int width, int height, uint flags) {
        if (!backing) {
            backing = nogc_new!SbBackingWindow(title, x, y, width, height, flags);
        }
    }

public:
    ~this() {
        if (backing) {
            nogc_delete(backing);
            this.backing = null;
        }
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

    void onResize(float width, float height) {
        if (backing) {
            backing.setFramebufferSize(width, height);
        }
    }
}