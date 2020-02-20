defmodule PrimaExLogger do
  @moduledoc """
  Custom logger to send json over stdout
  """
  use Timex

  @behaviour :gen_event

  @ignored_metadata_keys ~w[ansi_color pid]a

  @spec init({PrimaExLogger, atom()}) :: {:error, any()} | {:ok, any()} | {:ok, any(), :hibernate}
  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  def handle_call({:configure, opts}, %{name: name}) do
    {:ok, :ok, configure(name, opts)}
  end

  @spec configure(atom(), Keyword.t()) :: map()
  defp configure(name, opts) do
    env = Application.get_env(:logger, name, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, name, opts)

    level = Keyword.get(opts, :level, :info)
    encoder = Keyword.get(opts, :encoder, Jason)
    environment = Keyword.get(opts, :environment, nil)
    type = Keyword.get(opts, :type, nil)
    metadata = Keyword.get(opts, :metadata, []) |> configure_metadata()

    %{
      level: level,
      name: name,
      encoder: encoder,
      type: type,
      environment: environment,
      metadata: metadata
    }
  end

  def handle_event({level, _, _} = event, %{level: min_level, encoder: encoder} = state) do
    case Logger.compare_levels(level, min_level) do
      :lt ->
        nil

      _ ->
        event
        |> forge_event(state)
        |> log(encoder)
    end

    {:ok, state}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  @spec forge_event(tuple(), map()) :: map()
  defp forge_event({level, _, {Logger, message, timestamp, metadata}}, %{
         type: type,
         environment: environment,
         metadata: fields
       }) do
    %{
      "message" => IO.iodata_to_binary(message),
      "level" => level,
      "type" => type,
      "environment" => environment,
      "metadata" => take_metadata(metadata, fields),
      "timestamp" => timestamp_to_iso(timestamp)
    }
  end

  @spec take_metadata(list(), any()) :: map()
  defp take_metadata(metadata, fields) do
    metadata
    |> Keyword.merge(fields)
    |> Keyword.drop(@ignored_metadata_keys)
    |> to_printable()
  end

  @spec to_printable(any()) :: any()
  def to_printable(v) when is_binary(v), do: v
  def to_printable(v) when is_atom(v), do: v
  def to_printable(v) when is_number(v), do: v

  def to_printable(v) when is_list(v) do
    if Keyword.keyword?(v) do
      v
      |> Enum.into(%{})
      |> to_printable()
    else
      Enum.map(v, &to_printable/1)
    end
  end

  def to_printable(%_{} = v), do: to_printable(inspect(v))

  def to_printable(v) when is_map(v) do
    Enum.into(v, %{}, fn {k, v} -> {to_printable(k), to_printable(v)} end)
  end

  def to_printable(v), do: inspect(v)

  @spec timestamp_to_iso(tuple()) :: String.t()
  defp timestamp_to_iso({{year, month, day}, {hour, minute, second, milliseconds}}) do
    case NaiveDateTime.new(
           year,
           month,
           day,
           hour,
           minute,
           second,
           milliseconds * 1000
         ) do
      {:ok, ts} ->
        ts
        |> Timex.to_datetime(Timezone.local())
        |> Timex.format!("{ISO:Extended}")

      _ ->
        nil
    end
  end

  @spec log(map(), module()) :: :ok
  defp log(event, encoder) do
    case apply(encoder, :encode, [event]) do
      {:ok, json} ->
        IO.puts(json)

      {:error, reason} ->
        IO.puts(
          "Error during JSON encoding. Reason: #{inspect(reason)}, event: #{inspect(event)}"
        )
    end
  end

  @spec configure_metadata(list() | atom()) :: list()
  defp configure_metadata([]), do: []
  defp configure_metadata(:all), do: []
  defp configure_metadata(metadata) when is_list(metadata), do: Enum.reverse(metadata)
end
