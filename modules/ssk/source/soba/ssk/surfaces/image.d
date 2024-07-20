module soba.ssk.surfaces.image;
import soba.ssk.surfaces;
import soba.ssk.scene;
import inmath;

import soba.canvas.image;

/**
    A surface consisting of a texture
*/
class SskImageSurface : SskSurface {
@nogc:
private:
    SbImage image;

public:
    this(SskScene scene, SbImage image) {
        super(scene);
        this.image = image;
        this.bounds = recti(
            0,
            0,
            image.getWidth(),
            image.getHeight()
        );
    }
}
