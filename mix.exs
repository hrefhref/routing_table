defmodule RoutingTable.MixProject do
  use Mix.Project

  def project do
    [
      app: :routing_table,
      version: "0.1.0",
      elixir: "~> 1.12-rc",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:rustler, "~> 0.22.2"}
    ]
  end
end
