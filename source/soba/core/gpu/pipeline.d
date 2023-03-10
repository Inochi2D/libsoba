module soba.core.gpu.pipeline;
import soba.core.gpu;
import bindbc.wgpu;
import std.string;
import std.exception;

/**
    Describes the kind of topology of the mesh being rendered
*/
enum SbGFXPrimitiveTopology {

    /**
        Draw individual triangles in a list
    */
    Triangles = WGPUPrimitiveTopology.TriangleList,

    /**
        Draw individual triangles in a continual strip
    */
    TriangleStrip = WGPUPrimitiveTopology.TriangleStrip,

    /**
        Draw individual lines in a list
    */
    Lines = WGPUPrimitiveTopology.LineList,

    /**
        Draw individual lines in a continual strip
    */
    LineStrip = WGPUPrimitiveTopology.LineStrip,

    /**
        Draw individual points
    */
    Points = WGPUPrimitiveTopology.PointList,
}

/**
    Describes the culling mode for triangles being rendered
*/
enum SbGFXCullMode {
    /**
        Cull the front face of a surface
    */
    Font = WGPUCullMode.Front,

    /**
        Cull the back face of a surface
    */
    Back = WGPUCullMode.Back,
    
    /**
        Cull nothing
    */
    None = WGPUCullMode.None
}

/**
    Blending factors
*/
enum SbGFXBlendFactor
{
    Zero = WGPUBlendFactor.Zero,
    One = WGPUBlendFactor.One,
    Src = WGPUBlendFactor.Src,
    OneMinusSrc = WGPUBlendFactor.OneMinusSrc,
    SrcAlpha = WGPUBlendFactor.SrcAlpha,
    OneMinusSrcAlpha = WGPUBlendFactor.OneMinusSrcAlpha,
    Dst = WGPUBlendFactor.Dst,
    OneMinusDst = WGPUBlendFactor.OneMinusDst,
    DstAlpha = WGPUBlendFactor.DstAlpha,
    OneMinusDstAlpha = WGPUBlendFactor.OneMinusDstAlpha,
    SrcAlphaSaturated = WGPUBlendFactor.SrcAlphaSaturated,
    Constant = WGPUBlendFactor.Constant,
    OneMinusConstant = WGPUBlendFactor.OneMinusConstant
}

/**
    Blending operations
*/
enum SbGFXBlendOperation
{
    Add = WGPUBlendOperation.Add,
    Subtract = WGPUBlendOperation.Subtract,
    ReverseSubtract = WGPUBlendOperation.ReverseSubtract,
    Min = WGPUBlendOperation.Min,
    Max = WGPUBlendOperation.Max
}

enum SbGFXWindingOrder {
    
    /**
        Counter-clockwise winding order
    */
    CCW,

    /**
        Clockwise winding order
    */
    CW
}


class SbGFXPipeline {
private:
    struct SbGFXPipelineGroup {
        uint type;
        int bindloc;
        union {
            /// Type 0
            SbGFXBufferBaseI buffer;

            /// Type 1
            SbGFXTextureView texture;
        }

        this(int bindloc, SbGFXBufferBaseI buffer) {
            this.type = 0;
            this.bindloc = bindloc;
            this.buffer = buffer;
        }

        this(int bindloc, SbGFXTextureView texture) {
            this.type = 1;
            this.bindloc = bindloc;
            this.texture = texture;
        }
    }

    const(char)* name;
    SbGFXContext ctx;

    // Pipeline
    SbGFXPrimitiveTopology topology = SbGFXPrimitiveTopology.Triangles;
    SbGFXCullMode culling = SbGFXCullMode.Back;
    int msaa = 1;
    SbGFXBlendFactor sfactor = SbGFXBlendFactor.Src, sfactorA = SbGFXBlendFactor.Src;
    SbGFXBlendFactor dfactor = SbGFXBlendFactor.OneMinusSrcAlpha, dfactorA = SbGFXBlendFactor.OneMinusSrcAlpha;
    SbGFXBlendOperation bop = SbGFXBlendOperation.Add;
    SbGFXWindingOrder winding = SbGFXWindingOrder.CCW;
    WGPURenderPipelineDescriptor desc;
    WGPURenderPipeline pipeline;
    WGPUBindGroup bgroup;

    // Pipeline data
    const(char)* fragMain;
    const(char)* vertMain;
    SbGFXShader shader;
    SbGFXBufferBaseI[] buffers;
    SbGFXTexture[] textures;
    SbGFXTextureView[] targets;
    SbGFXPipelineGroup[int] bindgroups;
    WGPUBindGroupLayoutEntry[] bglentries;
    WGPUBindGroupEntry[] bgentries;

    WGPUVertexBufferLayout[] generateVertexBufferBindings() {
        WGPUVertexBufferLayout[] layouts;
        foreach(buffer; buffers) {
            layouts ~= buffer.getLayout();
        }
        return layouts;
    }

    void generatePipelineObject() {
        desc.label = name;

        // Vertex buffers
        auto bufferLayouts = generateVertexBufferBindings();
        desc.vertex = WGPUVertexState(
            null,
            shader.getNative(),
            vertMain,
            0,
            null,
            cast(uint)bufferLayouts.length,
            bufferLayouts.ptr
        );

        bool isStrip = 
            topology == SbGFXPrimitiveTopology.LineStrip || 
            topology == SbGFXPrimitiveTopology.TriangleStrip;

        // Primitives
        desc.primitive = WGPUPrimitiveState(
            null,
            cast(WGPUPrimitiveTopology)topology,
            isStrip ? WGPUIndexFormat.Uint32 : WGPUIndexFormat.Undefined,
            cast(WGPUFrontFace)winding,
            cast(WGPUCullMode)culling
        );

        // Multisampling
        desc.multisample = WGPUMultisampleState(
            null,
            msaa,
            ~0,
            false
        );

        WGPUColorTargetState[] states;
        foreach(target; targets) {
            states ~= WGPUColorTargetState(
                null,
                target.getNativeFormat(),
                new WGPUBlendState(
                    WGPUBlendComponent(
                        cast(WGPUBlendOperation)bop,
                        cast(WGPUBlendFactor)sfactor,
                        cast(WGPUBlendFactor)dfactor,
                    ),
                    WGPUBlendComponent(
                        cast(WGPUBlendOperation)bop,
                        cast(WGPUBlendFactor)sfactorA,
                        cast(WGPUBlendFactor)dfactorA,
                    )
                ),
                WGPUColorWriteMask.All
            );
        }

        desc.fragment = new WGPUFragmentState(
            null,
            shader.getNative(),
            fragMain,
            0,
            null,
            cast(int)states.length,
            states.ptr
        );

        bglentries.length = 0;
        bgentries.length = 0;
        foreach(group; bindgroups) {
            switch(group.type) {
                case 0:
                    bgentries ~= WGPUBindGroupEntry(
                        null,
                        group.bindloc,
                        group.buffer.getHandle(),
                        0,
                        group.buffer.getSize(),
                        null,
                        null
                    );
                    bglentries ~= WGPUBindGroupLayoutEntry(
                        null,
                        group.bindloc,
                        WGPUShaderStage.Fragment,
                        WGPUBufferBindingLayout(
                            null,
                            WGPUBufferBindingType.Uniform,
                            false,
                            group.buffer.getSize()
                        ),
                        WGPUSamplerBindingLayout(
                            null,
                            WGPUSamplerBindingType.Undefined
                        ),
                        WGPUTextureBindingLayout(
                            null,
                            WGPUTextureSampleType.Undefined,
                            WGPUTextureViewDimension.Undefined,
                            false
                        ),
                        WGPUStorageTextureBindingLayout(
                            null,
                            WGPUStorageTextureAccess.Undefined,
                            WGPUTextureFormat.Undefined,
                            WGPUTextureViewDimension.Undefined,
                        )
                    );
                    break;
                case 1:
                    bgentries ~= WGPUBindGroupEntry(
                        null,
                        group.bindloc,
                        null,
                        0,
                        0,
                        null,
                        group.texture.currentView()
                    );
                    bgentries ~= WGPUBindGroupEntry(
                        null,
                        group.bindloc+1,
                        null,
                        0,
                        0,
                        group.texture.getNativeSampler(),
                        null
                    );
                    bglentries ~= WGPUBindGroupLayoutEntry(
                        null,
                        group.bindloc,
                        WGPUShaderStage.Fragment,
                        WGPUBufferBindingLayout(
                            null,
                            WGPUBufferBindingType.Undefined,
                            false,
                            0
                        ),
                        WGPUSamplerBindingLayout(
                            null,
                            WGPUSamplerBindingType.Undefined
                        ),
                        WGPUTextureBindingLayout(
                            null,
                            WGPUTextureSampleType.Float,
                            WGPUTextureViewDimension.D2,
                            false
                        ),
                        WGPUStorageTextureBindingLayout(
                            null,
                            WGPUStorageTextureAccess.Undefined,
                            WGPUTextureFormat.Undefined,
                            WGPUTextureViewDimension.Undefined,
                        )
                    );
                    bglentries ~= WGPUBindGroupLayoutEntry(
                        null,
                        group.bindloc+1,
                        WGPUShaderStage.Fragment,
                        WGPUBufferBindingLayout(
                            null,
                            WGPUBufferBindingType.Undefined,
                            false,
                            0
                        ),
                        WGPUSamplerBindingLayout(
                            null,
                            WGPUSamplerBindingType.Filtering
                        ),
                        WGPUTextureBindingLayout(
                            null,
                            WGPUTextureSampleType.Undefined,
                            WGPUTextureViewDimension.Undefined,
                            false
                        ),
                        WGPUStorageTextureBindingLayout(
                            null,
                            WGPUStorageTextureAccess.Undefined,
                            WGPUTextureFormat.Undefined,
                            WGPUTextureViewDimension.Undefined,
                        )
                    );
                    break;
                default: break;
            }
        }

        WGPUBindGroupLayoutDescriptor bgroupdesc;
        bgroupdesc.entryCount = cast(uint)bglentries.length;
        bgroupdesc.entries = bglentries.ptr;
        WGPUBindGroupLayout bgroupLayout = wgpuDeviceCreateBindGroupLayout(ctx.getDevice(), &bgroupdesc);

        WGPUBindGroupDescriptor bgdesc;
        bgdesc.entries = bgentries.ptr;
        bgdesc.entryCount = cast(uint)bgentries.length;
        bgdesc.layout = bgroupLayout;

        bgroup = wgpuDeviceCreateBindGroup(ctx.getDevice(), &bgdesc);

        WGPUPipelineLayoutDescriptor pldesc;
        pldesc.bindGroupLayoutCount = 1;
        pldesc.bindGroupLayouts = &bgroupLayout;

        desc.layout = wgpuDeviceCreatePipelineLayout(ctx.getDevice, &pldesc);
        pipeline = wgpuDeviceCreateRenderPipeline(ctx.getDevice(), &desc);
    }

public:

    /// Constructor
    this(SbGFXContext ctx, SbGFXTextureView mainTarget, string name="Pipeline") {
        this.ctx = ctx;
        this.name = name.toStringz;
        this.targets ~= mainTarget;
    }

    /**
        Finalizes the pipeline, making it usable for rendering
    */
    void finalize() {

        // if the pipeline already exists, erase it
        if (pipeline) wgpuRenderPipelineDrop(pipeline);
        this.generatePipelineObject();
    }

    /**
        Adds a buffer to the pipeline
    */
    void addVertexBuffer(SbGFXBufferBaseI buffer) {
        enforce(buffer.getType() == SbGFXBufferType.Vertex, "Invalid buffer type!");
        this.buffers ~= buffer;
    }

    /**
        Adds a uniform buffer to the pipeline
    */
    void setUniformBuffer(SbGFXBufferBaseI buffer, int bindloc) {
        enforce(buffer.getType() == SbGFXBufferType.Uniform, "Invalid buffer type!");
        this.bindgroups[bindloc] = SbGFXPipelineGroup(bindloc, buffer);
    }

    /**
        Adds a texture to the pipeline
    */
    void setTexture(SbGFXTexture texture, int bindloc) {
        this.bindgroups[bindloc] = SbGFXPipelineGroup(bindloc, texture);
    }

    /**
        Adds a rendering target to the pipeline
    */
    void addRenderTarget(SbGFXTextureView texture) {
        this.targets ~= texture;
    }

    /**
        Sets the shader of the pipeline
    */
    void setShader(SbGFXShader shader, string vertMain = "vs_main", string fragMain = "fs_main") {
        this.vertMain = vertMain.toStringz;
        this.fragMain = fragMain.toStringz;
        this.shader = shader;
    }

    /**
        Sets the rendering topology
    */
    void setTopology(SbGFXPrimitiveTopology topology) {
        this.topology = topology;
    }

    /**
        Sets the rendering culling mode
    */
    void setCullMode(SbGFXCullMode culling) {
        this.culling = culling;
    }

    /**
        Sets the rendering culling mode
    */
    void setWinding(SbGFXWindingOrder winding) {
        this.winding = winding;
    }

    /**
        Sets the rendering multisample amount
    */
    void setMSAA(int msaa) {
        this.msaa = msaa;
    }

    /**
        Sets the blending function for the color and alpha channels
    */
    void setBlendFunc(SbGFXBlendFactor sfactor, SbGFXBlendFactor dfactor) {
        this.setBlendFuncColor(sfactor, dfactor);
        this.setBlendFuncAlpha(sfactor, dfactor);
    }

    /**
        Sets the blending function for the color channels
    */
    void setBlendFuncColor(SbGFXBlendFactor sfactor, SbGFXBlendFactor dfactor) {
        sfactor = sfactor;
        dfactor = dfactor;
    }

    /**
        Sets the blending function for the alpha channel
    */
    void setBlendFuncAlpha(SbGFXBlendFactor sfactor, SbGFXBlendFactor dfactor) {
        sfactorA = sfactor;
        dfactorA = dfactor;
    }

    /**
        Sets the blending equation operation
    */
    void setBlendEquation(SbGFXBlendOperation bop) {
        bop = bop;
    }

    /**
        Whether the pipeline is ready for use
    */
    bool isReady() {
        return pipeline !is null;
    }

    /// Returns the underlying WGPU handle
    final
    WGPURenderPipeline getHandle() {
        return pipeline;
    }

    /// Returns the underlying WGPU handle
    final
    WGPUBindGroup getBindGroupHandle() {
        return bgroup;
    }
}