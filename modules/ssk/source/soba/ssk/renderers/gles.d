module soba.ssk.renderers.gles;
import soba.ssk.renderers;
import soba.ssk.texture;
import soba.sio;
import numem.all;
import numem.mem.utils;
import inmath;

import bindbc.gles.gles;


enum sskBaseVtxShaderGLES = "
#version 100
uniform mat4 mvp;

layout(location = 0) in vec2 vtxIn;
layout(location = 1) in vec2 uvIn;

out vec2 uvOut;

void main() {
    gl_Position = mvp * vec4(vtxIn.x, vtxIn.y, 0, 1);
    uvOut = uvIn;
}\0";

enum sskBaseFragShaderGLES = "
#version 100
in vec2 uvOut;

uniform sampler2D texIn;

layout(location = 0) out vec4 colorOut;

void main() {
    colorOut = texture(texIn, uvOut);
}\0";

class SskGLESRenderer : SskRenderer {
@nogc:
private:
    GLuint vao;
    GLuint vbo;

    GLuint program;
    
    GLuint createShader(GLenum type, const(char)* code) {
        GLuint shader = glCreateShader(type);
        glShaderSource(shader, 1, &code, null);
        glCompileShader(shader);

        int success;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
        if (!success) {
            int logLen;
            glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLen);

            nstring errText;
            errText.resize(logLen);

            glGetShaderInfoLog(shader, logLen, null, cast(char*)errText.ptr);
            throw nogc_new!NuException(errText);
        }

        return shader;
    }

    GLuint createShaderProgram(const(char)* vtx, const(char)* frag) {
        GLuint vtxShader = createShader(GL_VERTEX_SHADER, vtx);
        GLuint fragShader = createShader(GL_FRAGMENT_SHADER, frag);

        GLuint prog = glCreateProgram();
        glAttachShader(prog, vtxShader);
        glAttachShader(prog, fragShader);
        glLinkProgram(prog);

        // Should be linked by now.
        // Which means we can free these.
        glDeleteShader(vtxShader);
        glDeleteShader(fragShader);

        int success;
        glGetProgramiv(prog, GL_LINK_STATUS, &success);
        if (!success) {

            int logLen;
            glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLen);

            nstring errText;
            errText.resize(logLen);

            glGetProgramInfoLog(prog, logLen, null, cast(char*)errText.ptr);
            throw nogc_new!NuException(errText);
        }

        return prog;
    }
public:
    this(SioWindow window) {
        super(window);
        window.makeCurrent();

        // NOTE: For some reason the dev of this binding didn't make it nogc??
        auto esLoader = assumeNothrowNoGC(&loadGLES);
        enforce(esLoader() != GLESSupport.noLibrary, nstring("Failed to establish OpenGL ES context."));
    
        glGenBuffers(1, &vbo);
        glGenVertexArrays(1, &vao);
        program = createShaderProgram(sskBaseVtxShaderGLES, sskBaseFragShaderGLES);
    }

    override
    SskTexture createTexture(SskTextureFormat format, SskTextureKind kind, uint width, uint height) {
        return nogc_new!SskGLESTexture(format, kind, width, height);
    }

    override
    void begin() {
        glEnable(GL_SCISSOR_TEST);
    }

    override
    void end() {
        glDisable(GL_SCISSOR_TEST);
    }

    override
    void setScissor(recti scissor) {
        vec2i wsize = this.getWindow().getFramebufferSize();
        glScissor(scissor.left, wsize.y-scissor.y, scissor.width, scissor.height);
    }

    /**
        Renders texture to the specified area
    */
    override
    void renderTextureTo(SskTexture texture, recti at) {

    }

    /**
        Sets texture to render target.
        Type of texture MUST be framebuffer.

        Set to null to render to the window once again.
    */
    override
    void renderToTexture(SskTexture texture) {

    }
}


class SskGLESTexture : SskTexture {
@nogc:
private:
    GLuint handle;
    GLuint fbTexHandle;

    uint width, height;

    void create() {
        if (this.getKind() == SskTextureKind.image) {
            glGenTextures(1, &handle);
            glBindTexture(GL_TEXTURE_2D, handle);
            glTexImage2D(
                GL_TEXTURE_2D,
                0,
                GL_RGBA,
                width,
                height,
                0,
                this.getFormat() == SskTextureFormat.RGB ? GL_RGB : GL_RGBA,
                GL_UNSIGNED_BYTE,
                null
            );
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);  

        } else {
            glGenTextures(1, &fbTexHandle);
            glGenFramebuffers(1, &handle);

            glBindTexture(GL_TEXTURE_2D, handle);
            glTexImage2D(
                GL_TEXTURE_2D,
                0,
                GL_RGBA,
                width,
                height,
                0,
                GL_RGBA,
                GL_UNSIGNED_BYTE,
                null
            );
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 

            glBindFramebuffer(GL_FRAMEBUFFER, handle);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, fbTexHandle, 0);
        }
    }

public:
    ~this() {
        final switch(this.getKind()) {
            case SskTextureKind.image:
                glDeleteTextures(1, &handle);
                break;

            case SskTextureKind.framebuffer:
                glDeleteFramebuffers(1, &handle);
                glDeleteTextures(1, &fbTexHandle);
                break;
        }
    }

    this(SskTextureFormat format, SskTextureKind kind, uint width, uint height) {
        super(format, kind, width, height);

        this.width = width;
        this.height = height;

        this.create();
    }

    /**
        Gets the render-api specific handle
    */
    override
    SskTextureRef getHandle() {
        return cast(SskTextureRef)handle;
    }

    /**
        Resizes the texture
    */
    override
    void resize(uint width, uint height) {
        this.width = width;
        this.height = height;

        glBindTexture(GL_TEXTURE_2D, this.getKind() == SskTextureKind.framebuffer ? fbTexHandle : handle);
        glTexImage2D(
            GL_TEXTURE_2D,
            0,
            GL_RGBA,
            width,
            height,
            0,
            GL_RGBA,
            GL_UNSIGNED_BYTE,
            null
        );
    }

    /**
        Gets the width of the texture
    */
    override
    uint getWidth() {
        return width;
    }

    /**
        Gets the height of the texture
    */
    override
    uint getHeight() {
        return height;
    }

    override
    void upload(SskTextureFormat format, ubyte[] data, uint width, uint height) {
        if (this.getKind() == SskTextureKind.image) {
            glBindTexture(GL_TEXTURE_2D, handle);
            glTexImage2D(
                GL_TEXTURE_2D,
                0,
                GL_RGBA,
                width,
                height,
                0,
                GL_RGBA,
                GL_UNSIGNED_BYTE,
                null
            );

            glGenerateMipmap(GL_TEXTURE_2D);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
    }
}