/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen

    Surfaces
*/
module soba.core.gpu.surface;
import soba.core.gpu;
import bindbc.wgpu;
import std.string;
import bindbc.sdl;


class SbSurface {
private:
    this() { }

    SDL_Window* window;
    SbGPUContext ctx;
    
    WGPUSurfaceDescriptor sfcdesc;
    WGPUSurface surface;

    WGPUSwapChainDescriptor swapdesc;
    WGPUSwapChain swapchain;

    int width_, height_;

    // Create surface descriptor
    WGPUSurfaceDescriptor createSurfaceDescriptor(SDL_Window* window) {
        WGPUSurfaceDescriptor sfd;

        SDL_SysWMinfo wminfo;
        SDL_GetWindowWMInfo(window, &wminfo);
        switch(wminfo.subsystem) {

            // WINDOWS
            version(Windows) {
                case SDL_SYSWM_WINDOWS:
                    auto win32_hwnd = wminfo.info.win.window;
                    auto win32_hinst = wminfo.info.win.hinstance;
                    WGPUSurfaceDescriptorFromWindowsHWND sfdHwnd = {
                        chain: {
                            next: null,
                            sType: WGPUSType.SurfaceDescriptorFromWindowsHWND
                        },
                        hinstance: win32_hwnd,
                        hwnd: win32_hinst
                    };
                    sfd.nextInChain = cast(const(WGPUChainedStruct)*)&sfdHwnd;
                    break;
            }

            version(linux) {
                // X11
                case SDL_SYSWM_X11:
                    auto x11_display = wminfo.info.x11.display;
                    auto x11_window = wminfo.info.x11.window;
                    WGPUSurfaceDescriptorFromXlibWindow sfdX11 = {
                        chain: {
                            next: null,
                            sType: WGPUSType.SurfaceDescriptorFromXlibWindow
                        },
                        display: x11_display,
                        window: x11_window
                    };

                    sfd.nextInChain = cast(const(WGPUChainedStruct)*)&sfdX11;
                    break;

                // WAYLAND
                case SDL_SYSWM_WAYLAND:
                    auto wl_display = wminfo.info.wl.display;
                    auto wl_surface = wminfo.info.wl.surface;
                    WGPUSurfaceDescriptorFromWaylandSurface sfdWL = {
                        chain: {
                            next: null,
                            sType: WGPUSType.SurfaceDescriptorFromWaylandSurface
                        },
                        display: wl_display,
                        surface: wl_surface
                    };

                    sfd.nextInChain = cast(const(WGPUChainedStruct)*)&sfdWL;
                    break;
            }
            
            // macOS
            version(OSX) {
                case SDL_SYSWM_COCOA:
                    SDL_Renderer* renderer = SDL_CreateRenderer(handle, -1, SDL_RENDERER_PRESENTVSYNC);
                    auto metal_layer = SDL_RenderGetMetalLayer(renderer);
                    WGPUSurfaceDescriptorFromMetalLayer sfdMetal = {
                        chain: {
                            next: null,
                            sType: WGPUSType.SurfaceDescriptorFromMetalLayer
                        },
                        layer: metal_layer
                    };
                    sfd = cast(const(WGPUChainedStruct)*)&sfdMetal;
                    SDL_DestroyRenderer(renderer);
            }
            // Other platforms
            default:

                assert(0, "Sorry the specified platform is currently not supported!");
        }
        return sfd;
    }

    WGPUSwapChainDescriptor createSwapchainDescriptor(SbGPUContext ctx, WGPUSurface surface, int width, int height) {
        WGPUSwapChainDescriptor desc;
        desc = WGPUSwapChainDescriptor(
            null,
            "Swapchain",
            WGPUTextureUsage.RenderAttachment,
            wgpuSurfaceGetPreferredFormat(surface, ctx.getAdapter()),
            width,
            height,
            WGPUPresentMode.Fifo
        );

        return desc;
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
    this(SbGPUContext ctx, SDL_Window* window, int width, int height) {
        this.window = window;
        this.ctx = ctx;
        this.width_ = width;
        this.height_ = height;
        this.sfcdesc = this.createSurfaceDescriptor(window);
        this.surface = wgpuInstanceCreateSurface(ctx.getInstance(), &this.sfcdesc);
        this.swapdesc = this.createSwapchainDescriptor(ctx, this.surface, width, height);
        this.swapchain = wgpuDeviceCreateSwapChain(ctx.getDevice(), this.surface, &this.swapdesc);
    }

    /**
        Resizes the surface
    */
    final
    void resize(int width, int height) {
        this.width_ = width;
        this.height_ = height;

        if (swapchain) wgpuSwapChainDrop(swapchain);
        swapdesc = createSwapchainDescriptor(ctx, surface, width, height);
        swapchain = wgpuDeviceCreateSwapChain(ctx.getDevice(), surface, &swapdesc);
    }

    /**
        Returns the current texture (view)
    */
    final
    WGPUTextureView currentTexture() {
        return wgpuSwapChainGetCurrentTextureView(swapchain);
    }

    /// Width of the surface (in pixels)
    final int width() { return width_; }

    /// Height of the surface (in pixels)
    final int height() { return height_; }
}