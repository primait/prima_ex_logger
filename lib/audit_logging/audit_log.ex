defmodule PrimaExLogger.AuditLogging.AuditLog do
  @moduledoc """
    "runtime": {
      "type": ["object", "null"],
      "description": "Represents the runtime details automatically injected by the library.",
      "properties": {
        "app_name": { "type": "string" },
        "app_version": { "type": "string" },
        "environment": { "type": "string" }
      },
      "required": ["app_name", "app_version", "environment"]
    },
  """


  @audit_log_scope "auditLog"

  @derive Jason.Encoder
  @enforce_keys [:actor, :event_name, :message, :timestamp]
  defstruct [:actor, :event_name, :message, :timestamp, :created_at, :metadata, :target, :http, :runtime, scope: @audit_log_scope]

  def created_at(log, created_at), do: %{log | created_at: created_at}
  def metadata(log, metadata), do: %{log | metadata: metadata}
  def target(log, target), do: %{log | target: target}
  def http(log, http), do: %{log | http: http}
  def runtime(log, runtime), do: %{log | runtime: runtime}

  defmodule Http do
    @derive Jason.Encoder
    @enforce_keys [:host, :user_agent_string, :http_method, :path, :remote_address]
    defstruct [:host, :user_agent_string, :http_method, :path, :remote_address, :correlation_id]

    def correlation_id(http, correlation_id), do: %{http | correlation_id: correlation_id}
  end

  defmodule Runtime do
    @derive Jason.Encoder
    @enforce_keys [:app_name, :app_version, :environment]
    defstruct [:app_name, :app_version, :environment]
  end
end
