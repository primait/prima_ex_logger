defmodule PrimaExLogger.AuditLogTest do
  use ExUnit.Case

  alias PrimaExLogger.AuditLogging.AuditLog

  test "can add and encode simple optional fields" do
    audit_log =
      %AuditLog{
        actor: "actor",
        event_name: "event_name",
        message: "message",
        timestamp: "timestamp"
      }
      |> AuditLog.created_at(1_738_662_929)
      |> AuditLog.metadata(%{
        field1: "field1",
        field2: "field2"
      })
      |> AuditLog.target("target")

    encoded = Jason.encode!(audit_log)

    assert String.contains?(encoded, "auditLog")
    assert String.contains?(encoded, "actor")
    assert String.contains?(encoded, "event_name")
    assert String.contains?(encoded, "message")
    assert String.contains?(encoded, "timestamp")
    assert String.contains?(encoded, "1738662929")
    assert String.contains?(encoded, "field1")
    assert String.contains?(encoded, "field2")
  end
end
