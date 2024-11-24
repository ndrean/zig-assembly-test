defmodule MandelzoomWeb.PageLive do
  use MandelzoomWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # bounds = %{
    #   topleft_x: -2.0,
    #   topleft_y: 1.0,
    #   bottomright_x: 1.0,
    #   bottomright_y: -1.0,
    #   imax: 100
    # }
    {:ok, socket}

    # {:ok, push_event(socket, "initialize", %{bounds: bounds})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Mandelzoom</h1>
      <div>
        <canvas id="mandelzoom" phx-hook="MandelbrotViewer" width="800" height="600"></canvas>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event(
        "zoom",
        %{
          "rows" => rows,
          "cols" => cols,
          "imax" => imax,
          "topleft_x" => topleft_x,
          "topleft_y" => topleft_y,
          "bottomright_x" => bottomright_x,
          "bottomright_y" => bottomright_y
        },
        socket
      ) do
    {:noreply,
     assign(socket,
       rows: rows,
       cols: cols,
       imax: imax,
       topleft_x: topleft_x,
       topleft_y: topleft_y,
       bottomright_x: bottomright_x,
       bottomright_y: bottomright_y
     )}
  end
end
