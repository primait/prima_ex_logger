defmodule PrimaExLogger.AuditLogging.AuditLog do
  @audit_log_scope "auditLog"

  @derive Jason.Encoder
  defstruct [:actor, :event_name, :message, :timestamp, scope: @audit_log_scope]

  def new(), do: %__MODULE__{}

  def actor(log, actor), do: %{log | actor: actor}
  def event_name(log, event_name), do: %{log | event_name: event_name}
  def message(log, message), do: %{log | message: message}
  def timestamp(log, timestamp), do: %{log | timestamp: timestamp}
end
