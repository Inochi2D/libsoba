/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Surfaces
*/
module soba.core.gpu.surface;
import soba.core.gpu.texture;
import soba.core.gpu;
import bindbc.wgpu;
import std.string;
import bindbc.sdl;
import std.exception;


enum SbGFXSurfaceSwapMode {

    /**
        Disables VSync
    */
    Immediate = 0,

    /**
        Adaptive VSync
    */
    AdaptiveVSync = 1,
    
    /**
        Strict VSync
    */
    VSync = 2,
}

class SbGFXSurface : SbGFXTextureView {
private:
    SDL_Window* window;
    SbGFXContext ctx;
    
    bool transparent;
    WGPUSurfaceDescriptor sfcdesc;
    WGPUSurface surface;

    WGPUSwapChain swapchain;
    SbGFXSurfaceSwapMode swapMode;
    WGPUTextureView currentTexture_;
    WGPUTextureFormat swapchainFormat;

    int width_, height_;

    void createSurface() {
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

            this.surface = wgpuInstanceCreateSurface(ctx.getInstance(), &desc);
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
            this.surface = wgpuInstanceCreateSurface(ctx.getInstance(), &desc);
        } else version(OSX) {
            SDL_Renderer* renderer = SDL_CreateRenderer(handle, -1, SDL_RENDERER_PRESENTVSYNC);
            windowDesc.layer = SDL_RenderGetMetalLayer(renderer);
            windowDesc.chain = WGPUChainedStruct(null, WGPUSType.SurfaceDescriptorFromWaylandSurface);
            desc = cast(const(WGPUChainedStruct)*)&sfdMetal;
            this.surface = wgpuInstanceCreateSurface(ctx.getInstance(), &desc);
            SDL_DestroyRenderer(renderer);
        }
    }

    // (re-)create swapchain
    void createSwapchain() {
        swapchainFormat = wgpuSurfaceGetPreferredFormat(surface, ctx.getAdapter());

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
        switch(swapMode) {

            case SbGFXSurfaceSwapMode.Immediate:
                mode = WGPUPresentMode.Immediate;
                break;

            case SbGFXSurfaceSwapMode.AdaptiveVSync:
                mode = WGPUPresentMode.Mailbox;
                break;

            case SbGFXSurfaceSwapMode.VSync:
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
            transparent ? WGPUCompositeAlphaMode.PreMultiplied : WGPUCompositeAlphaMode.Auto,
            0,
            null
        );
        swapchain = wgpuDeviceCreateSwapChain(ctx.getDevice(), this.surface, &desc);
    }

public:
    /// Destructor
    ~this() {
        if (swapchain) wgpuSwapChainDrop(swapchain);
        if (surface) wgpuSurfaceDrop(surface);
    }

    /**
        Constructs a new Surface for a low level SDL window
    */
    this(SbGFXContext ctx, SDL_Window* window, int width, int height, SbGFXSurfaceSwapMode vsync = SbGFXSurfaceSwapMode.VSync, bool requestTransparent=false) {
        transparent = requestTransparent;
        this.ctx = ctx;
        this.window = window;
        this.width_ = width;
        this.height_ = height;
        this.createSurface();
        this.createSwapchain();
    }

    /**
        Resizes the surface
    */
    final
    void resize(int width, int height) {
        this.width_ = width;
        this.height_ = height;

        this.createSwapchain();
    }

    /**
        Sets the swapping mode
    */
    final
    void setSwapMode(SbGFXSurfaceSwapMode mode) { swapMode = mode; createSwapchain(); }

    /**
        Gets the swapping mode
    */
    final
    SbGFXSurfaceSwapMode getSwapMode() { return swapMode; }

    /**
        Returns the next texture view to this surface
    */
    final
    WGPUTextureView nextTexture() {
        if (currentTexture_) this.dropTexture();
        currentTexture_ = wgpuSwapChainGetCurrentTextureView(swapchain);
        return currentTexture_;
    }

    /**
        Drops the render source backing texture if needed
    */
    override
    void dropIfNeeded() {
        this.dropTexture();
    }

    /**
        Returns the next texture view to this surface
    */
    override
    WGPUTextureView currentView() {
        return currentTexture_;
    }

    /**
        Gets the native underlying WGPU format
    */
    override
    WGPUTextureFormat getNativeFormat() {
        return swapchainFormat;
    }

    /**
        Gets the native underlying WGPU sampler
    */
    override
    WGPUSampler getNativeSampler() { return null; }

    /**
        Drops the current texture view
    */
    final
    void dropTexture() {
        if (currentTexture_) {
            wgpuTextureViewDrop(currentTexture_);
            currentTexture_ = null;
        }
    }

    /**
        Present the surface's swapchain
    */
    final
    void present() {
        wgpuSwapChainPresent(swapchain);
    }

    /// Width of the surface (in pixels)
    final int width() { return width_; }

    /// Height of the surface (in pixels)
    final int height() { return height_; }

    /// Returns the underlying WGPU handle
    final WGPUSurface getHandle() { return surface; }

    /// Returns the underlying WGPU swapchain handle
    final WGPUSwapChain getSwapChainHandle() { return swapchain; }
}