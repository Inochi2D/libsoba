module soba.widgets.window.window;
import soba.widgets.widget;
import soba.core;
import soba.sio;
import soba.ssk;
import numem.all;

class SbWindow : SbWidget, SioIEventHandler {
@nogc:
private:
    SioWindowCreateInfo createInfo;
    SioWindow window;
    SskScene scene;
    SioWindowID windowId;

    void updateWindowDockState(SbWidget eWidget) {
        if (eWidget) {

            if (window) {
                SioEventLoop.instance().removeAllHandlersFor(windowId);
                nogc_delete!SioWindow(window);
                this.window = null;
            }

            eWidget.getSurface().addChild(this.getSurface());
            nogc_delete!SskScene(scene);
            this.scene = null;

        } else {

            // TODO: set position
            this.window = nogc_new!SioWindow(createInfo);
            this.scene = nogc_new!SskScene(window);
            this.scene.getRoot().addChild(this.getSurface());
            windowId = this.window.getId();
            SioEventLoop.instance().addHandler(windowId, this);
        }
    }

protected:


    /**
        Called when this node has a new parent
    */
    override
    void onReparent(SbWidget new_) {
        this.updateWindowDockState(new_);
    }

    override
    void onReflow() {
        if (this.getParent()) {
            this.setBounds(this.getParent().getBounds());
        } else {
            vec2i sz = window.getWindowSize();
            this.setBounds(recti(0, 0, sz.x, sz.y));
        }

        super.onReflow();
    }

    override
    void onEvent(SioEvent ev) {
        if (window) {
            if (ev.type == SioEventType.window) {
                switch(ev.window.event) {
                    default: 
                        this.reflow();
                        this.requestRedraw();
                        break;
                        
                    case SioWindowEventID.closeRequested:
                        this.hide();
                        break;
                
                }
            }
        }
        super.onEvent(ev);
    }

    /**
        Event called when visibility is changed.
    */
    override
    void onVisibilityChanged(bool newState) {
        if (window) {
            if (newState) {
                window.show();
                
                vec2i sz = window.getWindowSize();
                this.setBounds(recti(0, 0, sz.x, sz.y));
            } else window.hide();
        }
    }

    override
    void onRedrawRequested() {
        if (window) {
            if (this.scene) {
                this.scene.redraw();
            }
        }
    }

public:
    /**
        Creates a new window
    */
    this(nstring title) {
        createInfo.title = title;
        this.setSurface(nogc_new!SskSurface());
        this.updateWindowDockState(null);
    }

    /**
        Creates a new window
    */
    this(nstring title, uint width, uint height) {
        createInfo.title = title;
        createInfo.width = width;
        createInfo.height = height;
        createInfo.surfaceInfo = sbGetPreferredWindowSurface();
        this.setSurface(nogc_new!SskSurface());
        this.updateWindowDockState(null);
    }

    /**
        Called by the soba event handler.
    */
    final
    void processEvent(ref SioEvent event) {
        this.onEvent(event);
    }

    /**
        Sets the child of the window
    */
    void setChild(SbWidget widget) {
        this.addChild(widget);
    }
}