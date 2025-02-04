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

  test "can add and encode http struct" do
    # required fields only
    http = %AuditLog.Http{
      host: "host",
      user_agent_string: "user_agent",
      http_method: "POST",
      path: "/do-something",
      remote_address: "123.123.123.123"
    }

    audit_log =
      %AuditLog{
        actor: "actor",
        event_name: "event_name",
        message: "message",
        timestamp: "timestamp"
      }
      |> AuditLog.http(http)

    encoded = Jason.encode!(audit_log)

    assert String.contains?(encoded, ~s("host":"host"))
    assert String.contains?(encoded, ~s("user_agent_string":"user_agent"))
    assert String.contains?(encoded, ~s("http_method":"POST"))
    assert String.contains?(encoded, ~s("path":"/do-something"))
    assert String.contains?(encoded, ~s("remote_address":"123.123.123.123"))
    assert String.contains?(encoded, ~s("correlation_id":null))

    # with optional correlation_id
    http = AuditLog.Http.correlation_id(http, "12344321")
    audit_log = AuditLog.http(audit_log, http)
    encoded = Jason.encode!(audit_log)

    assert String.contains?(encoded, ~s("correlation_id":"12344321"))
  end
end
