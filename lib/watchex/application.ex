defmodule Watchex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      WatchexWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Watchex.PubSub},
      # Start the Endpoint (http/https)
      WatchexWeb.Endpoint,
      {Registry, keys: :unique, name: Watchex.GameRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: Watchex.WorldSupervisor}
      # Start a worker by calling: Watchex.Worker.start_link(arg)
      # {Watchex.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Watchex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    WatchexWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
