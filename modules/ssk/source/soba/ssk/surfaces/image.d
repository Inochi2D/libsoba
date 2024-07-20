module soba.ssk.surfaces.image;
import soba.ssk.renderers;
import soba.ssk.surfaces;
import soba.ssk.scene;
import soba.ssk.texture;
import numem.all;
import inmath;

import soba.canvas.image;

/**
    A surface consisting of a texture
*/
class SskImageSurface : SskSurface {
@nogc:
private:
    SbImage image;
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
            image.getHeight()
        );

        this.tryUpload();
    }

public:
    ~this() {
        nogc_delete(texture);
        nogc_delete(image);
    }

    this(SskScene scene, SbImage image) {
        super(scene);
        this.image = image;
        this.bounds = recti(
            0,
            0,
            image.getWidth(),
            image.getHeight()
        );
        this.tryUpload();
    }

    override
    void render(SskRenderer renderer) {
        renderer.renderTextureTo(texture, this.getBoundsRaw());
    }
}
