defmodule PrimaExLogger.AuditLoggingTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias PrimaExLogger.AuditLogging
  alias PrimaExLogger.AuditLogging.AuditLog

  test "MVP: only required fields" do
    io =
      capture_io(fn ->
        audit_log =
          AuditLog.new()
          |> AuditLog.actor("actor")
          |> AuditLog.event_name("event_name")
          |> AuditLog.message("message")
          |> AuditLog.timestamp("timestamp")

        :ok = AuditLogging.log(audit_log)
      end)

    log = Jason.decode!(io)

    assert log["actor"] == "actor"
    assert log["event_name"] == "event_name"
    assert log["message"] == "message"
    assert log["timestamp"] == "timestamp"
  end

  test "misssing required fields" do
    io =
      capture_io(fn ->
        audit_log =
          AuditLog.new()
          |> AuditLog.actor("actor")
          |> AuditLog.event_name("event_name")
          |> AuditLog.message("message")

        {:error, error} = AuditLogging.log(audit_log)
        assert error == "Missing required field(s): timestamp"
      end)

    log = Jason.decode!(io)

    assert log["actor"] == "actor"
    assert log["event_name"] == "event_name"
    assert log["message"] == "message"
    assert log["timestamp"] == "timestamp"
  end
end
