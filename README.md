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
- **ignore_metadata_keys** (list of strings): specify a list of root level metadata keys to remove from all logs,
  if not provided it will default to `[:conn]` for security reasons
- **host**(:inet.socket_address()): - example: {127, 0, 0, 1},
  **port**(:inet.port()): - example: 10518

## Sending data to Datadog agent

You can send directly logs to Datadog via tcp messages sent to the Datadog agent. To do so you can start the agent via
`docker-compose up -d`. In order for the agent to work you need to have a datadog api key in your environment.

```
export DD_API_KEY=YOUR_API_KEY
```

Example of configuration with host and port for the TCPconn to forward the logs to.

```elixir

config :logger,
  backends: [
    {PrimaExLogger, :prima_logger}
  ]

config :logger, :prima_logger,
  level: :debug,
  metadata: :all,
  encoder: Jason,
  type: :stonehenge,
  environment: :staging,
  host: {127, 0, 0, 1},
  port: 10518
```

You also need to add :prima_ex_logger as an extra application in the mix file of your project.

```elixir
...
  def application do
    [
      mod: {YourApp.Application, []},
      extra_applications: [..., :prima_ex_logger]
    ]
  end
...
```

And finally if you want to enable the tcp forwarding you need to start your application with
`TCP_LOGGER=true iex -S mix`.

> Note!
> The TCPconn genserver is not meant to used in production. This is only a helper for testing purposes.
