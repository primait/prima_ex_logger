defmodule PrimaExLogger.AuditLoggingTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias PrimaExLogger.AuditLogging
  alias PrimaExLogger.AuditLogging.AuditLog

  test "log!/1 emits audit log" do
    io =
      capture_io(fn ->
        audit_log =
          %AuditLog{
            actor: "actor",
            event_name: "event_name",
            message: "message",
            timestamp: "timestamp"
          }

        AuditLogging.log!(audit_log)
      end)

    log = Jason.decode!(io)

    assert log["actor"] == "actor"
    assert log["event_name"] == "event_name"
    assert log["message"] == "message"
    assert log["timestamp"] == "timestamp"

    # scope is also added automatically
    assert log["scope"] == "auditLog"
  end

  test "log/1 emits audit log" do
    io =
      capture_io(fn ->
        audit_log =
          %AuditLog{
            actor: "actor",
            event_name: "event_name",
            message: "message",
            timestamp: "timestamp"
          }

        :ok = AuditLogging.log(audit_log)
      end)

    log = Jason.decode!(io)

    assert log["actor"] == "actor"
    assert log["event_name"] == "event_name"
    assert log["message"] == "message"
    assert log["timestamp"] == "timestamp"

    # scope is also added automatically
    assert log["scope"] == "auditLog"
  end
end
