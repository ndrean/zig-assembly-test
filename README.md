# Zig-assembly-test
Zig compiled to WebAssembly rendered in Phoenix Liveview and as a standalone app.

Standalone: 

```sh
cd zoomzig
zig build
```

```sh
cd mandelbrot
mix copy && mix phx.server
```

## Zig

The code will return a slice that corresponds to the RGBA values of each pixel.

In the "build.zig", we set `.max_memory = std.wasm.page_size * 128`. 

We set a variable `global_colours`. The `Zig`  will populate this slice.

To compile to `WebAssembly`, we:
- use `export fn ...`
- pass only numbers as arguments
- can't return error union, thus no `try`. Use `catch unreached`.
- function returns `void` or `numbers`.
- to return the "colours slice", we build a function to return the address of the first element of this memory block with `getColoursPointer`, and another one with its length with `getColoursSize`.

```wasm
var global_colours: ?[]u8 = null;

export fn getColoursPointer() *u8 {
    // Expose the colours array to the host
    return &global_colours.?.ptr[0];
}

export fn getColoursSize() usize {
    return global_colours.?.len;
}
```

## Elixir

The call `WebAssembly.instantiateStreaming` asks for a content-type "application/wasm".

### Serve the "wasm" file to the client

We serve the _wasm_ file with an endpoint defined in the router.

```elixir
pipeline :api do
    plug :accepts, ["wasm"]
end

scope "/", MandelzoomWeb do
    pipe_through :api
    get "/wasm", WasmController, :load
end
```

`Phoenix` appends by default sets "charset=utf8" to the Content-Type and `WebAssembly` does not want this.

We overwrite the `resp_headers`:

(<https://elixirforum.com/t/content-type-for-custom-binary-format/60452>)

```elixir
 conn = 
    %Plug.Conn{conn | resp_headers: [{"content-type", "application/wasm"} | conn.resp_headers]}
```

## Javascript - WebAssembly

The code is call via a hook, `MandelbrotViewer`.

The key points:
- instantiate a "memory" for WebAssembly
- fetch the wasm file (Phoenix will serve it)
- we called the WebAssembly module "instance" here". Call the WebAssembly functions with `instance.exports.<function_name>`
- pass only numbers (integers, floats) to `WebAssembly`. We named our main `Zig` function "initilize" which receives only numbers and return `void`. 

```js
memory = new WebAssembly.Memory({initial: initialPages,maximum: MAXIMUM_PAGES,});

const {instance }  = await WebAssembly.instantiateStreaming(fetch("/wasm"), { env: {memory}});

instance.exports.initilize(eows, cols...)
```

To fill in the canvas, we:
- instanttiate a Javascript `new Uint8ClampedArray` that will receive the WebAssembly data from the memory  address with a given length.
- create an `ImageData` from this data
- draw into the Canvas with `createImageBitmap`


## Create a Github pages from a subfolder

- Create a folder, "pages" here.
- create an "index.html" which calls a (eg) "scriptjs"
- put your JS in it
- copy "zoom.wasm" in the same folder

Then: 

```sh
git subtree push --prefix pages origin gh-pages
```

et voilà:

<https://ndrean.github.io/zig-assembly-test/>
