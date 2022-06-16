import Config

config :logger,
  backends: [
    {PrimaExLogger, :prima_logger}
  ],
  level: :info

config :logger, :prima_logger,
  encoder: Poison,
  type: :test,
  environment: :production
