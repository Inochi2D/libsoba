module soba.core.gpu.wgpu.surface;
import soba.core.gpu.wgpu.target;
import soba.core.gpu.wgpu;
import soba.core.gpu.surface;
import soba.core.gpu.target;
import soba.core.gpu;
import bindbc.wgpu;
import bindbc.sdl;

class SbWGPUSurface : SbGPUSurface {
private:
    int swapInterval = 1;
    uint width_, height_;
    uint sbwidth_, sbheight_;
    float dpiScaleX_, dpiScaleY_;
    WGPUTexture currentTexture_;

    void createSurface(SDL_Window* window) {
        WGPUSurfaceDescriptor desc;

        SDL_SysWMinfo info;
        SDL_GetWindowWMInfo(window, &info);
        
        version(Windows) {

            // Win32
            WGPUSurfaceDescriptorFromWindowsHWND windowDesc;
            windowDesc.hinstance = info.info.win.hinstance;
            windowDesc.hwnd = info.info.win.window;
            windowDesc.chain = WGPUChainedStruct(null, WGPUSType.SurfaceDescriptorFromWindowsHWND);
            desc.nextInChain = cast(const(WGPUChainedStruct)*)&windowDesc;

            this.surface = wgpuInstanceCreateSurface(sbWGPUGetInstance(), &desc);
        } else version(linux) {

            // X11
            if (wminfo.subsystem == SDL_SYSWM_X11) {
                WGPUSurfaceDescriptorFromXlibWindow windowDesc;
                windowDesc.display = info.info.x11.display;
                windowDesc.window = info.info.x11.window;
                windowDesc.chain = WGPUChainedStruct(null, WGPUSType.SurfaceDescriptorFromXlibWindow);
                desc.nextInChain = cast(const(WGPUChainedStruct)*)&windowDesc;
            }

            // WAYLAND
            if (wminfo.subsystem == SDL_SYSWM_WAYLAND) {
                WGPUSurfaceDescriptorFromWaylandSurface windowDesc;
                windowDesc.display = info.info.wl.display;
                windowDesc.surface = info.info.wl.surface;
                windowDesc.chain = WGPUChainedStruct(null, WGPUSType.SurfaceDescriptorFromWaylandSurface);
                desc.nextInChain = cast(const(WGPUChainedStruct)*)&windowDesc;
            }
            this.surface = wgpuInstanceCreateSurface(sbWGPUGetInstance(), &desc);
        } else version(OSX) {
            SDL_Renderer* renderer = SDL_CreateRenderer(handle, -1, SDL_RENDERER_PRESENTVSYNC);
            windowDesc.layer = SDL_RenderGetMetalLayer(renderer);
            windowDesc.chain = WGPUChainedStruct(null, WGPUSType.SurfaceDescriptorFromWaylandSurface);
            desc = cast(const(WGPUChainedStruct)*)&sfdMetal;
            this.surface = wgpuInstanceCreateSurface(sbWGPUGetInstance(), &desc);
            SDL_DestroyRenderer(renderer);
        }
    }

    // (re-)create swapchain
    void createSwapchain() {
        swapchainFormat = wgpuSurfaceGetPreferredFormat(surface, context.getAdapter());

        // Destroy the prior swapchain
        if (swapchain) {
            if (currentTexture_) wgpuTextureViewDrop(currentTexture_);
            wgpuSwapChainDrop(swapchain);
        }


        // Calculate the presenting mode
        // Immediate = no vsync
        // FIFO = strict vsync
        // Mailbox = VSync with frameskip
        WGPUPresentMode mode = WGPUPresentMode.Immediate;
        switch(swapInterval) {

            case -1:
                mode = WGPUPresentMode.Immediate;
                break;

            case 0:
                mode = WGPUPresentMode.Mailbox;
                break;

            case 1:
                mode = WGPUPresentMode.Fifo;
                break;
            
            default: break;
        }

        // Create a new descriptor and apply it to our swapchain
        WGPUSwapChainDescriptor desc;
        desc.width = width_;
        desc.height = height_;
        desc.presentMode = mode;
        desc.format = swapchainFormat;
        desc.usage = WGPUTextureUsage.RenderAttachment;
        desc.nextInChain = cast(WGPUChainedStruct*)new WGPUSwapChainDescriptorExtras(
            WGPUChainedStruct(
                null,
                cast(WGPUSType)WGPUNativeSType.SwapChainDescriptorExtras
            ),
            WGPUCompositeAlphaMode.Auto,
            0,
            null
        );
        swapchain = wgpuDeviceCreateSwapChain(context.getDevice(), this.surface, &desc);
    }

protected:
    SbWGPUContext context;
    WGPUSurface surface;
    WGPUSwapChain swapchain;
    WGPUTextureFormat swapchainFormat;

public:

    ~this() {
        wgpuSwapChainDrop(swapchain);
        wgpuSurfaceDrop(surface);
    }

    this(SbGPUContext context, SbGPUCreationTargetI target) {
        super(context, target);
        this.context = cast(SbWGPUContext)context;

        // Screen coordinate width/height
        uint swidth, sheight;
        SDL_GetWindowSize(target.getHandle(), cast(int*)&swidth, cast(int*)&sheight);

        // Gets size of window in pixels.
        SDL_GetWindowSizeInPixels(target.getHandle(), cast(int*)&width_, cast(int*)&height_);

        // Calculate DPI scale
        dpiScaleX_ = cast(float)width_/cast(float)swidth;
        dpiScaleY_ = cast(float)height_/cast(float)sheight;
        
        // Create surface and swapchain.
        createSurface(target.getHandle());
        createSwapchain();
    }

    /**
        Gets the width of the surface in pixels
    */
    override
    uint getWidthPx() { return width_; }
    
    /**
        Gets the Height of the surface in pixels
    */
    override
    uint getHeightPx() { return height_; }

    /**
        Gets the horizontal DPI scale of the surface
    */
    override
    float dpiScaleX() { return dpiScaleX_; }

    /**
        Gets the vertical DPI scale of the surface
    */
    override
    float dpiScaleY() { return dpiScaleY_; }

    override
    void onResize(uint swidth, uint sheight) {

        // Gets size of window in pixels.
        SDL_GetWindowSizeInPixels(target.getHandle(), cast(int*)&width_, cast(int*)&height_);

        // Calculate DPI scale
        dpiScaleX_ = cast(float)width_/cast(float)swidth;
        dpiScaleY_ = cast(float)height_/cast(float)sheight;

        this.createSwapchain();
    }

    /**
        Called when the surface starts being rendered to
    */
    override
    void onSurfaceBeginRender() { }
    
    /**
        Called when the surface starts stops being rendered to
    */
    override
    void onSurfaceEndRender() {
        this.present();
    }

    /**
        Rebuilds the swapchain
    */
    override 
    void rebuildSwapchain() {
        this.createSwapchain();
    }

    /**
        Sets the swap interval
    */
    override
    void setSwapInterval(int swapinterval) {
        this.swapInterval = swapinterval;
        this.rebuildSwapchain();
    }

    /**
        Presents the surface
    */
    override
    void present() {
        wgpuSwapChainPresent(swapchain);
    }

    /**
        Gets a render target from the surface
    */
    override
    SbGPURenderTarget toRenderTarget() {
        return new SbWGPURenderTarget(context, this);
    }

    /**
        Gets the next texture view associated with this swapchain
    */
    WGPUTextureView getNextTexture() {
        return wgpuSwapChainGetCurrentTextureView(swapchain);
    }
}