module soba.ssk.surfaces.canvas;
import soba.ssk.renderers;
import soba.ssk.surfaces;
import soba.ssk.texture;
import soba.ssk.scene;
import numem.all;
import inmath;

import soba.canvas;

/**
    A surface consisting of a vector-renderable canvas
*/
class SskCanvasSurface : SskSurface {
@nogc:
private:
    SbImage image;
    SbContext context;
    SskTexture texture;

public:
    /**
        Creates a surface
    */
    this(SskScene scene, uint width, uint height) {
        super(scene);
        this.bounds = recti(
            0,
            0,
            width,
            height
        );

        this.image = nogc_new!SbImage(width, height, 4);
        this.context = SbContext.create();
        this.texture = scene.getRenderer().createTexture(
            SskTextureFormat.BGRA,
            SskTextureKind.image,
            width,
            height
        );
    }

    /**
        Begins rendering to the surface
    */
    SbContext begin() {
        context.begin(image);
        return context;
    }

    /**
        Ends rendering to the surface
    */
    void end() {
        context.end();
        auto lock = image.acquire();
        texture.upload(image.getFormat().fromImageFormat(), lock.data[0..lock.dataLength], lock.width, lock.height);
        image.release(lock);
        this.markDirty();
    }

    override
    void render(SskRenderer renderer) {
        renderer.renderTextureTo(texture, this.getBoundsRaw());
    }
}