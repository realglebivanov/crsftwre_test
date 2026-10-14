defmodule CrsftwreTest.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      CrsftwreTestWeb.Telemetry,
      CrsftwreTestWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: CrsftwreTest.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl Application
  def config_change(changed, _new, removed) do
    CrsftwreTestWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
