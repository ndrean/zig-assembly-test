// Constants
const WASM_PAGE_SIZE = 65536;
const INITIAL_PAGES = 40;
const MAXIMUM_PAGES = 128;
const IMAX = 300;

// Global variables
let memory, wasm, canvas, ctx, currentBounds;

function setupMemory() {
  const bytesNeeded = canvas.width * canvas.height * 4;
  const pagesNeeded = Math.ceil(bytesNeeded / WASM_PAGE_SIZE);
  const initialPages = Math.max(pagesNeeded, INITIAL_PAGES);

  if (initialPages > MAXIMUM_PAGES) {
    throw new Error("Canvas size exceeds maximum memory allocation");
  }

  memory = new WebAssembly.Memory({
    initial: initialPages,
    maximum: MAXIMUM_PAGES,
  });
}

async function initWasm() {
  const result = await WebAssembly.instantiateStreaming(fetch("zoom.wasm"), {
    env: { memory },
  });
  wasm = result.instance;
}

function renderCurrentImage() {
  const coloursPtr = wasm.exports.getColoursPointer();
  const coloursSize = wasm.exports.getColoursSize();
  const imageData = new ImageData(
    new Uint8ClampedArray(wasm.exports.memory.buffer, coloursPtr, coloursSize),
    canvas.width,
    canvas.height
  );
  createImageBitmap(imageData).then((bitmap) => ctx.drawImage(bitmap, 0, 0));
}

function toCartesian(canvasX, canvasY) {
  const { min_x, max_x, min_y, max_y } = currentBounds;
  return {
    x: min_x + (canvasX / (canvas.width - 1)) * (max_x - min_x),
    y: max_y - (canvasY / (canvas.height - 1)) * (max_y - min_y),
  };
}

function recalculateBounds(canvasX, canvasY, zoomIn = true) {
  const { x: newCenterX, y: newCenterY } = toCartesian(canvasX, canvasY);
  const { min_x, max_x, min_y, max_y } = currentBounds;
  const oldWidth = max_x - min_x;
  const oldHeight = max_y - min_y;
  const factor = zoomIn ? 0.5 : 2;
  const newWidth = oldWidth * factor;
  const newHeight = oldHeight * factor;

  return {
    min_x: newCenterX - newWidth / 2,
    max_x: newCenterX + newWidth / 2,
    min_y: newCenterY - newHeight / 2,
    max_y: newCenterY + newHeight / 2,
  };
}

function handleClick(e) {
  const rect = canvas.getBoundingClientRect();
  const canvasX = e.clientX - rect.left;
  const canvasY = e.clientY - rect.top;
  const newBounds = recalculateBounds(canvasX, canvasY, !e.shiftKey);
  currentBounds = newBounds;

  wasm.exports.initialize(
    canvas.height,
    canvas.width,
    IMAX,
    newBounds.min_x,
    newBounds.max_y,
    newBounds.max_x,
    newBounds.min_y
  );

  renderCurrentImage();
}

async function init() {
  canvas = document.getElementById("mandelzoom");
  ctx = canvas.getContext("2d");
  currentBounds = { min_x: -2.0, max_y: 1.0, max_x: 0.6, min_y: -1.0 };

  setupMemory();
  await initWasm();

  wasm.exports.initialize(
    canvas.height,
    canvas.width,
    IMAX,
    currentBounds.min_x,
    currentBounds.max_y,
    currentBounds.max_x,
    currentBounds.min_y
  );

  renderCurrentImage();
  canvas.addEventListener("click", handleClick);
}

document.addEventListener("DOMContentLoaded", init);