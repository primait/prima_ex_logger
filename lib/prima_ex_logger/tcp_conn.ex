defmodule PrimaExLogger.TCPconn do
  use GenServer
  require Logger

  defmodule State do
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
