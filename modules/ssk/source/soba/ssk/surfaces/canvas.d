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
        if (texture) {
            auto lock = image.acquire();
            if(lock) {
                texture.upload(image.getFormat().fromImageFormat(), lock.data[0..lock.dataLength], lock.width, lock.height);
                image.release(lock);
                this.markDirty();
            }
        }
    }

    void tryCreateTexture() {

        // Create a new texture
        if (this.getScene()) {

            // Yeet old one
            if (this.texture) {
                
                // Delete old texture belonging to old scene
                nogc_delete(this.texture);
                this.texture = null;
            }
            
            this.texture = this.getScene().getRenderer().createTexture(
                image.getFormat().fromImageFormat(),
                SskTextureKind.image,
                image.getWidth(),
                image.getHeight()
            );

            this.tryUpload();
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

        if (newScene) {
            this.setBounds(recti(
                0, 0,
                image.getWidth(), image.getHeight()
            ));
            
            this.tryCreateTexture();
        }
    }

    /**
        Called when resized

        The size change is first applied *after* this function is called
        So you may refer to the old size via getBounds()
    */
    override
    void onBoundsChanged(recti newBounds, recti newBoundsScaled) {
        image.resize(newBoundsScaled.width, newBoundsScaled.height);
        if (texture) this.tryUpload();
        else this.tryCreateTexture();
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
    this(uint width, uint height) {
        super();

        this.setBounds(recti(
            0, 0,
            width, height
        ));

        vec2 scale = this.getScale();
        this.image = nogc_new!SbImage(cast(uint)(width*scale.x), cast(uint)(height*scale.y), 4);
        this.context = SbContext.create();
        
        this.tryCreateTexture();
    }

    /**
        Begins rendering to the surface
    */
    SbContext begin() {
        context.begin(image);
        context.scale(this.getScale());
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
        renderer.renderTextureTo(texture, this.getBoundsScaled());
    }
}