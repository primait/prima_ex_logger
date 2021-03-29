defmodule PrimaExLogger.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    env = Application.get_env(:logger, :prima_logger)
    host = Keyword.fetch!(env, :host)
    port = Keyword.fetch!(env, :port)

    children = [
      {PrimaExLogger.TCPconn, [host, port]}
    ]

    opts = [strategy: :one_for_one, name: Naive.Application]
    Supervisor.start_link(children, opts)
  end
end
