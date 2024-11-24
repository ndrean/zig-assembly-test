defmodule MandelzoomWeb.Router do
  use MandelzoomWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MandelzoomWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["wasm"]
  end

  scope "/", MandelzoomWeb do
    pipe_through :browser

    live "/", PageLive
  end

  scope "/", MandelzoomWeb do
    pipe_through :api
    get "/wasm", WasmController, :load
  end
end
