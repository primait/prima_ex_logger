# PrimaExLogger

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `prima_ex_logger` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:prima_ex_logger, "~> 0.6.0"}
  ]
end
```

## Configuration example

```elixir
config :logger,
  backends: [
    {PrimaExLogger, :prima_logger}
  ],
  level: :info  # please note that changing global :logger level will also affect this backend

config :logger, :prima_logger,
  encoder: Poison,
  type: :your_app_name,
  environment: :production,
  country: :country
```

## Supported options

- **encoder** (module): JSON encoder, default Jason. Tested with Jason, Poison and JSX

- **type** (string): app name

- **environment** (atom)

- **country** (atom)

- **metadata** (list): custom metadata to append to every log, default `[]`.
  Note that this has a different meaning than Logger's `metadata` option, which is used to indicate what metadata keys to keep instead!

- **opentelemetry_metadata (`:datadog | :opentelemetry | :detailed | :none | :raw`)**: automatically adds distributed tracing information to log metadata. This can be used to correlate logs across services exploiting the distributed tracing infrastructure.

  The value indicates the "format" of the opentelemetry metadata to use:
  - `:raw`: leaves the opentelemetry metadata generated by the opentelemetry sdk intact and doesn't change it any way.
      Not recommended because these are serialized to quite useless lists of integers.
      All other options will remove the opentelemetry SDK metadata from the logs, but will use it to compute the equivalents in other formats.
  - `:datadog`: sets `dd.trace_id` and `dd.span_id` as per the [DataDog doc on connecting OpenTelemetry Traces and Logs](https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/opentelemetry).
    This is the default and will allow you to use the extremely useful log / APM correlation features of DataDog.
  - `:opentelemetry`: sets `otel.trace_id`, `otel.span_id` and `otel.trace_flags'` using the OpenTelemetry hex-encoded TraceId/SpanId formats.
  - `:detailed`: sets both of the above
  - `:none`: No automatic opentelemetry-related metadata at all in the produced logs.

  Note that, for this functionality to work, your project must depend on `:opentelemetry_api` >= 1.1 and have functioning opentelemetry instrumentation,
  for example by using [prima_opentelemetry_ex](https://github.com/primait/prima_opentelemetry_ex).

- **metadata_serializers** (list): custom serializers for structs found in metadata, default `[]`
  - example: `[{Decimal, to_string}]`, will invoke `Decimal.to_string/1` when a `Decimal` struct is found in the metadata
  - example: `[{Decimal, &Kernel.to_string/1}]`, will invoke `Kernel.to_string/1` when a `Decimal` struct is found in the metadata

- **ignore_metadata_keys** (list of strings): specify a list of root level metadata keys to remove from all logs,
if not provided it will default to `[:conn]` for security reasons
