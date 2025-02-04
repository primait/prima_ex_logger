defmodule PrimaExLogger.AuditLogging.AuditLog do
  @audit_log_scope "auditLog"

  @derive Jason.Encoder
  @enforce_keys [:actor, :event_name, :message, :timestamp]
  defstruct [:actor, :event_name, :message, :timestamp, :created_at, :metadata, :target, scope: @audit_log_scope]

  def created_at(log, created_at), do: %{log | created_at: created_at}
  def metadata(log, metadata), do: %{log | metadata: metadata}
  def target(log, target), do: %{log | target: target}
end
