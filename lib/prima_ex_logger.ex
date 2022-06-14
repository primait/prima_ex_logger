defmodule PrimaExLogger do
  @moduledoc """
  Custom logger to send json over stdout
  """

  @behaviour :gen_event

  @ignored_metadata_keys ~w[ansi_color pid]a

  @dialyzer {:nowarn_function,
             [init: 1, configure: 2, forge_event: 2, timestamp_to_iso: 1, log: 2]}

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
    metadata_serializers = Keyword.get(opts, :metadata_serializers, [])
    ignored_metadata_keys = Keyword.get(opts, :ignored_metadata_keys, [:conn])

    %{
      level: level,
      name: name,
      encoder: encoder,
      type: type,
      environment: environment,
      metadata: metadata,
      metadata_serializers: metadata_serializers,
      ignored_metadata_keys: ignored_metadata_keys
    }
  end

  def handle_event(event, %{encoder: encoder} = state) do
    event
    |> forge_event(state)
    |> log(encoder)

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
         metadata: fields,
         metadata_serializers: custom_serializers,
         ignored_metadata_keys: ignored_metadata_keys
       }) do
    %{
      "message" => IO.iodata_to_binary(message),
      "level" => level,
      "type" => type,
      "environment" => environment,
      "metadata" =>
        take_metadata(
          metadata,
          fields,
          custom_serializers,
          @ignored_metadata_keys ++ ignored_metadata_keys
        ),
      "timestamp" => timestamp_to_iso(timestamp)
    }
  end

  @spec take_metadata(list(), any(), list(), list()) :: map()
  defp take_metadata(metadata, fields, custom_serializers, ignore_keys) do
    metadata
    |> Keyword.merge(fields)
    |> Keyword.drop(ignore_keys)
    |> to_printable(custom_serializers)
  end

  @spec to_printable(any(), list()) :: any()
  def to_printable(v, _) when is_binary(v), do: v
  def to_printable(v, _) when is_atom(v), do: v
  def to_printable(v, _) when is_number(v), do: v

  def to_printable(v, custom_serializers) when is_list(v) do
    if Keyword.keyword?(v) do
      v
      |> Enum.into(%{})
      |> to_printable(custom_serializers)
    else
      Enum.map(v, &to_printable(&1, custom_serializers))
    end
  end

  def to_printable(%t{} = v, custom_serializers) when t in [Date, DateTime, NaiveDateTime],
    do: to_printable(inspect(v), custom_serializers)

  def to_printable(%t{} = v, custom_serializers) do
    custom_serializers
    |> Enum.find(fn
      {^t, _} -> true
      _ -> false
    end)
    |> case do
      nil ->
        to_printable(Map.from_struct(v), custom_serializers)

      {_module, fun} when is_function(fun, 1) ->
        fun
        |> apply([v])
        |> to_printable(custom_serializers)

      {module, fun} when is_atom(fun) ->
        module
        |> apply(fun, [v])
        |> to_printable(custom_serializers)
    end
  end

  def to_printable(v, custom_serializers) when is_map(v) do
    Enum.into(v, %{}, fn {k, v} ->
      {to_printable(k, custom_serializers), to_printable(v, custom_serializers)}
    end)
  end

  def to_printable(v, _), do: inspect(v)

  @spec timestamp_to_iso(tuple()) :: String.t()
  def timestamp_to_iso({{year, month, day}, {hour, minute, second, milliseconds}}) do
    case NaiveDateTime.new(
           %Date{
             year: year,
             month: month,
             day: day
           },
           %Time{
             hour: hour,
             minute: minute,
             second: second,
             microsecond: {1000 * milliseconds, 6}
           }
         ) do
      {:ok, ts} ->
        ts
        |> DateTime.from_naive!("Etc/UTC")
        |> DateTime.to_iso8601(:extended)

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
