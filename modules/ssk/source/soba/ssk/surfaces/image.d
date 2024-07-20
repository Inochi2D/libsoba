module soba.ssk.surfaces.image;
import soba.ssk.surfaces;
import soba.canvas.image;

/**
    A surface consisting of a texture
*/
class SskImageSurface : SskSurface {
private:
    SbImage image;

public:
    this(SbImage image) {
        super();
        this.image = image;
        this.bounds = recti(
            0,
            0,
            image.getWidth(),
            image.getHeight()
        );
    }
}
