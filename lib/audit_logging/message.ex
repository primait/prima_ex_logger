defmodule PrimaExLogger.AuditLogging.AuditLog do
  @audit_log_scope "auditLog"

  @derive Jason.Encoder
  @enforce_keys [:actor, :event_name, :message, :timestamp]
  defstruct [:actor, :event_name, :message, :timestamp, scope: @audit_log_scope]
end
