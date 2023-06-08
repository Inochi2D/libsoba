module soba.core.gpu.wgpu;
import soba.core.gpu;
import soba.core.gpu.surface;
import soba.core.gpu.texture;
import soba.core.gpu.buffer;
import soba.core.gpu.shader;
import soba.core.gpu.wgpu.surface;
import bindbc.wgpu;
import bindbc.sdl;
import std.exception;
import imagefmt;
import soba.core.gpu.wgpu.texture;
import soba.core.gpu.wgpu.buffer;
import soba.core.gpu.wgpu.shader;


private {
    __gshared WGPUInstance winstance;
    __gshared bool wgpuInitialized = false;

    extern(C)
    void sbGPUCtxAdapterCallback(WGPURequestAdapterStatus status, WGPUAdapter adapter, const(char)* message, void* userdata) {
        *cast(WGPUAdapter*)userdata = adapter;
    }

    extern(C)
    void sbGPUCtxDeviceCallback(WGPURequestDeviceStatus status, WGPUDevice device, const(char)* message, void* userdata) {
        *cast(WGPUDevice*)userdata = device;
    }
}

class SbWGPUContext : SbGPUContext {
private:

    void createAdapter() {

        // Request an adapter
        WGPURequestAdapterOptions options;
        options.powerPreference = WGPUPowerPreference.LowPower;
        wgpuInstanceRequestAdapter(winstance, &options, &sbGPUCtxAdapterCallback, &adapter);
    }

    void createDevice() {

        // Request a device
        WGPUDeviceDescriptor deviceDesc;
        WGPURequiredLimits limits;
        limits.limits.maxTextureDimension1D = 2048;
        limits.limits.maxTextureDimension2D = 2048;
        limits.limits.maxTextureDimension3D = 256;
        limits.limits.maxTextureArrayLayers = 256;
        limits.limits.maxBindGroups = 4;
        limits.limits.maxBindingsPerBindGroup = 640;
        limits.limits.maxDynamicUniformBuffersPerPipelineLayout = 8;
        limits.limits.maxDynamicStorageBuffersPerPipelineLayout = 4;
        limits.limits.maxSampledTexturesPerShaderStage = 16;
        limits.limits.maxSamplersPerShaderStage = 16;
        limits.limits.maxStorageBuffersPerShaderStage = 4;
        limits.limits.maxStorageTexturesPerShaderStage = 4;
        limits.limits.maxUniformBuffersPerShaderStage = 12;
        limits.limits.maxUniformBufferBindingSize = 16 << 10;
        limits.limits.maxStorageBufferBindingSize = 128 << 20;
        limits.limits.maxVertexBuffers = 8;
        limits.limits.maxVertexAttributes = 16;
        limits.limits.maxVertexBufferArrayStride = 2048;
        limits.limits.minUniformBufferOffsetAlignment = 256;
        limits.limits.minStorageBufferOffsetAlignment = 256;
        limits.limits.maxInterStageShaderComponents = 60;
        limits.limits.maxComputeWorkgroupStorageSize = 16352;
        limits.limits.maxComputeInvocationsPerWorkgroup = 256;
        limits.limits.maxComputeWorkgroupSizeX = 256;
        limits.limits.maxComputeWorkgroupSizeY = 256;
        limits.limits.maxComputeWorkgroupSizeZ = 64;
        limits.limits.maxComputeWorkgroupsPerDimension = 65535;
        limits.limits.maxBufferSize = 1 << 28;
        deviceDesc.requiredLimits = &limits;
        wgpuAdapterRequestDevice(adapter, &deviceDesc, &sbGPUCtxDeviceCallback, &device);
    }

    void createQueue() {
        queue = wgpuDeviceGetQueue(device);
    }

protected:
    SbGPUCreationTargetI target;
    SbGPUSurface surface;
    WGPUAdapter adapter;
    WGPUDevice device;
    WGPUQueue queue;

public:
    ~this() {
        wgpuDeviceDrop(device);
        wgpuAdapterDrop(adapter);
    }

    this() { }

    /**
        The type of GPU context
    */
    override
    SbGPUContextType getContextType() {
        return SbGPUContextType.WebGPU;
    }

    /**
        Setup function called for initial window creation
    
        Dummy function in WGPU
    */
    override
    void setupForTarget(SbGPUCreationTargetI target) {
        this.target = target;

        createAdapter();
        createDevice();
        createQueue();

        surface = new SbWGPUSurface(this, target);
    }
    
    /**
        Makes the context current. (OpenGL only)
    */
    override
    void makeCurrent() { }

    /**
        Gets the target of the context
    */
    override
    ref SbGPUCreationTargetI getTarget() { return target; }

    /**
        Gets the target of the context
    */
    override
    ref SbGPUSurface getSurface() { return surface; }

    /**
        Gets WGPU adapter
    */
    ref WGPUAdapter getAdapter() { return adapter; }
    
    /**
        Gets WGPU device
    */
    ref WGPUDevice getDevice() { return device; }
    
    /**
        Gets WGPU queue
    */
    ref WGPUDevice getQueue() { return queue; }

    /**
        Creates a new texture
    */
    override
    SbGPUTexture createTexture(int width, int height, SbGPUTextureFormat format) {
        return new SbWGPUTexture(this, width, height, format);
    }

    /**
        Creates a new texture
    */
    override
    SbGPUTexture createTexture(ref IFImage image) {
        return new SbWGPUTexture(this, image);
    }

    /**
        Creates a new texture
    */
    override
    SbGPUTexture createTexture(ubyte[] data, int width, int height, SbGPUTextureFormat format) {
        return new SbWGPUTexture(this, data, width, height, format);
    }
    
    /**
        Creates a new index buffer
    */
    override
    SbGPUBuffer createIndexBuffer(size_t size) {
        return new SbWGPUBuffer(this, SbGPUBufferType.Index, size);
    }

    /**
        Creates a new index buffer
    */
    override
    SbGPUBuffer createIndexBuffer(void* initialData, size_t length) {
        return new SbWGPUBuffer(this, SbGPUBufferType.Index, initialData, length);
    }

    /**
        Creates a new vertex buffer
    */
    override
    SbGPUBuffer createVertexBuffer(size_t size) {
        return new SbWGPUBuffer(this, SbGPUBufferType.Vertex, size);
    }

    /**
        Creates a new vertex buffer
    */
    override
    SbGPUBuffer createVertexBuffer(void* initialData, size_t length) {
        return new SbWGPUBuffer(this, SbGPUBufferType.Vertex, initialData, length);
    }

    /**
        Creates a new uniform buffer
    */
    override
    SbGPUBuffer createUniformBuffer(size_t size) {
        return new SbWGPUBuffer(this, SbGPUBufferType.Uniform, size);
    }

    /**
        Creates a new uniform buffer
    */
    override
    SbGPUBuffer createUniformBuffer(void* initialData, size_t length) {
        return new SbWGPUBuffer(this, SbGPUBufferType.Uniform, initialData, length);
    }
    
    /**
        Creates a new shader object with the specified variants.
    */
    override
    SbGPUShaderObject createShader(SbGPUShaderCodeVariant[] variants) {
        return new SbWGPUShaderObject(this, variants);
    }
}

/**
    Returns the active WGPU instance
*/
WGPUInstance sbWGPUGetInstance() {
    return winstance;
}

/**
    Initializes WGPU support
*/
void sbWGPUInit() {
    
    // Load WGPU if not loaded yet.
    if (!wgpuInitialized) {
        auto wgpuSupport = loadWGPU();
        enforce(wgpuSupport != WGPUSupport.noLibrary, "WGPU was not found!");

        // Create WGPU instance
        WGPUInstanceDescriptor desc;
        desc.nextInChain = null;
        winstance = wgpuCreateInstance(&desc);

        wgpuInitialized = true;
    }
}