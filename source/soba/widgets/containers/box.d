module soba.widgets.containers.box;
import soba.widgets.containers;
import soba.widgets.widget;
import soba.drawing.contexts;
import soba.core.math;
import numem.all;
import core.stdc.stdio;

enum SbBoxDirection {
    Horizontal,
    Vertical
}

class SbBox : SbContainer {
nothrow @nogc:
private:
    SbBoxDirection direction;
    bool evenSpacing;
    bool fitContents;

protected:

    override
    void onReflow() {
        recti targetSelfBounds;
        if (SbWidget parent = this.getParent()) {
            targetSelfBounds = parent.getBounds();
        }

        if (direction == SbBoxDirection.Horizontal) {
            if (fitContents) {
                float tallestRequest = 0;
                foreach(child; this.getChildren()) {
                    float request = max(child.getRequestedSize().y, child.getMinimumSize().y);
                    if (request > tallestRequest)
                        tallestRequest = request;
                }
                targetSelfBounds.height = cast(int)tallestRequest;
            }
            this.setBounds(targetSelfBounds);

            // Figure out the height of every widget inside.
            recti dimensions = this.getBounds();
                SbWidget[] children = this.getChildren();
                float sectionWidth = targetSelfBounds.width/children.length;
                float sectionX = 0;
                foreach(i, child; children) {
                    float request = max(child.getRequestedSize().x, child.getMinimumSize().x);
                    if (evenSpacing) {
                        child.setBounds(recti(cast(int)sectionX, dimensions.y, cast(int)sectionWidth, dimensions.height));
                        sectionX += sectionWidth;
                    } else {
                        // child.
                    }
                }
        } else {
            if (fitContents) {
                float widestRequest = 0;
                foreach(child; this.getChildren()) {
                    float request = max(child.getRequestedSize().x, child.getMinimumSize().x);
                    if (request > widestRequest)
                        widestRequest = request;
                }
                targetSelfBounds.width = cast(int)widestRequest;
            }
            this.setBounds(targetSelfBounds);

            // Figure out the height of every widget inside.
            recti dimensions = this.getBounds();
            
            SbWidget[] children = this.getChildren();
            float sectionHeight = targetSelfBounds.height/children.length;
            float sectionY = 0;
            foreach(i, child; children) {
                child.setBounds(recti(dimensions.x, cast(int)sectionY, dimensions.width, cast(int)sectionHeight));
                sectionY += sectionHeight;
            }
        }
    }

public:

    this(SbBoxDirection direction, bool evenSpacing, bool fitContents) {
        super();
        this.direction = direction;
        this.fitContents = fitContents;
        this.evenSpacing = evenSpacing;
    }
}