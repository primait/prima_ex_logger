defmodule PrimaExLoggerTest do
  use ExUnit.Case, async: false

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

  # Invalid sequences are replaced following Unicode's "maximal subpart" practice
  # (one U+FFFD per truncated sequence), as `String.replace_invalid/1` does.
  for {kind, message, expected_message} <- [
        {"a Latin-1 character", "Hello caf" <> <<0xE9>> <> " world", "Hello caf\uFFFD world"},
        {"a stray continuation byte", "Hello " <> <<0xAA>> <> " world", "Hello \uFFFD world"},
        {"a byte never valid in UTF-8", "Hello " <> <<0xFF>> <> " world", "Hello \uFFFD world"},
        {"an overlong encoding", "Hello " <> <<0xC0, 0xAF>> <> " world",
         "Hello \uFFFD\uFFFD world"},
        {"a UTF-16 surrogate", "Hello " <> <<0xED, 0xA0, 0x80>> <> " world",
         "Hello \uFFFD\uFFFD\uFFFD world"},
        {"a truncated sequence", "Hello " <> <<0xE2, 0x82>> <> " world", "Hello \uFFFD world"},
        {"a truncated 4-byte sequence", "Hello " <> <<0xF0, 0x9F, 0x8E>> <> " world",
         "Hello \uFFFD world"},
        {"a truncated sequence at the end", "Hello world" <> <<0xE2, 0x82>>, "Hello world\uFFFD"},
        {"several invalid bytes", "caf" <> <<0xE9>> <> " na" <> <<0xEF>> <> "ve",
         "caf\uFFFD na\uFFFDve"},
        {"characters JSON must escape", "quote \" backslash \\ newline \n tab \t nul \0",
         "quote \" backslash \\ newline \n tab \t nul \0"},
        {"multi-byte and invisible characters", "caf\u00E9 \u2028 \u2029 \uFEFF 🎉",
         "caf\u00E9 \u2028 \u2029 \uFEFF 🎉"}
      ] do
    test "Logs messages containing #{kind} as JSON with the expected text" do
      # Arrange
      message = unquote(message)
      expected_message = unquote(expected_message)

      # Act
      io =
        capture_io(fn ->
          logger = new_logger()
          log(logger, message, :error)
          :gen_event.stop(logger)
        end)

      # Assert
      decoded = Jason.decode(io)

      assert match?({:ok, _}, decoded),
             "Expected a JSON log line but got #{printable(io)} for a message containing #{unquote(kind)}"

      {:ok, event} = decoded

      assert event["message"] == expected_message,
             "Expected message #{printable(expected_message)} but got #{printable(event["message"])} for a message containing #{unquote(kind)}"

      assert event["level"] == "error",
             "Expected level \"error\" but got #{printable(event["level"])} for a message containing #{unquote(kind)}"
    end
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

  test "Logs with correct environment" do
    io =
      capture_io(fn ->
        logger = new_logger(environment: :custom_env)
        log(logger, "Hello world!", :info)
        :gen_event.stop(logger)
      end)

    event = Jason.decode!(io)
    assert event["environment"] == "custom_env"
  end

  test "Logs with correct country" do
    io =
      capture_io(fn ->
        logger = new_logger()
        log(logger, "Hello world!", :info)
        :gen_event.stop(logger)
      end)

    event = Jason.decode!(io)
    assert event["country"] == nil

    io =
      capture_io(fn ->
        logger = new_logger(country: :custom_country)
        log(logger, "Hello world!", :info)
        :gen_event.stop(logger)
      end)

    event = Jason.decode!(io)
    assert event["country"] == "prima:country:custom_country"
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

  test "Can handle flush" do
    assert :ok = Logger.flush()
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
            otel_trace_id: ~c"3f654ec56f0380000000000000000015",
            otel_span_id: ~c"f000000000000005",
            otel_trace_flags: ~c"01"
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

    test "values can be binary()" do
      io =
        capture_io(fn ->
          logger = new_logger(opentelemetry_metadata: :detailed)

          log(logger, "hello world!", :info,
            # This is the log metadata automatically added by opentelemetry sdk >= 1.1.0
            otel_trace_id: "3f654ec56f0380000000000000000015",
            otel_span_id: "f000000000000005",
            otel_trace_flags: "01"
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

    test "PrimaExLogger.install won't remove default handler if config not specified" do
      _ = :logger.remove_handler(:prima_logger)
      on_exit(fn -> _ = :logger.remove_handler(:prima_logger) end)

      unless Enum.any?(:logger.get_handler_ids(), &(&1 == :default)) do
        :ok = :logger.add_handler(:default, :logger_std_h, %{config: %{type: :standard_io}})
      end

      assert Enum.any?(:logger.get_handler_ids(), &(&1 == :default))

      assert {:ok, _pid} = PrimaExLogger.install(:handler_together_with_default)

      # default is still there
      assert Enum.any?(:logger.get_handler_ids(), &(&1 == :default))
    end

    test "PrimaExLogger.install removes default handler if config specifies default_handler: false" do
      unless Enum.any?(:logger.get_handler_ids(), &(&1 == :default)) do
        :ok = :logger.add_handler(:default, :logger_std_h, %{config: %{type: :standard_io}})
      end

      assert Enum.any?(:logger.get_handler_ids(), &(&1 == :default))

      Application.put_env(:logger, :handler_without_default, default_handler: false)

      assert {:ok, _pid} = PrimaExLogger.install(:handler_without_default)

      # default is not there anymore
      refute Enum.any?(:logger.get_handler_ids(), &(&1 == :default))

      Application.delete_env(:logger, :handler_without_default)
    end
  end

  # Plain inspect/1 renders invalid UTF-8 as a byte list truncated after 50 bytes.
  defp printable(value), do: inspect(value, binaries: :as_strings, printable_limit: :infinity)

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
