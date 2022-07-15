defmodule PrimaExLogger.TCPconn do
  @moduledoc """
  A generic server process that forwards the received string
  to a host and port via TCP. To do so uses the erlang
  `:gen_tcp` module.

  """
  use GenServer, restart: :temporary
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
      max_retries: 3,
      retries: 0,
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
    {:ok, state, {:continue, :connect}}
  end

  @impl true
  def handle_continue(
        :connect,
        %State{
          max_retries: max_retries,
          retries: retries
        } = s
      ) do
    case {connect(s), retries} do
      {{:ok, new_state}, _r} ->
        {:noreply, new_state}

      {{:backoff, _milliseconds}, r} when r > max_retries ->
        IO.puts(
          "Failed to connect to the socket review your config: \n" <>
            "host: #{inspect(s.host)}\n" <>
            "port: #{inspect(s.port)}"
        )

        {:stop, :unable_to_connect, s}

      {{:backoff, milliseconds}, r} ->
        Process.sleep(milliseconds)
        {:noreply, %{s | retries: r + 1}, {:continue, :connect}}
    end
  end

  @impl true
  def handle_call({:send, data}, _, %State{socket: nil} = s) do
    IO.puts("Socket not ready, ignoring message: #{data}")

    {:reply, :ok, s}
  end

  @impl true
  def handle_call({:send, data}, _, %State{socket: socket} = s) do
    with {:ok, new_data} <- ensure_eof(data),
         :ok <- :gen_tcp.send(socket, new_data) do
      {:reply, :ok, s}
    else
      {:error, _} = error ->
        IO.puts("Send failed: #{inspect(error)}")

        {:reply, :ok, connect(s)}
    end
  end

  defp connect(%State{socket: socket} = s) when is_port(socket) do
    {:ok, s}
  end

  defp connect(%State{host: host} = s) when is_binary(host) do
    connect(%{s | host: String.to_charlist(host)})
  end

  defp connect(%State{host: host, port: port, opts: opts, timeout: timeout} = s) do
    case :gen_tcp.connect(host, port, [active: false] ++ opts, timeout) do
      {:ok, socket} ->
        {:ok, %{s | socket: socket}}

      {:error, error} ->
        IO.puts("Failed to connect to socket, error: #{inspect(error)}")
        {:backoff, 1000}
    end
  end

  defp ensure_eof(data) do
    {:ok, data |> String.trim() |> Kernel.<>("\n") |> Kernel.<>(<<0>>)}
  end
end
