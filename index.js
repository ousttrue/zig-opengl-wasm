class Logger {
    constructor() {
        this.buffer = [];
    }

    logger(severity, ptr, len) {
        this.push(severity, memToString(ptr, len));
    }

    push(severity, last) {
        this.buffer.push(last);
        if (last.length > 0 && last[last.length - 1] == '\n') {
            const message = this.buffer.join('');
            this.buffer = [];
            switch (severity) {
                case 0:
                    console.error(message);
                    break;

                case 1:
                    console.warn(message);
                    break;

                case 2:
                    console.info(message);
                    break;

                default:
                    console.debug(message);
                    break;
            }
        }
    }
}
const g_logger = new Logger();

const canvas = document.querySelector("#gl");
const webglOptions = {
    alpha: true, //Boolean that indicates if the canvas contains an alpha buffer.
    antialias: true,  //Boolean that indicates whether or not to perform anti-aliasing.
    depth: 32,  //Boolean that indicates that the drawing buffer has a depth buffer of at least 16 bits.
    failIfMajorPerformanceCaveat: false,  //Boolean that indicates if a context will be created if the system performance is low.
    powerPreference: "default", //A hint to the user agent indicating what configuration of GPU is suitable for the WebGL context. Possible values are:
    premultipliedAlpha: true,  //Boolean that indicates that the page compositor will assume the drawing buffer contains colors with pre-multiplied alpha.
    preserveDrawingBuffer: true,  //If the value is true the buffers will not be cleared and will preserve their values until cleared or overwritten by the author.
    stencil: true, //Boolean that indicates that the drawing buffer has a stencil buffer of at least 8 bits.
};

/**
 * @type WebGL2RenderingContext
 */
const gl = canvas.getContext('webgl2', webglOptions);
if (gl === null) {
    throw "WebGL を初期化できません。ブラウザーまたはマシンが対応していない可能性があります。";
}

const getMemory = () => new DataView(instance.exports.memory.buffer);

const memGet = (ptr, len) => new Uint8Array(getMemory().buffer, ptr, len);

const memToString = (ptr, len) => {
    let array = null;
    if (len) {
        array = memGet(ptr, len);
    }
    else {
        // zero terminated
        let i = 0;
        const buffer = new Uint8Array(getMemory().buffer, ptr);
        for (; i < buffer.length; ++i) {
            if (buffer[i] == 0) {
                break;
            }
        }
        array = new Uint8Array(getMemory().buffer, ptr, i);
    }
    const decoder = new TextDecoder()
    const text = decoder.decode(array)
    return text;
}

const memAllocString = (src) => {
    const buffer = (new TextEncoder).encode(src);
    const dstPtr = instance.exports.getGlobalAddress();
    const dst = new Uint8Array(getMemory().buffer, dstPtr, buffer.length);
    for (let i = 0; i < buffer.length; ++i) {
        dst[i] = buffer[i];
    }
    return dstPtr;
}

const memSetString = (dstPtr, maxLength, length, src) => {
    const buffer = (new TextEncoder).encode(src);
    const dst = new Uint8Array(getMemory().buffer, dstPtr, buffer.length);
    for (let i = 0; i < buffer.length && i < maxLength; ++i) {
        dst[i] = buffer[i];
    }
    const write_length = Math.min(buffer.len, maxLength);
    if (length) {
        getMemory().setUint32(length, write_length, true);
    }
    return write_length;
}

// 0 origin
const glUniformLocations = [];
// 1 origin
const glVertexArrays = [];
const glPrograms = [];
const glShaders = [];
const glBuffers = [];
const glTextures = [];

const importObject = {
    env: {
        console_logger: (level, ptr, len) => g_logger.logger(level, ptr, len),
        //
        getString: (name) => {
            const param = gl.getParameter(name);
            if (typeof (param) == "string") {
                return memAllocString(param);
            }
            else {
                return memAllocString("no getString");
            }
        },
        isEnabled: (cap) => gl.isEnabled(cap),
        viewport: (x, y, width, height) => gl.viewport(x, y, width, height),
        scissor: (x, y, width, height) => gl.scissor(x, y, width, height),
        clear: (x) => gl.clear(x),
        clearColor: (r, g, b, a) => gl.clearColor(r, g, b, a),
        genBuffers: (num, dataPtr) => {
            for (let n = 0; n < num; n++, dataPtr += 4) {
                glBuffers.push(gl.createBuffer());
                getMemory().setUint32(dataPtr, glBuffers.length, true);
            }
        },
        bindBuffer: (type, bufferId) => {
            if (bufferId > 0) {
                gl.bindBuffer(type, glBuffers[bufferId - 1]);
            }
            else {
                gl.bindBuffer(type, null);
            }
        },
        bufferData: (type, count, dataPtr, drawType) => {
            const data = new Uint8Array(getMemory().buffer, Number(dataPtr), Number(count));
            gl.bufferData(type, data, drawType);
        },
        bufferSubData: (target, offset, size, dataPtr) => {
            const data = new Uint8Array(getMemory().buffer, Number(dataPtr), Number(size));
            gl.bufferSubData(target, offset, data);
        },
        createShader: (shaderType) => {
            glShaders.push(gl.createShader(shaderType));
            return glShaders.length;
        },
        deleteShader: (shader) => {
            if (shader > 0) {
                gl.deleteShader(glShaders[shader - 1]);
            }
        },
        shaderSource: (shader, count, srcs) => {
            if (shader <= 0) {
                return;
            }
            let list = [];
            for (let i = 0; i < count; ++i, srcs += 4) {
                const p = getMemory().getUint32(srcs, true);
                const item = memToString(p);
                list.push(item);
            }
            gl.shaderSource(glShaders[shader - 1], list.join(""));
        },
        compileShader: (shader) => {
            if (shader <= 0) {
                return;
            }
            gl.compileShader(glShaders[shader - 1]);
        },
        getShaderiv: (shader, pname, params) => {
            if (shader <= 0) {
                return;
            }
            const param = gl.getShaderParameter(glShaders[shader - 1], pname);
            if (pname == gl.COMPILE_STATUS) {
                if (param) {
                    // gl.GL_TRUE
                    getMemory().setUint32(params, 1, true);
                }
                else {
                    // gl.GL_TRUE
                    getMemory().setUint32(params, 0, true);
                }
            }
            else if (Number.isInteger(param)) {
                getMemory().setUint32(params, param, true);
            }
            else {
                console.warn(`getShaderParameter ${pname}: ${param}`);
            }
        },
        getShaderInfoLog: (shader, maxLength, length, infoLog) => {
            if (shader <= 0) {
                return;
            }
            const message = gl.getShaderInfoLog(glShaders[shader - 1]);
            if (typeof (message) == "string") {
                memSetString(infoLog, maxLength, length, message);
            }
            else {
                getMemory().setUint32(length, 0, true);
            }
        },
        createProgram: () => {
            glPrograms.push(gl.createProgram());
            return glPrograms.length;
        },
        attachShader: (program, shader) => {
            if (program <= 0) {
                return;
            }
            if (shader <= 0) {
                return;
            }
            gl.attachShader(glPrograms[program - 1], glShaders[shader - 1]);
        },
        detachShader: (program, shader) => {
            if (program <= 0) {
                return;
            }
            if (shader <= 0) {
                return;
            }
            gl.detachShader(glPrograms[program - 1], glShaders[shader - 1]);
        },
        linkProgram: (program) => {
            if (program <= 0) {
                return;
            }
            gl.linkProgram(glPrograms[program - 1]);
        },
        getProgramiv: (program, pname, params) => {
            if (program <= 0) {
                return;
            }
            const param = gl.getProgramParameter(glPrograms[program - 1], pname);
            if (pname == gl.LINK_STATUS) {
                if (param) {
                    // gl.GL_TRUE
                    getMemory().setUint32(params, 1, true);
                }
                else {
                    // gl.GL_TRUE
                    getMemory().setUint32(params, 0, true);
                }
            }
            else if (Number.isInteger(param)) {
                getMemory().setUint32(params, param, true);
            }
            else {
                console.warn(`getProgramParameter ${pname}: ${param}`);
            }
        },
        getProgramInfoLog: (program, maxLength, length, infoLog) => {
            if (program <= 0) {
                return;
            }
            const message = gl.getProgramInfoLog(glPrograms[program - 1]);
            if (typeof (message) == "string") {
                memSetString(infoLog, maxLength, length, message);
            }
            else {
                getMemory().setUint32(length, 0, true);
            }
        },
        getUniformLocation: (program, name) => {
            if (program <= 0) {
                return;
            }
            glUniformLocations.push(gl.getUniformLocation(glPrograms[program - 1], memToString(name)));
            return glUniformLocations.length - 1;
        },
        getAttribLocation: (program, name) => {
            if (program <= 0) {
                return;
            }
            return gl.getAttribLocation(glPrograms[program - 1], memToString(name));
        },
        enableVertexAttribArray: (index) => gl.enableVertexAttribArray(index),
        vertexAttribPointer: (index, size, type, normalized, stride, offset) => {
            gl.vertexAttribPointer(index, size, type, normalized, stride, Number(offset));
        },
        useProgram: (program) => {
            if (program <= 0) {
                return;
            }
            gl.useProgram(glPrograms[program - 1]);
        },
        uniformMatrix4fv: (location, count, transpose, value) => {
            const values = new Float32Array(getMemory().buffer, value, 16 * count);
            gl.uniformMatrix4fv(glUniformLocations[location], transpose, values);
        },
        uniform1i: (location, v0) => gl.uniform1i(glUniformLocations[location], v0),
        drawArrays: (mode, first, count) => gl.drawArrays(mode, first, count),
        drawElements: (mode, count, type, offset) => {
            gl.drawElements(mode, count, type, Number(offset));
        },
        getIntegerv: (pname, data) => {
            const param = gl.getParameter(pname);
            if (gl.getError() == gl.NO_ERROR) {
                if (!param) {
                    getMemory().setUint32(data, 0, true);
                }
                else if (param instanceof Int32Array) {
                    const buffer = new Int32Array(getMemory().buffer, data, param.length);
                    for (let i = 0; i < buffer.length; ++i) {
                        buffer[i] = param[i];
                    }
                    // console.log(`${pname} => ${buffer}`);
                }
                else if (Number.isInteger(param)) {
                    getMemory().setUint32(data, param, true);
                }
                else if (param instanceof WebGLProgram) {
                    getMemory().setUint32(data, glPrograms.indexOf(param) + 1, true);
                }
                else if (param instanceof WebGLTexture) {
                    getMemory().setUint32(data, glTextures.indexOf(param) + 1, true);
                }
                else if (param instanceof WebGLBuffer) {
                    getMemory().setUint32(data, glBuffers.indexOf(param) + 1, true);
                }
                else {
                    console.log(`unknown param type: ${getPname(pname)} ${typeof (param)}`);
                    getMemory().setUint32(data, -1, true);
                }
            }
            else {
                console.warn(`unknown param: ${getPname(pname)}`);
            }
        },
        bindTexture: (target, texture) => {
            if (texture <= 0) {
                gl.bindTexture(target, null);
            }
            else {
                gl.bindTexture(target, glTextures[texture - 1]);
            }
        },
        texImage2D: (target, level, internalFormat, width, height, border, format, type, data) => {
            let pixels = null;
            switch (format) {
                case gl.RGBA:
                    pixels = memGet(data, width * height * 4);
                    break;
                default:
                    logger.error(`unknown ${format}`);
                    break;
            }
            gl.texImage2D(target, level, internalFormat, width, height, border, format, type, pixels);
        },
        activeTexture: (texture) => gl.activeTexture(texture),
        genTextures: (n, textures) => {
            for (let i = 0; i < n; ++i, textures += 4) {
                glTextures.push(gl.createTexture());
                getMemory().setUint32(textures, glTextures.length, true);
            }
        },
        texParameteri: (target, pname, param) => gl.texParameteri(target, pname, param),
        pixelStorei: (pname, param) => gl.pixelStorei(pname, param),
        genVertexArrays: (n, arrays) => {
            let ptr = arrays;
            for (let i = 0; i < n; ++i, ptr += 4) {
                glVertexArrays.push(gl.createVertexArray());
                getMemory().setUint32(ptr, glVertexArrays.length, true);
            }
        },
        deleteVertexArrays: (n, array) => {
            for (let i = 0; i < n; ++i, array += 4) {
                const index = getMemory().getUint32(array, true);
                gl.deleteVertexArray(glVertexArrays[index - 1]);
            }
        },
        bindVertexArray: (array) => {
            if (array > 0) {
                gl.bindVertexArray(glVertexArrays[array - 1]);
            }
            else {
                gl.bindVertexArray(null);

            }
        },
        enable: (cap) => gl.enable(cap),
        disable: (cap) => gl.disable(cap),
        blendEquation: (mode) => gl.blendEquation(mode),
        blendFuncSeparate: (srcRGB, dstRGB, srcAlpha, dstAlpha) => gl.blendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha),
        blendEquationSeparate: (modeRGB, modeAlpha) => gl.blendEquationSeparate(modeRGB, modeAlpha),
    }
};

// get
const response = await fetch('zig-out/lib/engine.wasm')
// byte array
const buffer = await response.arrayBuffer();
// compile
const compiled = await WebAssembly.compile(buffer);
// instanciate env に webgl などを埋め込む
const instance = await WebAssembly.instantiate(compiled, importObject);
console.log(instance);

// call
instance.exports.ENGINE_init(null);
function step(timestamp) {
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    canvas.width = w;
    canvas.height = h;
    instance.exports.ENGINE_render(w, h);
    window.requestAnimationFrame(step);
}
window.requestAnimationFrame(step);
