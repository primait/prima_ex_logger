defmodule PrimaExLogger.AuditLoggingTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias PrimaExLogger.AuditLogging
  alias PrimaExLogger.AuditLogging.AuditLog

  test "Happy case" do
    io =
      capture_io(fn ->
        audit_log =
          AuditLog.new()
          |> AuditLog.actor("actor")
          |> AuditLog.event_name("event_name")
          |> AuditLog.message("message")
          |> AuditLog.timestamp("timestamp")

        AuditLogging.log(audit_log)
      end)

    log = Jason.decode!(io)

    assert log["actor"] == "actor"
    assert log["event_name"] == "event_name"
    assert log["message"] == "message"
    assert log["timestamp"] == "timestamp"
  end
end
