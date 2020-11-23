defmodule PrimaExLoggerTest do
  use ExUnit.Case
  require Logger

  import ExUnit.CaptureIO

  defmodule TestStruct do
    defstruct [:field1, :field2]
  end

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

  test "Sent messages include metadata, with flattening" do
    io =
      capture_io(fn ->
        logger = new_logger(metadata_opts: [flattened: true])

        log(logger, "Hello world!", :info,
          field1: "7396385c-6da5-4e6f-b63f-1c6785bc1ccc",
          field2: ["one", "two", "three"],
          field3: %{sub: "1234", extra: %{filter: "on"}},
          field4: %{field: [1, 2, 3], extra: %{nested: "off", list: [4, 5, 6]}}
        )

        :gen_event.stop(logger)
      end)

    event = Jason.decode!(io)
    assert event["metadata"]["field1"] == "7396385c-6da5-4e6f-b63f-1c6785bc1ccc"
    assert event["metadata"]["field2"] == ["one", "two", "three"]
    assert event["metadata"]["field3.sub"] == "1234"
    assert event["metadata"]["field3.extra.filter"] == "on"
    assert event["metadata"]["field4.field"] == [1, 2, 3]
    assert event["metadata"]["field4.extra.nested"] == "off"
    assert event["metadata"]["field4.extra.list"] == [4, 5, 6]
  end

  test "Sent messages include metadata, with flattening (including structs)" do
    io =
      capture_io(fn ->
        logger = new_logger(metadata_opts: [flattened: true])

        log(logger, "Hello world!", :info,
          field: %TestStruct{field1: "one", field2: %{hello: "world"}}
        )

        :gen_event.stop(logger)
      end)

    event = Jason.decode!(io)
    assert event["metadata"]["field.field1"] == "one"
    assert event["metadata"]["field.field2.hello"] == "world"
  end

  test "Sent messages include static fields" do
    io =
      capture_io(fn ->
        logger = new_logger(metadata: [field2: "value2"])
        log(logger, "Hello world!")
        :gen_event.stop(logger)
      end)

    event = Jason.decode!(io)
    assert event["metadata"]["field2"] == "value2"
  end

  defp new_logger(opts \\ []) do
    {:ok, manager} = :gen_event.start_link()
    :ok = :gen_event.add_handler(manager, PrimaExLogger, {PrimaExLogger, :prima_logger})
    :ok = :gen_event.call(manager, PrimaExLogger, {:configure, opts})
    manager
  end

  defp log(logger, msg, level \\ :info, metadata \\ []) do
    ts = {{2017, 1, 1}, {1, 2, 3, 400}}
    :gen_event.notify(logger, {level, logger, {Logger, msg, ts, metadata}})
    Process.sleep(100)
  end
end
