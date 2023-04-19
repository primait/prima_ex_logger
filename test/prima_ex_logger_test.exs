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

  describe "opentelemetry metadata" do
    test "doesn't break if raw opentelemetry log metadata is missing (no opentelemetry metadata is emitted)" do
      io =
        capture_io(fn ->
          logger = new_logger(opentelemetry_metadata: :detailed)

          log(logger, "hello world!", :info)

          :gen_event.stop(logger)
        end)

      event = Jason.decode!(io)
      assert "dd" not in Map.keys(event["metadata"])
      assert "otel" not in Map.keys(event["metadata"])
    end

    test "doesn't break if unexpected otel metadata values" do
      # This tests that PrimaExLogger doesn't break if some user application
      # is putting arbitrary, unexpected values in the metadata keys "reserved" by
      # the OpenTelemetry SDK.
      io =
        capture_io(fn ->
          logger = new_logger(opentelemetry_metadata: :detailed)

          log(logger, "hello world!", :info,
            otel_trace_id: "we would expect a charlist here..",
            otel_trace_flags: %{"flag1" => false, "flag2" => true}
          )

          :gen_event.stop(logger)
        end)

      event = Jason.decode!(io)
      assert "dd" not in Map.keys(event)
      assert "otel" not in Map.keys(event)
    end

    test "values are computed correctly based on the raw opentelemetry metadata" do
      io =
        capture_io(fn ->
          logger = new_logger(opentelemetry_metadata: :detailed)

          log(logger, "hello world!", :info,
            # This is the log metadata automatically added by opentelemetry sdk >= 1.1.0
            otel_trace_id: '3f654ec56f0380000000000000000015',
            otel_span_id: 'f000000000000005',
            otel_trace_flags: '01'
          )

          :gen_event.stop(logger)
        end)

      event = Jason.decode!(io)
      assert event["dd"] == %{"trace_id" => "21", "span_id" => "17293822569102704645"}

      assert event["otel"] == %{
               "trace_id" => "3f654ec56f0380000000000000000015",
               "span_id" => "f000000000000005",
               "trace_flags" => "01"
             }
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
