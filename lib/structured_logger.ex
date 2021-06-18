defmodule StructuredLogger do
  @moduledoc """
  Provides an alternative logging frontend which performs an additional 'structured logging' step.

  The log_line passed to the logger can be either a string, or an interpolated string.
  The original log_line (as it appears in source code) is put under 'original_message' in the logger metadata.
  The log_line is then interpolated with the given values to produce the final 'message'.

  Why:
  - Allows you to see at a glance, when looking at the logs, what went wrong;
      as the message has values interpolated to give context.
  - Enables you to then easily search for the original log_line, when looking for a specific error in the logs, without needing
      to know which values got interpolated.
  """

  @doc """
  Performs an interpolated log at the given level.
  """
  defmacro log(level, log_line, values \\ []) do
    __MODULE__.logs(level, log_line, values)
  end

  @doc """
  Performs an interpolated log at the error level.
  """
  defmacro error(log_line, values \\ []) do
    __MODULE__.logs(:error, log_line, values)
  end

  @doc """
  Performs an interpolated log at the warning level.
  """
  defmacro warning(log_line, values \\ []) do
    __MODULE__.logs(:warning, log_line, values)
  end

  @doc """
  Performs an interpolated log at the info level.
  """
  defmacro info(log_line, values \\ []) do
    __MODULE__.logs(:info, log_line, values)
  end

  @doc """
  Performs an interpolated log at the debug level.
  """
  defmacro debug(log_line, values \\ []) do
    __MODULE__.logs(:debug, log_line, values)
  end

  def logs(level, log_line, values) do
    message = to_message(log_line, values)
    original = to_original(log_line)

    quote do
      require Logger

      Logger.unquote(Macro.var(level, nil))(
        unquote(message),
        Keyword.put_new(unquote(values), :original_message, unquote(original))
      )
    end
  end

  def to_original(log_line) do
    log_line
    |> Macro.to_string()
    |> String.trim("\"")
  end

  def to_message(log_line, values) do
    Macro.prewalk(
      log_line,
      fn
        {key, _, _} = ast when is_atom(key) ->
          Keyword.get(values, key, ast)

        ast ->
          ast
      end
    )
  end
end
