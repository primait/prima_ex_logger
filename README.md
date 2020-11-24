# PrimaExLogger

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `prima_ex_logger` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:prima_ex_logger, "~> 0.2.1"}
  ]
end
```

## Configuration example

```elixir
config :logger,
  backends: [
    {PrimaExLogger, :prima_logger}
  ]

config :logger, :prima_logger,
  level: :info,
  encoder: Poison,
  type: :your_app_name,
  environment: :production
```

## Supported options

- **level** (atom): minimum level to log
- **encoder** (module): JSON encoder, default Jason. Tested with Jason, Poison and JSX
- **type** (string): app name
- **environment** (atom): current environment
- **metadata** (list): custom metadata to append on every log, default []
- **metadata_serializers** (list): custom serializers for structs found in metadata, default []
    - example: `[{Decimal, to_string}]`, will invoke `Decimal.to_string/1` when a `Decimal` struct is found among metadata
    - example: `[{Decimal, &Kernel.to_string/1}]`, will invoke `Kernel.to_string/1` when a `Decimal` struct is found among metadata
