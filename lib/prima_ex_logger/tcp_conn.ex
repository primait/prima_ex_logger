defmodule PrimaExLogger.TCPconn do
  @moduledoc """
  A generic server process that forwards the received string
  to a host and port via TCP. To do so uses the erlang
  `:gen_tcp` module.

  """
  use GenServer
  require Logger

  defmodule State do
    @moduledoc """
    The TCPconn state module.

    Requires `:host` and `:port` as mimimum values for the
    state to open a tcp socket.

    For more information about available options for the
    socket connection [see](https://erlang.org/doc/man/gen_tcp.html#data-types).


    """
    @enforce_keys [:host, :port]
    defstruct [
      :host,
      :port,
      opts: [],
      timeout: 5000
    ]
  end

  def start_link(%State{} = state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def send(data), do: GenServer.call(__MODULE__, {:send, data})

  # Callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:send, data}, _, %State{} = s) do
    with {:ok, sock} <- connect(s),
         {:ok, new_data} <- ensure_new_line(data),
         :ok <- :gen_tcp.send(sock, new_data),
         :ok <- :gen_tcp.shutdown(sock, :write) do
      {:reply, :ok, s}
    else
      {:backoff, milliseconds, s} ->
        Process.sleep(milliseconds)
        {:send, data, s}

      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  defp connect(%State{host: host, port: port, opts: opts, timeout: timeout} = s) do
    case :gen_tcp.connect(host, port, [active: false] ++ opts, timeout) do
      {:ok, sock} ->
        {:ok, sock}

      {:error, _} ->
        {:backoff, 1000, s}
    end
  end

  defp ensure_new_line(data) do
    {:ok, data |> String.trim() |> Kernel.<>("\n")}
  end
end
