defmodule PrimaExLogger do
  @moduledoc """
  Custom logger to send json over stdout
  """

  @behaviour :gen_event

  @ignored_metadata_keys ~w[ansi_color pid]a
  # The Logger metadata keys set by the opentelemetry sdk (since 1.1.0)
  @opentelemetry_sdk_metadata_keys [:otel_trace_id, :otel_span_id, :otel_trace_flags]

  @typedoc """
  An object that encodes the current "settings" of PrimaExLogger
  """
  @type settings() :: map()

  @spec init({PrimaExLogger, atom()}) :: {:error, any()} | {:ok, any()} | {:ok, any(), :hibernate}
  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  def handle_call({:configure, opts}, %{name: name}) do
    {:ok, :ok, configure(name, opts)}
  end

  @spec configure(atom(), Keyword.t()) :: settings()
  defp configure(name, opts) do
    env = Application.get_env(:logger, name, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, name, opts)

    country = Keyword.get(opts, :country, nil)
    encoder = Keyword.get(opts, :encoder, Jason)
    environment = Keyword.get(opts, :environment, nil)
    ignored_metadata_keys = Keyword.get(opts, :ignored_metadata_keys, [:conn])
    metadata = Keyword.get(opts, :metadata, []) |> configure_metadata()
    metadata_serializers = Keyword.get(opts, :metadata_serializers, [])
    opentelemetry_metadata = Keyword.get(opts, :opentelemetry_metadata, :datadog)
    type = Keyword.get(opts, :type, nil)

    %{
      name: name,
      encoder: encoder,
      type: type,
      country: country,
      environment: environment,
      metadata: metadata,
      opentelemetry_metadata: opentelemetry_metadata,
      metadata_serializers: metadata_serializers,
      ignored_metadata_keys: ignored_metadata_keys
    }
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  def handle_event(event, %{encoder: encoder} = state) do
    event
    |> forge_event(state)
    |> log(encoder)

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

  @spec forge_event(tuple(), settings()) :: map()
  defp forge_event({level, _, {Logger, message, timestamp, metadata}}, settings) do
    %{
      "message" => IO.iodata_to_binary(message),
      "level" => level,
      "type" => settings.type,
      "country" => format_country(settings.country),
      "environment" => settings.environment,
      "metadata" => process_metadata(metadata, settings),
      "timestamp" => timestamp_to_iso(timestamp)
    }
    |> add_opentelemetry_metadata(metadata, settings)
  end

  @spec process_metadata(Logger.metadata(), settings()) :: map()
  defp process_metadata(metadata, settings) do
    metadata =
      metadata
      |> Keyword.merge(settings.metadata)
      |> Keyword.drop(@ignored_metadata_keys ++ settings.ignored_metadata_keys)

    no_otel_metadata = Keyword.drop(metadata, @opentelemetry_sdk_metadata_keys)
    metadata = if :raw == settings.opentelemetry_metadata, do: metadata, else: no_otel_metadata

    to_printable(metadata, settings.metadata_serializers)
  end

  @spec add_opentelemetry_metadata(map(), Logger.metadata(), settings()) :: map()
  defp add_opentelemetry_metadata(event, metadata, settings) do
    otel_metadata =
      try do
        metadata
        |> Keyword.take(@opentelemetry_sdk_metadata_keys)
        |> opentelemetry_metadata(settings.opentelemetry_metadata)
      rescue
        # If the otel metadata is not in the format we expect
        # (for example because the application may be overwriting it with arbitrary values)
        # we don't want the logger to break, but just return no opentelemetry metadata.
        _ -> []
      end

    otel_metadata |> to_printable(settings.metadata_serializers) |> Enum.into(event)
  end

  @spec opentelemetry_metadata(
          Logger.metadata(),
          :datadog | :opentelemetry | :detailed | :raw | :none
        ) ::
          Keyword.t()
  defp opentelemetry_metadata(raw_otel_metadata, format)

  # If here, it means the log event did not have the standard opentelemetry sdk metadata
  # Either the process that emitted the log did not have a trace context in its process dictionary
  # (incorrect or missing opentelemetry instrumentation), or the application is using
  # a version of opentelemetry API/SDK older than 1.1, which is when logger metadata was added.
  defp opentelemetry_metadata([], _format), do: []

  defp opentelemetry_metadata(_, :raw), do: []
  defp opentelemetry_metadata(_, :none), do: []

  # Opentelemetry metadata in "DataDog format", see:
  # https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/opentelemetry
  # With these, DataDog Logs-APM correlation features will work
  defp opentelemetry_metadata(metadata, :datadog) do
    # Convert 128 bit OpenTelemetry trace ID to 64 bit DataDog trace ID (take the last 64 bits)
    # Convert integer represented as a base16 charlist to a base10 binary
    # we could return the integer directly, which is probably slightly more efficient, but:
    # - what integer would we send when missing?
    #   (datadog doesn't like same metadata being set with different types)
    # - Sending it as a string prevents it from being displayed as "1.4342e18"
    # - The datadog examples for other languages use strings, with empty string fallback
    dd_trace_id =
      metadata
      |> get_as_binary(:otel_trace_id)
      |> Integer.parse(16)
      |> case do
        {trace_id, ""} -> trace_id |> Bitwise.&&&(0xFFFFFFFFFFFFFFFF) |> Integer.to_string()
        _ -> ""
      end

    dd_span_id =
      metadata
      |> get_as_binary(:otel_span_id)
      |> Integer.parse(16)
      |> case do
        {span_id, ""} -> Integer.to_string(span_id, 10)
        _ -> ""
      end

    [dd: [trace_id: dd_trace_id, span_id: dd_span_id]]
  end

  # Opentelemetry metadata in opentelemetry format: 128 bit trace IDs and 64 bit span IDs, hex-encoded as binaries.
  # Saved in a `otel` "namespace."
  defp opentelemetry_metadata(metadata, :opentelemetry) do
    [
      otel: [
        trace_id: get_as_binary(metadata, :otel_trace_id),
        span_id: get_as_binary(metadata, :otel_span_id),
        trace_flags: get_as_binary(metadata, :otel_trace_flags)
      ]
    ]
  end

  defp opentelemetry_metadata(metadata, :detailed) do
    # A combination of :datadog and :opentelemetry
    opentelemetry_metadata(metadata, :datadog) ++ opentelemetry_metadata(metadata, :opentelemetry)
  end

  defp get_as_binary(metadata, key),
    do: metadata |> Keyword.get(key, ~c"") |> :binary.list_to_bin()

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
        v
        |> fun.()
        |> to_printable(custom_serializers)

      {module, fun} when is_atom(fun) ->
        module
        # Credo wants us to do `module.fun(v)`, but that doesn't work in Elixir..
        # credo:disable-for-next-line Credo.Check.Refactor.Apply
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
    NaiveDateTime.new!(
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
    )
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601(:extended)
  end

  @spec log(map(), module()) :: :ok
  defp log(event, encoder) do
    case encoder.encode(event) do
      {:ok, json} ->
        IO.puts(json)

      {:error, reason} ->
        IO.puts(
          "Error during JSON encoding. Reason: #{inspect(reason)}, event: #{inspect(event)}"
        )
    end
  end

  @spec configure_metadata(list() | :all) :: Logger.metadata()
  defp configure_metadata([]), do: []
  defp configure_metadata(:all), do: []
  defp configure_metadata(metadata) when is_list(metadata), do: Enum.reverse(metadata)

  defp format_country(nil), do: nil
  defp format_country(country), do: "prima:country:#{country}"
end
