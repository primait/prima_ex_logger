use Mix.Config

config :logger,
  backends: [
    {PrimaExLogger, :prima_logger}
  ]

config :logger, :prima_logger,
  level: :info,
  encoder: Poison,
  type: :test,
  environment: :production
