defmodule Mandelzoom.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MandelzoomWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:mandelzoom, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Mandelzoom.PubSub},
      # Start a worker by calling: Mandelzoom.Worker.start_link(arg)
      # {Mandelzoom.Worker, arg},
      # Start to serve requests, typically the last entry
      MandelzoomWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mandelzoom.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MandelzoomWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
