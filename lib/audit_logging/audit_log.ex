defmodule PrimaExLogger.AuditLogging.AuditLog do
  @moduledoc """
  Struct representation of and Audit log
  """

  @audit_log_scope "auditLog"

  @derive Jason.Encoder
  @enforce_keys [:actor, :event_name, :message, :timestamp]
  defstruct [
    :actor,
    :event_name,
    :message,
    :timestamp,
    :created_at,
    :metadata,
    :target,
    :http,
    :runtime,
    scope: @audit_log_scope
  ]

  @type t :: %__MODULE__{
          actor: String.t(),
          event_name: String.t(),
          message: String.t(),
          timestamp: non_neg_integer() | String.t(),
          scope: String.t(),
          created_at: non_neg_integer() | String.t(),
          metadata: Map.t(),
          target: String.t(),
          http: Http.t(),
          runtime: Runtime.t()
        }

  @spec created_at(t(), non_neg_integer() | String.t()) :: AuditLog.t()
  def created_at(log, created_at), do: %{log | created_at: created_at}

  @spec created_at(t(), Map.t()) :: AuditLog.t()
  def metadata(log, metadata), do: %{log | metadata: metadata}

  @spec target(t(), String.t()) :: AuditLog.t()
  def target(log, target), do: %{log | target: target}

  @spec target(t(), Http.t()) :: AuditLog.t()
  def http(log, http), do: %{log | http: http}

  @spec target(t(), Runtime.t()) :: AuditLog.t()
  def runtime(log, runtime), do: %{log | runtime: runtime}

  defmodule Http do
    @moduledoc false

    @derive Jason.Encoder
    @enforce_keys [:host, :user_agent_string, :http_method, :path, :remote_address]
    defstruct [:host, :user_agent_string, :http_method, :path, :remote_address, :correlation_id]

    @type t :: %__MODULE__{
            host: String.t(),
            user_agent_string: String.t(),
            http_method: String.t(),
            path: String.t(),
            remote_address: String.t(),
            correlation_id: String.t()
          }

    @spec correlation_id(t(), String.t()) :: t()
    def correlation_id(http, correlation_id), do: %{http | correlation_id: correlation_id}
  end

  defmodule Runtime do
    @moduledoc false

    @derive Jason.Encoder
    @enforce_keys [:app_name, :app_version, :environment]
    defstruct [:app_name, :app_version, :environment]

    @type t :: %__MODULE__{
            app_name: String.t(),
            app_version: String.t(),
            environment: String.t()
          }

    @service_name "SERVICE_NAME"
    @service_version "SERVICE_VERSION"
    @service_env "SERVICE_ENV"

    @spec from_env() :: {:ok, t()} | {:error, String.t()}
    def from_env do
      with {:ok, service_name} <- get_env(@service_name),
           {:ok, service_version} <- get_env(@service_version),
           {:ok, service_env} <- get_env(@service_env) do
        {:ok,
         %__MODULE__{
           app_name: service_name,
           app_version: service_version,
           environment: service_env
         }}
      else
        {:error, missing_var} -> {:error, "Missing environment variable: #{missing_var}"}
      end
    end

    @spec from_env!() :: t()
    def from_env! do
      case from_env() do
        {:ok, runtime} -> runtime
        {:error, error} -> raise RuntimeError, error
      end
    end

    defp get_env(var) do
      case System.get_env(var) do
        nil -> {:error, var}
        value -> {:ok, value}
      end
    end
  end
end
