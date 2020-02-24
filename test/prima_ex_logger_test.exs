defmodule PrimaExLoggerTest do
  use ExUnit.Case, async: false
  require Logger

  import ExUnit.CaptureIO

  test "Happy case" do
    io =
      capture_io(fn ->
        logger = new_logger()
        log(logger, "Hello world!")
        :gen_event.stop(logger)
      end)

    event = Jason.decode!(io)
    assert event["message"] == "Hello world!"
    assert event["level"] == "info"
  end

  test "Log messages end with newline" do
    io =
      capture_io(fn ->
        logger = new_logger()
        log(logger, "Hello world!")
        :gen_event.stop(logger)
      end)

    assert io |> String.ends_with?("\n")
  end

  test "Logs with correct log level" do
    io =
      capture_io(fn ->
        logger = new_logger()
        log(logger, "Hello world!", :warn)
        :gen_event.stop(logger)
      end)

    event = Jason.decode!(io)
    assert event["level"] == "warn"
  end

  test "Can print several messages" do
    io =
      capture_io(fn ->
        logger = new_logger()
        log(logger, "Hello world!")
        log(logger, "Foo?")
        log(logger, "Bar!")
        :gen_event.stop(logger)
      end)

    lines = io |> String.trim() |> String.split("\n") |> List.to_tuple()
    assert tuple_size(lines) == 3
    assert lines |> elem(0) |> Jason.decode!() |> Map.get("message") == "Hello world!"
    assert lines |> elem(1) |> Jason.decode!() |> Map.get("message") == "Foo?"
    assert lines |> elem(2) |> Jason.decode!() |> Map.get("message") == "Bar!"
  end

  test "Sent messages include metadata" do
    io =
      capture_io(fn ->
        logger = new_logger()
        log(logger, "Hello world!", :info, field1: "value1")
        :gen_event.stop(logger)
      end)

    event = Jason.decode!(io)
    assert event["metadata"]["field1"] == "value1"
  end

  test "Sent messages include static fields" do
    opts =
      :logger
      |> Application.get_env(:prima_logger)
      |> Keyword.put(:metadata, field2: "value2")

    Application.put_env(:logger, :prima_logger, opts)

    io =
      capture_io(fn ->
        logger = new_logger()
        log(logger, "Hello world!")
        :gen_event.stop(logger)
      end)

    event = Jason.decode!(io)
    assert event["metadata"]["field2"] == "value2"
  end

  defp new_logger do
    {:ok, manager} = :gen_event.start_link()
    :gen_event.add_handler(manager, PrimaExLogger, {PrimaExLogger, :prima_logger})
    manager
  end

  defp log(logger, msg, level \\ :info, metadata \\ []) do
    ts = {{2017, 1, 1}, {1, 2, 3, 400}}
    :gen_event.notify(logger, {level, logger, {Logger, msg, ts, metadata}})
    Process.sleep(100)
  end
end
