defmodule MandelzoomWeb.WasmController do
  use MandelzoomWeb, :controller

  # remove chrset=utf8 from response: https://elixirforum.com/t/content-type-for-custom-binary-format/60452
  def load(conn, _params) do

    conn = 
    %Plug.Conn{conn | resp_headers: [{"content-type", "application/wasm"} | conn.resp_headers]}

    send_file(conn, 200, "assets/wasm/zoom.wasm")
  end
end
