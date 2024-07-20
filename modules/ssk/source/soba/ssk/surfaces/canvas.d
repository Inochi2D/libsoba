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

    void tryUpload() {
        auto lock = image.acquire();
        if(lock) {
            texture.upload(image.getFormat().fromImageFormat(), lock.data[0..lock.dataLength], lock.width, lock.height);
            image.release(lock);
            this.markDirty();
        }
    }

protected:

    /**
        Called when reparenting to a new scene

        The scene change is first applied *after* this function is called
        So you may refer to the old scene via getScene()
    */
    override
    void onSceneChanged(SskScene newScene) {

        // Delete old texture belonging to old scene
        nogc_delete(this.texture);

        // Create a new texture
        this.texture = newScene.getRenderer().createTexture(
            image.getFormat().fromImageFormat(),
            SskTextureKind.image,
            image.getWidth(),
            image.getWidth()
        );

        this.tryUpload();
    }

public:
    ~this() {
        nogc_delete(texture);
        nogc_delete(context);
        nogc_delete(image);
    }

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
            image.getFormat().fromImageFormat(),
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
        this.tryUpload();
    }

    override
    void render(SskRenderer renderer) {
        renderer.renderTextureTo(texture, this.getBoundsRaw());
    }
}