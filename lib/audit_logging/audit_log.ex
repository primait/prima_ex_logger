defmodule PrimaExLogger.AuditLogging.AuditLog do
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

    @service_name "SERVICE_NAME"
    @service_version "SERVICE_VERSION"
    @service_env "SERVICE_ENV"

    def from_env() do
      service_name = System.get_env(@service_name)
      service_version = System.get_env(@service_version)
      service_env = System.get_env(@service_env)

      if service_name == nil or service_version == nil or service_env == nil do
        {:error, "Missing environment variable"}
      else
        {:ok, %__MODULE__{app_name: service_name, app_version: service_version, environment: service_env}}
      end
    end
  end
end
