module soba.core.gpu.pipeline;
import soba.core.gpu;
import bindbc.wgpu;
import std.string;

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

class SbGFXPipeline {
private:
    const(char)* name;
    SbGFXContext ctx;

    // Pipeline
    SbGFXPrimitiveTopology topology = SbGFXPrimitiveTopology.Triangles;
    SbGFXCullMode culling = SbGFXCullMode.Back;
    int msaa = 1;
    SbGFXBlendFactor sfactor = SbGFXBlendFactor.Src, sfactorA = SbGFXBlendFactor.Src;
    SbGFXBlendFactor dfactor = SbGFXBlendFactor.OneMinusSrcAlpha, dfactorA = SbGFXBlendFactor.OneMinusSrcAlpha;
    SbGFXBlendOperation bop = SbGFXBlendOperation.Add;
    WGPURenderPipelineDescriptor desc;
    WGPURenderPipeline pipeline;

    // Pipeline data
    const(char)* fragMain;
    const(char)* vertMain;
    SbGFXShader shader;
    SbGFXBufferBaseI[] buffers;
    SbGFXTexture[] textures;
    SbGFXTextureView[] targets;

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

        // Primitives
        desc.primitive = WGPUPrimitiveState(
            null,
            cast(WGPUPrimitiveTopology)topology,
            WGPUIndexFormat.Uint32,
            WGPUFrontFace.CCW,
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
        Adds a texture to the pipeline
    */
    void addTexture(SbGFXTexture texture) {
        this.shader = shader;
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
    bool ready() {
        return pipeline !is null;
    }

    /// Returns the underlying WGPU handle
    final
    WGPURenderPipeline getHandle() {
        return pipeline;
    }
}