module soba.core.gpu.gl.shader;
import soba.core.gpu.gl;
import soba.core.gpu.shader;
import bindbc.opengl;
import std.string;
import std.format;
import std.exception;

class SbGLShaderObject : SbGPUShaderObject {
private:
    SbGLContext context;
    GLuint vao;
    GLuint vertexShader;
    GLuint fragmentShader;
    GLuint program;
    bool complete = false;

    SbGPUShaderCodeVariant[2] findGLShaders(SbGPUShaderCodeVariant[] variants) {
        SbGPUShaderCodeVariant* vertex, fragment;
        foreach(ref variant; variants) {
            if (variant.backend == context.getContextType()) {
                enforce(!variant.isBytecode, "SPIR-V is not supported in the OpenGL backend!");

                switch(variant.stage) {

                    case SbGPUShaderStageFlags.Vertex:
                        vertex = &variant;
                        break;

                    case SbGPUShaderStageFlags.Fragment:
                        fragment = &variant;
                        break;

                    default: 
                        throw new Exception("Unsupported shader type '%s'!".format(variant.stage));    
                }
            }
        }

        enforce(vertex, "Vertex shader stage is missing!");
        enforce(fragment, "Fragment shader stage is missing!");
        return [*vertex, *fragment];
    }

    void compileShaders(string vertex, string fragment) {

        // Compile vertex shader
        vertexShader = glCreateShader(GL_VERTEX_SHADER);
        auto c_vert = vertex.toStringz;
        glShaderSource(vertexShader, 1, &c_vert, null);
        glCompileShader(vertexShader);
        verifyShader(vertexShader);

        // Compile fragment shader
        fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
        auto c_frag = fragment.toStringz;
        glShaderSource(fragmentShader, 1, &c_frag, null);
        glCompileShader(fragmentShader);
        verifyShader(fragmentShader);

        // Attach and link them
        program = glCreateProgram();
        glAttachShader(program, vertexShader);
        glAttachShader(program, fragmentShader);
        glLinkProgram(program);
        verifyProgram();
    }

    void verifyShader(GLuint shader) {

        int compileStatus;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &compileStatus);
        if (compileStatus == GL_FALSE) {

            // Get the length of the error log
            GLint logLength;
            glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
            if (logLength > 0) {

                // Fetch the error log
                char[] log = new char[logLength];
                glGetShaderInfoLog(shader, logLength, null, log.ptr);

                throw new Exception(cast(string)log);
            }
        }
    }

    void verifyProgram() {

        int linkStatus;
        glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
        if (linkStatus == GL_FALSE) {

            // Get the length of the error log
            GLint logLength;
            glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
            if (logLength > 0) {

                // Fetch the error log
                char[] log = new char[logLength];
                glGetProgramInfoLog(program, logLength, null, log.ptr);

                throw new Exception(cast(string)log);
            }
        } else complete = true;
    }

public:
    this(SbGLContext context, SbGPUShaderCodeVariant[] variants) {
        this.context = context;

        glGenVertexArrays(1, &vao);
        SbGPUShaderCodeVariant[2] shaders = findGLShaders(variants);
        compileShaders(shaders[0].code, shaders[1].code);
    }

    /**
        Gets handle to OpenGL program
    */
    GLuint getProgram() {
        return program;
    }

    /**
        Gets handle to OpenGL vertex array
    */
    GLuint getVertexArray() {
        return vao;
    }
    
    /**
        Gets whether the shader object is complete
    */
    override
    bool isComplete() {
        return complete;
    }
}