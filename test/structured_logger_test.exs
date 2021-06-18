defmodule StructuredLoggerTest do
  use ExUnit.Case

  require StructuredLogger, as: SL

  test "no interpolation or metadata" do
    log =
      quote do
        SL.info("hi")
      end

    expected =
      quote do
        require Logger

        Logger.info("hi", Keyword.put_new([], :original_message, "hi"))
      end

    assert_expands_to(log, expected)
  end

  test "no interpolation with metadata" do
    log =
      quote do
        SL.log(:critical, "error!", this: :thing, happened: %{"oh" => "no"})
      end

    expected =
      quote do
        require Logger

        Logger.critical(
          "error!",
          Keyword.put_new([this: :thing, happened: %{"oh" => "no"}], :original_message, "error!")
        )
      end

    assert_expands_to(log, expected)
  end

  test "interpolation without metadata" do
    log =
      quote do
        SL.warning("hello, #{name}")
      end

    expected =
      quote do
        require Logger

        Logger.warning(
          "hello, #{name}",
          Keyword.put_new([], :original_message, "hello, \#{name}")
        )
      end

    assert_expands_to(log, expected)
  end

  test "interpolation with metadata" do
    log =
      quote do
        SL.error("go through #{room.door}", room: kitchen)
      end

    expected =
      quote do
        require Logger

        Logger.error(
          "go through #{kitchen.door}",
          Keyword.put_new([room: kitchen], :original_message, "go through \#{room.door}")
        )
      end

    assert_expands_to(log, expected)
  end

  defp assert_expands_to(initial_ast, final_ast) do
    expanded = Macro.expand(initial_ast, __ENV__) |> Macro.to_string()
    expected = Macro.to_string(final_ast)

    assert expanded == expected
  end
end
