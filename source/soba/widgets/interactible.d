module soba.widgets.interactible;
import soba.core.events;
import soba.widgets;

class SbInteractible : SbWidget {
nothrow @nogc:
private:
    bool active;
    bool hovered;

protected:
    /**
        Let interactions on the widget fall through to child widgets.
    */
    bool fallthrough;

public:

    /**
        Gets if the interactible widget is clicked
    */
    final
    bool getIsActivated() {
        return active;
    }

    /**
        Gets if the interactible widget is hovered
    */
    final
    bool getIsHovered() {
        return hovered;
    }

    /**
        Called when the mouse enters the widget
    */
    void onMouseEnter() { }

    /**
        Called when the mouse leaves the widget
    */
    void onMouseLeave() { }

    /**
        Called when the activates clicks the widget
    */
    void onActivated() { }
}