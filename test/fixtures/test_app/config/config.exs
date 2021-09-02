use Mix.Config

config :logger,
  backends: [
    {PrimaExLogger, :prima_logger}
  ]

config :logger, :prima_logger,
  app_version?: true,
  level: :info,
  metadata: :all,
  encoder: Jason,
  type: :stonehenge,
  environment: :staging
