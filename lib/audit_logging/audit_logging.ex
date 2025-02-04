defmodule PrimaExLogger.AuditLogging do
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
