defmodule PrimaExLogger.AuditLogging.AuditLog do
  @moduledoc """
    "http": {
      "type": ["object", "null"],
      "description": "Context about the HTTP request currently being processed.",
      "properties": {
        "host": { "type": "string" },
        "user_agent_string": { "type": "string" },
        "http_method": { "type": "string" },
        "path": { "type": "string" },
        "remote_address": { "type": "string" },
        "correlation_id": { "type": ["string", "null"] }
      },
      "required": ["host", "user_agent_string", "http_method", "path", "remote_address"]
    },
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
  defstruct [:actor, :event_name, :message, :timestamp, :created_at, :metadata, :target, :http, scope: @audit_log_scope]

  def created_at(log, created_at), do: %{log | created_at: created_at}
  def metadata(log, metadata), do: %{log | metadata: metadata}
  def target(log, target), do: %{log | target: target}
  def http(log, http), do: %{log | http: http}

  defmodule Http do
    @derive Jason.Encoder
    @enforce_keys [:host, :user_agent_string, :http_method, :path, :remote_address]
    defstruct [:host, :user_agent_string, :http_method, :path, :remote_address]
  end
end
