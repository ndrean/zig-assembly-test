// Memory and canvas constants
const WASM_PAGE_SIZE = 65536; // 64KB
const INITIAL_PAGES = 60; // 100 x 64KB = 6.4MB
const MAXIMUM_PAGES = 150;
const IMAX = 400; // max iterations

const MandelbrotViewer = {
  memory: null,
  wasm: null,
  canvas: null,
  ctx: null,
  currentBounds: {
    min_x: -2,
    max_y: 1,
    max_x: 0.6,
    min_y: -1,
  },
  setupMemory() {
    const cols = this.canvas.width,
      rows = this.canvas.height,
      bytesNeeded = cols * rows * 4; // 4 bytes per pixel (RGBA)

    // Calculate required pages (round up)
    const pagesNeeded = Math.ceil(bytesNeeded / WASM_PAGE_SIZE);

    // Ensure we have enough initial pages
    const initialPages = Math.max(pagesNeeded, INITIAL_PAGES);

    if (initialPages > MAXIMUM_PAGES) {
      console.error(
        `Canvas size requires ${initialPages} pages, but maximum is ${MAXIMUM_PAGES}`
      );
      throw new Error("Canvas size exceeds maximum memory allocation");
    }

    this.memory = new WebAssembly.Memory({
      initial: initialPages,
      maximum: MAXIMUM_PAGES,
    });

    console.log(`Memory configuration:
      Canvas: ${cols}x${rows} (${bytesNeeded} bytes)
      Pages needed: ${pagesNeeded}
      Initial pages: ${initialPages}
      Maximum pages: ${MAXIMUM_PAGES}
      Initial memory: ${((initialPages * WASM_PAGE_SIZE) / 1024 / 1024).toFixed(
        2
      )}MB
      Maximum memory: ${(
        (MAXIMUM_PAGES * WASM_PAGE_SIZE) /
        1024 /
        1024
      ).toFixed(2)}MB
    `);
  },

  getMemoryStats() {
    if (!this.memory) return null;

    const currentBytes = this.memory.buffer.byteLength;
    const currentPages = currentBytes / WASM_PAGE_SIZE;

    return {
      currentPages,
      currentBytes,
      currentMB: (currentBytes / 1024 / 1024).toFixed(2),
      maxPages: MAXIMUM_PAGES,
      maxBytes: MAXIMUM_PAGES * WASM_PAGE_SIZE,
      maxMB: ((MAXIMUM_PAGES * WASM_PAGE_SIZE) / 1024 / 1024).toFixed(2),
    };
  },
  async initWasm() {
    try {
      const result = await WebAssembly.instantiateStreaming(fetch("/wasm"), {
        env: {
          memory: this.memory,
        },
      });

      this.wasm = result.instance;
      console.log("WASM module loaded successfully");
    } catch (error) {
      console.error("Failed to initialize WASM:", error);
      throw error;
    }
  },
  async mounted() {
    try {
      // Initialize canvas and memory management
      this.canvas = this.el;
      this.ctx = this.canvas.getContext("2d");
      this.setupMemory();
      await this.initWasm();
      console.log(this.getMemoryStats());

      // Store initial dimensions
      const cols = this.el.width,
        rows = this.el.height,
        imax = IMAX;

      const { min_x, max_x, min_y, max_y } = this.currentBounds;

      const instance = this.wasm;
      instance.exports.initialize(rows, cols, imax, min_x, max_y, max_x, min_y);

      // Get and render the initial image
      this.renderCurrentImage();

      // Set up event listeners for zooming
      this.setupEventListener();
    } catch (error) {
      console.error("Failed to initialize Mandelbrot viewer:", error);
    }
  },
  // renderWithProgressiveDetail() {
  //     // First render with low iterations
  //     this.wasm.exports.initialize(
  //         this.canvas.height,
  //         this.canvas.width,
  //         10,  // Start with few iterations
  //         this.currentBounds.min_x,
  //         this.currentBounds.max_y,
  //         this.currentBounds.max_x,
  //         this.currentBounds.min_y
  //     );
  //     // this.renderCurrentImage();

  //     // Then render with full detail
  //     setTimeout(() => {
  //         this.wasm.exports.initialize(
  //             this.canvas.height,
  //             this.canvas.width,
  //             200,  // Full iterations
  //             this.currentBounds.min_x,
  //             this.currentBounds.max_y,
  //             this.currentBounds.max_x,
  //             this.currentBounds.min_y
  //         );
  //         this.renderCurrentImage();
  //     }, 0);
  // },

  renderCurrentImage() {
    const instance = this.wasm;
    const coloursPtr = instance.exports.getColoursPointer();
    const coloursSize = instance.exports.getColoursSize();

    // Get the image data from WASM memory
    const imageData = new ImageData(
      new Uint8ClampedArray(
        instance.exports.memory.buffer,
        coloursPtr,
        coloursSize
      ),
      this.el.width,
      this.el.height
    );

    createImageBitmap(imageData).then((bitmap) =>
      this.ctx.drawImage(bitmap, 0, 0)
    );
  },
  toCartesian(canvasX, canvasY) {
    const { min_x, max_x, min_y, max_y } = this.currentBounds;
    return {
      x: min_x + (canvasX / (this.canvas.width - 1)) * (max_x - min_x),
      y: max_y - (canvasY / (this.canvas.height - 1)) * (max_y - min_y),
    };
  },
  recalculateBounds(canvasX, canvasY, { zoomIn = true } = {}) {
    const { x: newCenterX, y: newCenterY } = this.toCartesian(canvasX, canvasY);
    const { min_x, max_x, min_y, max_y } = this.currentBounds;

    const oldWidth = max_x - min_x;
    const oldHeight = max_y - min_y;

    const zoomRatio = 2; // Adjust for faster/slower zoom
    const factor = zoomIn ? 1 / zoomRatio : zoomRatio;
    const newWidth = oldWidth * factor;
    const newHeight = oldHeight * factor;

    return {
      min_x: newCenterX - newWidth / 2,
      max_x: newCenterX + newWidth / 2,
      min_y: newCenterY - newHeight / 2,
      max_y: newCenterY + newHeight / 2,
    };
  },

  setupEventListener() {
    this.canvas.addEventListener("click", (e) => {
      const rect = this.canvas.getBoundingClientRect();
      const canvasX = e.clientX - rect.left;
      const canvasY = e.clientY - rect.top;

      const newBounds = this.recalculateBounds(canvasX, canvasY, {
        zoomIn: !e.shiftKey,
      });

      // Update current bounds
      Object.assign(this.currentBounds, newBounds);

      // Call WASM to reinitialize with new bounds
      this.wasm.exports.initialize(
        this.canvas.height,
        this.canvas.width,
        IMAX,
        newBounds.min_x,
        newBounds.max_y,
        newBounds.max_x,
        newBounds.min_y
      );

      this.renderCurrentImage();
    });
  },
  destroyed() {
    if (this.wasm) this.wasm.exports.freeColours();
  },
};

export default MandelbrotViewer;
