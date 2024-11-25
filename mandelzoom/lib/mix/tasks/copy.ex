defmodule Mix.Tasks.Copy do
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    IO.puts("Copying WASM")
    {:ok, ["zoom.wasm"]} = File.ls("../zoomzig/zig-out/bin/")
    :ok = File.cp("../zoomzig/zig-out/bin/zoom.wasm", "./assets/wasm/zoom.wasm")
  end
end
