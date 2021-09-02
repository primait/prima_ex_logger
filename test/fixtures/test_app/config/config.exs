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
  type: :test_app,
  environment: :some_env
