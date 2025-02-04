defmodule PrimaExLogger.AuditLogging do
  @moduledoc """
  # Audit Logging

  An audit logging helper.

  ## Usage

  You can construct audit logs either manually, as described [here](https://backstage.helloprima.com/docs/default/component/audit_log/how-to/), or you can use the `PrimaExLogger.AuditLogging.AuditLog` structure to create them in a more guided manner.

  Here's the bare minimum that you need to do:
  ```
  audit_log = %PrimaExLogger.AuditLogging.AuditLog{
    actor: "actor",
    event_name: "event_name",
    message: "message",
    timestamp: "timestamp"
  }

  PrimaExLogger.AuditLogging.log!(audit_log)
  ```
  """

  @spec log(PrimaExLogger.AuditLogging.AuditLog) :: :ok | {:error, any()}
  def log(audit_log) do
    with {:ok, encoded} <- Jason.encode(audit_log) do
      IO.puts(encoded)
    else
      jason_error -> jason_error
    end
  end

  def log!(audit_log), do: audit_log |> Jason.encode!() |> IO.puts()
end
