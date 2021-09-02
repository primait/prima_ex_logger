defmodule TestApp.Application do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("just a log")
    System.stop()
  end
end
