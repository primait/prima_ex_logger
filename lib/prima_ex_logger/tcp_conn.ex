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
      :socket,
      opts: [],
      timeout: 5000
    ]
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def send(data), do: GenServer.call(__MODULE__, {:send, data})

  # Callbacks

  @impl true
  def init(host: host, port: port) do
    state = %State{host: host, port: port}
    {:ok, state}
  end

  @impl true
  def handle_call({:send, data}, _, %State{socket: socket} = s) do
    with {:ok, new_data} <- ensure_eof(data),
         :ok <- :gen_tcp.send(socket, new_data) do
      {:reply, :ok, s}
    else
      {:error, _} = error ->
        IO.puts("Send failed: #{inspect(error)}")
        {:noreply, connect(s)}
    end
  end

  defp connect(%State{host: host, port: port, opts: opts, timeout: timeout} = s) do
    case :gen_tcp.connect(host, port, [active: false] ++ opts, timeout) do
      {:ok, socket} ->
        {:ok, %{s | socket: socket}}

      {:error, _} ->
        {:backoff, 1000, s}
    end
  end

  defp ensure_eof(data) do
    {:ok, data |> String.trim() |> Kernel.<>("\n") |> Kernel.<>(<<0>>)}
  end
end
