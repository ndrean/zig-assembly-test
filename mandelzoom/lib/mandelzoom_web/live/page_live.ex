defmodule MandelzoomWeb.PageLive do
  use MandelzoomWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Mandelzoom</h1>
      <div>
        <canvas
        style="image-rendering: high-quality;"
        id="mandelzoom"
        phx-hook="MandelbrotViewer"
        width="1000"
        height="800"></canvas>
      </div>
    </div>
    """
  end
end
