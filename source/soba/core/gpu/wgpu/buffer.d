module soba.core.gpu.wgpu.buffer;
import soba.core.gpu.buffer;
import soba.core.gpu.wgpu;
import bindbc.wgpu;

class SbWGPUBuffer : SbGPUBuffer {
private:
    SbGPUBufferType type;
    SbWGPUContext context;

    WGPUBufferDescriptor desc;
    WGPUBuffer buffer;

    void createBuffer(size_t size) {

        // Set usage
        desc.usage = WGPUBufferUsage.CopySrc | WGPUBufferUsage.CopyDst;
        switch(type) {
            case SbGPUBufferType.Vertex:
                desc.usage |= WGPUBufferUsage.Vertex;
                break;
            case SbGPUBufferType.Index:
                desc.usage |= WGPUBufferUsage.Index;
                break;
            case SbGPUBufferType.Uniform:
                desc.usage |= WGPUBufferUsage.Uniform;
                break;
            default: break;
        }

        desc.size = cast(ulong)size;
        desc.mappedAtCreation = false;
        desc.nextInChain = null;
        desc.label = "Buffer";
        buffer = wgpuDeviceCreateBuffer(context.getDevice(), &desc);
    }
    
public:

    /// Destructor
    ~this() {
        wgpuBufferDrop(buffer);
    }

    /**
        Creates a buffer with no data but a preallocated size
    */
    this(SbWGPUContext context, SbGPUBufferType type, size_t initialSize = 1) {
        this.context = context;
        this.type = type;
        
        if (initialSize == 0) initialSize = 1;
        createBuffer(initialSize);
    }

    /**
        Creates a buffer with preallocated data
    */
    this(SbWGPUContext context, SbGPUBufferType type, void* initialData, size_t length) {
        this.context = context;
        this.type = type;
        
        if (length == 0) length = 1;
        createBuffer(length);
        this.bufferData(initialData, length);
    }

    /**
        Gets the count of attributes in the buffer
    */
    override 
    size_t getCount() {
        return attribs.length;
    }

    /**
        Gets the length of the buffer in bytes
    */
    override
    size_t getLength() {
        return cast(size_t)desc.size;
    }

    /**
        Gets the type of the buffer
    */
    override
    SbGPUBufferType getType() {
        return type;
    }

    /**
        Copies data from this buffer to the other buffer
    */
    override
    void copyTo(SbGPUBuffer other, size_t srcOffset, size_t srcLength, size_t dstOffset) {
        super.copyTo(other, srcOffset, srcLength, dstOffset);
        
        // Create encoder
        WGPUCommandEncoderDescriptor cmddesc;
        cmddesc.label = "Buffer Copy";
        auto encoder = wgpuDeviceCreateCommandEncoder(context.getDevice(), &cmddesc);

        // Instruct encoder to add a copy command to copy data from src to dst.
        wgpuCommandEncoderCopyBufferToBuffer(encoder, buffer, srcOffset, (cast(SbWGPUBuffer)other).buffer, dstOffset, srcLength);
        WGPUCommandBuffer cmdbuffer = wgpuCommandEncoderFinish(encoder, new WGPUCommandBufferDescriptor(
            null,
            "Buffer Copy"
        ));

        // Submit command to queue
        wgpuQueueSubmit(context.getQueue(), 1, &cmdbuffer);
    }

    /**
        Resizes the mapped range of the buffer
    */
    override
    void resize(size_t length) {
        size_t oldLength = this.getLength();

        // Create new descriptor with new size
        WGPUBufferDescriptor nudesc = desc;
        nudesc.size = length;

        // Create a new buffer with the new size
        WGPUBuffer newBuffer = wgpuDeviceCreateBuffer(context.getDevice(), &nudesc);

        // Encode a copy from the old buffer to the new
        WGPUCommandEncoderDescriptor cmddesc;
        cmddesc.label = "Copy Encoder";
        auto encoder = wgpuDeviceCreateCommandEncoder(context.getDevice(), &cmddesc);
        wgpuCommandEncoderCopyBufferToBuffer(encoder, buffer, 0, newBuffer, 0, oldLength);
        WGPUCommandBuffer cmdbuffer = wgpuCommandEncoderFinish(encoder, new WGPUCommandBufferDescriptor(
            null,
            "Copy Command"
        ));
        wgpuQueueSubmit(context.getQueue(), 1, &cmdbuffer);

        // Drop the old buffer and replace it with the new
        wgpuBufferDrop(buffer);
        buffer = newBuffer;
        desc = nudesc;
    }
    
    /**
        Buffers data

        offset+length MUST be shorter than buffer data length
    */
    override
    void bufferData(void* data, size_t length, size_t offset=0) {
        super.bufferData(data, length, offset);

        wgpuQueueWriteBuffer(context.getQueue(), buffer, cast(ulong)offset, data, cast(uint)length);
    }

    /**
        Finalize the attributes
    */
    override
    void finalizeAttributes() {
        attribsFinalized = true;
    }
}