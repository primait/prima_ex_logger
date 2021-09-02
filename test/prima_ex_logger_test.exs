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

        log(logger, "Hello world!", :info,
          field1: "value1",
          field_struct: %TestStruct{field1: "one", field2: %{hello: "world"}}
        )

        :gen_event.stop(logger)
      end)

    event = Jason.decode!(io)

    assert event["metadata"]["field1"] == "value1"

    assert event["metadata"]["field_struct"] == %{
             "field1" => "one",
             "field2" => %{"hello" => "world"}
           }
  end

  test "Sent messages include metadata, with custom serializer (1)" do
    io =
      capture_io(fn ->
        logger = new_logger(metadata_serializers: [{Decimal, :to_string}])

        log(logger, "Hello world!", :info,
          field1: "value1",
          field_decimal: Decimal.from_float(2.0)
        )

        :gen_event.stop(logger)
      end)

    event = Jason.decode!(io)
    assert event["metadata"]["field1"] == "value1"
    assert event["metadata"]["field_decimal"] == Decimal.to_string(Decimal.from_float(2.0))
  end

  test "Sent messages include metadata, with custom serializer (2)" do
    io =
      capture_io(fn ->
        logger = new_logger(metadata_serializers: [{Decimal, &inspect/1}])

        log(logger, "Hello world!", :info,
          field1: "value1",
          field_decimal: Decimal.from_float(2.0)
        )

        :gen_event.stop(logger)
      end)

    event = Jason.decode!(io)
    assert event["metadata"]["field1"] == "value1"
    assert event["metadata"]["field_decimal"] == inspect(Decimal.from_float(2.0))
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

  test "Same format without timex" do
    ts = {{2017, 1, 1}, {1, 2, 3, 400}}
    # this is what returns with timex: 2017-01-01T01:02:03.400000+00:00"
    assert "2017-01-01T01:02:03.400000Z" == PrimaExLogger.timestamp_to_iso(ts)
  end

  describe "App version option" do
    test "defaults none/nil" do
      # not part of event metadata as default
      io =
        capture_io(fn ->
          logger = new_logger()
          log(logger, "No app version")
          :gen_event.stop(logger)
        end)

      event = Jason.decode!(io)
      assert event["metadata"]["app_version"] == nil

      # default is none

      io =
        capture_io(fn ->
          logger = new_logger(app_version?: true)
          log(logger, "None as app version")
          :gen_event.stop(logger)
        end)

      event = Jason.decode!(io)
      assert event["metadata"]["app_version"] == "none"
    end

    test "adds expected version to logger metadata" do
      [
        {"mix", ["deps.get"]},
        {"mix", ["distillery.release", "--env=test"]},
        {"bash", ["_build/test/rel/test_app/bin/test_app", "console"]}
      ]
      |> Enum.map(fn {command, params} ->
        System.put_env("MIX_ENV", "test")
        assert {output, 0} = System.cmd(command, params, cd: "test/fixtures/test_app")

        output
      end)
      |> List.last()
      |> Jason.decode!()
      |> get_in(["metadata", "app_version"])
      |> Kernel.==("0.0.0-default")
      |> assert()

      # cleanup
      File.rm_rf!("test/fixtures/test_app/deps")
      File.rm_rf!("test/fixtures/test_app/_build")
    end
  end

  defp new_logger(opts \\ []) do
    {:ok, manager} = :gen_event.start_link()
    :ok = :gen_event.add_handler(manager, PrimaExLogger, {PrimaExLogger, :prima_logger})
    :ok = :gen_event.call(manager, PrimaExLogger, {:configure, opts})
    manager
  end

  defp log(logger, msg, level \\ :info, metadata \\ []) do
    ts = {{2017, 1, 1}, {1, 2, 3, 400}}
    :ok = :gen_event.notify(logger, {level, logger, {Logger, msg, ts, metadata}})
    Process.sleep(100)
  end
end
