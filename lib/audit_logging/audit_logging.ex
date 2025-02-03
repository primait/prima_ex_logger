defmodule PrimaExLogger.AuditLogging do
  def log(audit_log) do
    IO.puts(Jason.encode!(audit_log)) 
    :ok
  end
end
